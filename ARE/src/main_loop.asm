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
.endmacro

#undef _ml_tmp

.dseg
_ml_ram_tcs: .byte 1
_ml_ram_ttop: .byte 1
_ml_ram_smooth: .byte 1
_ml_ram_smooth_slow: .byte 1
_ml_ram_dstime: .byte 1
_ml_ram_dstime_slow: .byte 1
.cseg

.macro ML_SRC_SPLOAD
	#define ML_TIM 0.002
	#define ML_SMOOTH_SLOW 0.9
	#define ML_SMOOTH 0.5 

	ldi rma, LOW( int(ML_TIM * T8_PROPF+0.5) )
	ldi rmb, HIGH( int(ML_TIM * T8_PROPF+0.5) )

	call t_sr_calc
	sts _ml_ram_ttop, rmb
	sts _ml_ram_tcs, rmc

	ldi rma, int(ML_SMOOTH * 255)
	sts _ml_ram_smooth, rma
	ldi rma, int(ML_SMOOTH_SLOW * 255)
	sts _ml_ram_smooth_slow, rma
.endmacro

#define _ml_col @0
#define _ml_cl @1
#define _ml_ch @2

; [SOURCE] main loop
; @0 (dirty immediate register)
; @1 (dirty immediate register)
; @2 (dirty immediate register)
.macro ML_SRC_LOOP
_ml_l_src_loop_begin:
	ldi _ml_col, 16
_ml_l_src_loop_column:
	dec _ml_col

	;debug
	lds _ml_cl, ds_ram_out_val
	lsr _ml_cl
	lsr _ml_cl
	lsr _ml_cl
	lsr _ml_cl
	cp _ml_cl, _ml_col
	breq ciao
	clr _ml_cl
	clr _ml_ch
	rjmp go
ciao:
	lds _ml_cl, ds_ram_out_state
	ser _ml_ch
go:
	;debug end
	
	cli
	LM_SRC_SEND_COL _ml_ch, _ml_cl, _ml_col, rmd, rme

#undef _ml_cl
#undef _ml_ch
#define _ml_tmp @1
#define _ml_lock @2

	clr _ml_tmp
	sts _ML_TCNT, _ml_tmp
	lds _ml_tmp, _ml_ram_ttop
	sts _ML_OCRA, _ml_tmp
	lds _ml_tmp, _ml_ram_tcs
	sts _ML_TCCRB, _ml_tmp
	ser _ml_lock
	sei

_ml_l_src_loop_wait:
	tst _ml_lock
	brne _ml_l_src_loop_wait

	tst _ml_col
	brne _ml_l_src_loop_column
	rjmp _ml_l_src_loop_begin

ISR _ML_OCAaddr
	clr _ml_lock
	sts _ML_TCCRB, _ml_lock
	reti
.endmacro

#undef _ml_col
#undef _ml_tmp
#undef _ml_lock



.macro DS_SRC_STATE_UPDATE
	BL_SRC_OUT ds_state_updated
.endmacro
