; Francesco Zoccheddu
; ARE
; EEPROM programming
; dirty timer 0 and registers

#define _ML_TIMER 2

TIM_DEF _ML, _ML_TIMER

#define _ml_tmp @0

; [SOURCE] setup
; @0 (dirty immediate register)
.macro ML_SRC_SETUP
	; clear timer control registers
	clr _ml_tmp
	sts _ML_TCCRA, _ml_tmp
	sts _ML_TCCRB, _ml_tmp
	; set timer interrupt mask
	ldi _ml_tmp, OCIEA_VAL
	sts _ML_TIMSK, _ml_tmp
	; setup pause
	ser _ml_tmp
	sts ml_ram_paused, _ml_tmp
	P_SRC_SETUP _ml_tmp
.endmacro

#undef _ml_tmp

.dseg
_ml_ram_tcs: .byte 1
ml_ram_paused: .byte 1
.cseg

.macro ML_SRC_SPLOAD
	#define ML_TIM 0.002

	ldi rma, LOW( int(ML_TIM * T8_PROPF+0.5) )
	ldi rmb, HIGH( int(ML_TIM * T8_PROPF+0.5) )

	call t_sr_calc
	sts _ML_OCRA, rmb
	sts _ml_ram_tcs, rmc
.endmacro


; [SOURCE] main loop
; @0 (dirty immediate register)
; @1 (dirty immediate register)
; @2 (dirty immediate register)
; @3 (dirty immediate register)
.macro ML_SRC_LOOP

#define _ml_col @0

_ml_l_src_loop_begin:
	ldi _ml_col, 16
	
#define _ml_cl @1
#define _ml_ch @2

_ml_l_src_loop_column:
	dec _ml_col

#define _ml_tmp @3

	lds _ml_tmp, ml_ram_paused
	tst _ml_tmp
	brne _ml_l_src_loop_paused
	G_SRC_DRAW _ml_col, _ml_cl, _ml_ch, _ml_tmp
	rjmp _ml_l_src_loop_flush
_ml_l_src_loop_paused:
	P_SRC_DRAW _ml_col, _ml_cl, _ml_ch, _ml_tmp

#undef _ml_tmp

_ml_l_src_loop_flush:
	cli
	LM_SRC_SEND_COL _ml_ch, _ml_cl, _ml_col, rmd, rme

#undef _ml_cl
#undef _ml_ch

#define _ml_tmp @1
#define _ml_lock @2

	clr _ml_tmp
	sts _ML_TCNT, _ml_tmp
	lds _ml_tmp, _ml_ram_tcs
	sts _ML_TCCRB, _ml_tmp
	ser _ml_lock
	sei

#undef _ml_tmp

_ml_l_src_loop_wait:
	tst _ml_lock
	brne _ml_l_src_loop_wait

	tst _ml_col
	brne _ml_l_src_loop_column
	rjmp _ml_l_src_loop_begin

#undef _ml_col

ISR _ML_OCAaddr
	clr _ml_lock
	sts _ML_TCCRB, _ml_lock
	reti

#undef _ml_lock

.endmacro

#include "pause.asm"
#include "game.asm"
