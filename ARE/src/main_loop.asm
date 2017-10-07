; Francesco Zoccheddu
; ARE
; EEPROM programming
; dirty timer 0 and registers


#define _ML_TIMER 2

TIM_DEF _ML, _ML_TIMER

#define _ml_setup_tmp @0

; [SOURCE] setup
; @0 (dirty immediate register)
.macro ML_SRC_SETUP
	; clear timer control registers
	clr _ml_setup_tmp
	sts _ML_TCCRA, _ml_setup_tmp
	sts _ML_TCCRB, _ml_setup_tmp
	; set timer interrupt mask
	ldi _ml_setup_tmp, OCIEA_VAL
	sts _ML_TIMSK, _ml_setup_tmp
	; setup pause
	clr _ml_setup_tmp
	sts _ml_ram_pprog, _ml_setup_tmp
	ser _ml_setup_tmp
	sts ml_ram_paused, _ml_setup_tmp
	P_SRC_SETUP _ml_setup_tmp
.endmacro

#undef _ml_setup_tmp

.dseg
_ml_ram_tcs: .byte 1
ml_ram_paused: .byte 1
_ml_ram_pprog: .byte 1
_ml_ram_pabsnc_add: .byte 1
_ml_ram_pprsnc_sub: .byte 1
.cseg

.macro ML_SRC_SPLOAD
	#define ML_TIM 0.002

	ldi rma, LOW( int(ML_TIM * T8_PROPF+0.5) )
	ldi rmb, HIGH( int(ML_TIM * T8_PROPF+0.5) )

	call t_sr_calc
	sts _ML_OCRA, rmb
	sts _ml_ram_tcs, rmc

	ldi rma, 2
	sts _ml_ram_pabsnc_add, rma
	ldi rma, 2
	sts _ml_ram_pprsnc_sub, rma
	P_SRC_SPLOAD rma
.endmacro

#define ml_col rmf
#define ml_cl rmd
#define ml_ch rme
#define ml_tmp1 rma
#define ml_tmp2 rmb
#define ml_tmp3 rmc

ml_l_loop:
_ml_l_loop_begin:
	ldi ml_col, 16

	lds ml_tmp1, ml_ram_paused
	tst ml_tmp1
	brne _ml_l_loop_update_paused
	
	lds ml_tmp1, ds_ram_out_state
	lds ml_tmp2, _ml_ram_pprog
	tst ml_tmp1
	brne _ml_l_update_sub
	lds ml_tmp1, _ml_ram_pabsnc_add
	add ml_tmp2, ml_tmp1
	brne _ml_l_update_done
	ser ml_tmp1
	sts ml_ram_paused, ml_tmp1
	rjmp g_l_pause
_ml_l_update_sub:
	lds ml_tmp1, _ml_ram_pprsnc_sub
	sub ml_tmp2, ml_tmp1
	brcc _ml_l_update_done
	clr ml_tmp2
g_l_pause_done:
_ml_l_update_done:
	sts _ml_ram_pprog, ml_tmp2
	
	rjmp _ml_l_loop_column
_ml_l_loop_update_paused:
	rjmp p_l_update

ml_l_update_done:
_ml_l_loop_column:
	dec ml_col

	lds ml_tmp1, ml_ram_paused
	tst ml_tmp1
	brne _ml_l_loop_draw_paused
	rjmp g_l_draw
	rjmp _ml_l_loop_flush
_ml_l_loop_draw_paused:
	rjmp p_l_draw

ml_l_draw_done:
_ml_l_loop_flush:
	cli
	rjmp lm_l_sendcol

ml_l_sendcol_done:

#define _ml_lock ml_ch

	clr ml_tmp1
	sts _ML_TCNT, ml_tmp1
	lds ml_tmp1, _ml_ram_tcs
	sts _ML_TCCRB, ml_tmp1
	ser _ml_lock
	sei

_ml_l_loop_wait:
	tst _ml_lock
	brne _ml_l_loop_wait

	tst ml_col
	brne _ml_l_loop_column
	rjmp _ml_l_loop_begin

ISR _ML_OCAaddr
	clr _ml_lock
	sts _ML_TCCRB, _ml_lock
	reti

#undef _ml_lock

#include "pause.asm"
#include "game.asm"

