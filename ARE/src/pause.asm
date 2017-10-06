/*
 * pause.asm
 *
 *  Created: 06-Oct-17 21:37:50
 *   Author: zocch
 */ 

#define _P_TIMER 5
#define _P_STATE_PAUSABLE_BIT 6
#define _P_STATE_RESUMABLE_BIT 7

TIM_DEF _P, _P_TIMER

.dseg
_p_ram_hold_tcs: .byte 1
_p_ram_hold_ttopl: .byte 1
_p_ram_hold_ttoph: .byte 1

_p_ram_rtick_tcs: .byte 1
_p_ram_rtick_ttopl: .byte 1
_p_ram_rtick_ttoph: .byte 1

_p_ram_state: .byte 1
.cseg

#define _p_tmp @0

.macro P_SRC_SETUP
	; clear timer control registers
	clr _p_tmp
	sts _P_TCCRA, _p_tmp
	sts _P_TCCRB, _p_tmp
	sts _P_TCCRC, _p_tmp
	; set timer interrupt mask
	ldi _p_tmp, OCIEA_VAL
	sts _P_TIMSK, _p_tmp
	; set state
	ldi _p_tmp, 1 << _P_STATE_RESUMABLE_BIT
	sts _p_ram_state, _p_tmp
.endmacro

#undef _p_tmp

.macro P_SRC_SPLOAD
	#define P_HOLD_TIM 0.002
	#define P_RTICK_TIM 0.002

	ldi rma, LOW( int(P_HOLD_TIM * T16_PROPF+0.5) )
	ldi rmb, HIGH( int(P_HOLD_TIM * T16_PROPF+0.5) )

	call t_sr_calc
	sts _p_ram_hold_ttopl, rma
	sts _p_ram_hold_ttoph, rmb
	sts _p_ram_hold_tcs, rmc

	ldi rma, LOW( int(P_RTICK_TIM * T16_PROPF+0.5) )
	ldi rmb, HIGH( int(P_RTICK_TIM * T16_PROPF+0.5) )

	call t_sr_calc
	sts _p_ram_rtick_ttopl, rma
	sts _p_ram_rtick_ttoph, rmb
	sts _p_ram_rtick_tcs, rmc
.endmacro

#define _p_col @0
#define _p_cl @1
#define _p_ch @2
#define _p_tmp @3

.macro P_SRC_DRAW
	mov _p_tmp, _p_col
	andi _p_tmp, 0b00100100
	breq _p_l_src_draw_clear
	ldi _p_cl, 0b00001111
	ldi _p_ch, 0b11110000
	rjmp _p_l_src_draw_exit
_p_l_src_draw_clear:
	clr _p_cl
	clr _p_ch
_p_l_src_draw_exit:
.endmacro

#undef _p_col
#undef _p_cl
#undef _p_ch
#undef _p_tmp

.macro DS_SRC_STATE_UPDATE
	BL_SRC_OUT ds_state_updated
.endmacro
