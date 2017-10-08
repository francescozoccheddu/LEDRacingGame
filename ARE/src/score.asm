#define _S_TIMER 5

TIM_DEF _S, _S_TIMER

#define _s_setup_tmp @0
#define _S_STATE_SCR 0

.macro S_SRC_SETUP
	; clear timer control registers
	clr _s_setup_tmp
	sts _S_TCCRA, _s_setup_tmp
	sts _S_TCCRB, _s_setup_tmp
	sts _S_TCCRC, _s_setup_tmp
	; set timer interrupt mask
	ldi _s_setup_tmp, OCIEA_VAL
	sts _S_TIMSK, _s_setup_tmp
	; set state
	ldi _s_setup_tmp, _S_STATE_SCR
	sts _s_ram_state, _s_setup_tmp
.endmacro


#undef _s_setup_tmp

.dseg
_s_ram_state: .byte 1
_s_ram_bcd_top: .byte 4
_s_ram_bcd_scr: .byte 4
.cseg

s_l_draw:
	clr ml_cl
	lds ml_tmp1, _s_ram_state
	cpi ml_tmp1, _S_STATE_SCR
	breq _s_l_draw_scr
	ldi ZL, LOW( bm_top * 2)
	ldi ZH, HIGH( bm_top * 2)
	rjmp _s_l_draw_text
_s_l_draw_scr:
	ldi ZL, LOW( bm_scr * 2)
	ldi ZH, HIGH( bm_scr * 2)
_s_l_draw_text:
	clr ml_tmp1
	add ZL, ml_col
	adc ZH, ml_tmp1
	lpm ml_ch, Z
	rjmp s_l_draw_done

s_l_set:
	#define S_TIM 1
	ldi rma, LOW( int(S_TIM * T16_PROPF + 0.5))
	ldi rmb, HIGH( int(S_TIM * T16_PROPF + 0.5))
	call t_sr_calc
	sts _S_OCRAH, rmb
	sts _S_OCRAL, rma
	ori rmc, WGMB_VAL(4)
	sts _S_TCCRB, rmc
	rjmp s_l_set_done

ISR _S_OCAaddr
	lds ria, _s_ram_state
	com ria
	sts _s_ram_state, ria
	reti
	