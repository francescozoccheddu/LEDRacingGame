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
_ml_ram_dsval: .byte 1
_ml_ram_dsval_slow: .byte 1
.cseg

.macro ML_SRC_SPLOAD
	#define ML_TIM 0.002
	#define ML_SMOOTH_SLOW 0.85
	#define ML_SMOOTH 0.6

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


; [SOURCE] main loop
; @0 (dirty immediate register)
; @1 (dirty immediate register next to @0)
; @2 (dirty immediate register)
.macro ML_SRC_LOOP

#define _ml_tmp1 @0
#define _ml_tmp2 @1
#define _ml_tmp3 @2

_ml_l_src_loop_begin:

	; smooth ds
	lds _ml_tmp1, ds_ram_out_state
	tst _ml_tmp1
	breq _ml_l_src_loop_smooth_zombie

	; ds present
	lds _ml_tmp3, _ml_ram_smooth
	lds mull, _ml_ram_dsval
	mul mull, _ml_tmp3
	movw _ml_tmp2:_ml_tmp1, mulh:mull
	com _ml_tmp3
	lds mull, ds_ram_out_val
	mul mull, _ml_tmp3
	add mull, _ml_tmp1
	adc mulh, _ml_tmp2
	sts _ml_ram_dsval, mulh

	lds _ml_tmp3, _ml_ram_smooth_slow
	lds mull, _ml_ram_dsval_slow
	mul mull, _ml_tmp3
	movw _ml_tmp2:_ml_tmp1, mulh:mull
	com _ml_tmp3
	lds mull, ds_ram_out_val
	mul mull, _ml_tmp3
	add mull, _ml_tmp1
	adc mulh, _ml_tmp2
	sts _ml_ram_dsval_slow, mulh

	rjmp _ml_l_src_smooth_done

_ml_l_src_loop_smooth_zombie:

	lds _ml_tmp3, _ml_ram_smooth
	lds mull, _ml_ram_dsval
	mul mull, _ml_tmp3
	movw _ml_tmp2:_ml_tmp1, mulh:mull
	com _ml_tmp3
	lds mull, _ml_ram_dsval_slow
	mul mull, _ml_tmp3
	add mull, _ml_tmp1
	adc mulh, _ml_tmp2
	sts _ml_ram_dsval, mulh

	; ds gone

#undef _ml_tmp1
#undef _ml_tmp2
#undef _ml_tmp3

#define _ml_col @0

_ml_l_src_smooth_done:
	ldi _ml_col, 16
	
#define _ml_cl @1
#define _ml_ch @2

_ml_l_src_loop_column:
	dec _ml_col

	;debug
	lds _ml_cl, _ml_ram_dsval
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
	ser _ml_cl
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




.macro DS_SRC_STATE_UPDATE
	BL_SRC_OUT ds_state_updated
.endmacro
