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
	; load bitmaps
	SP_SRC_LOAD_TO_RAM ee_s_bm_scr, _s_ram_bm_scr, 2*16
	SP_SRC_LOAD_TO_RAM ee_s_bm_top, _s_ram_bm_top, 2*16
	SP_SRC_LOAD_TO_RAM ee_s_bm_digits, _s_ram_bm_digits, 12*4
	SP_SRC_LOAD ee_s_tim
	mov rma, sp_data
	SP_SRC_LOAD ee_s_tim + 1
	mov rmb, sp_data
	call t_sr_calc
	sts _S_OCRAH, rmb
	sts _S_OCRAL, rma
	ori rmc, WGMB_VAL(4)
	sts _s_ram_tccrb, rmc
.endmacro

#undef _s_setup_tmp

.eseg
ee_s_tim: .dw int( 1 * T16_PROPF + 0.5)
.cseg

.dseg
_s_ram_state: .byte 1
_s_ram_tccrb: .byte 1
_s_ram_bcd_top: .byte 4
_s_ram_bcd_scr: .byte 4
_s_ram_bm_top: .byte 2*16
_s_ram_bm_scr: .byte 2*16
_s_ram_bm_digits: .byte 12*4
.cseg

s_l_draw:
	lds ml_tmp1, _s_ram_state
	cpi ml_tmp1, _S_STATE_SCR
	breq _s_l_draw_scr
	ldi XL, LOW( _s_ram_bm_top )
	ldi XH, HIGH( _s_ram_bm_top )
	ldi YL, LOW( _s_ram_bcd_top )
	ldi YH, HIGH( _s_ram_bcd_top )
	rjmp _s_l_draw_text
_s_l_draw_scr:
	ldi XL, LOW( _s_ram_bm_scr )
	ldi XH, HIGH( _s_ram_bm_scr )
	ldi YL, LOW( _s_ram_bcd_scr )
	ldi YH, HIGH( _s_ram_bcd_scr )
_s_l_draw_text:
	clr ml_tmp1
	add XL, ml_col
	adc XH, ml_tmp1
	ld ml_ch, X
	; draw score
	mov ml_tmp2, ml_col
	lsr ml_tmp2
	lsr ml_tmp2
	ldi ml_tmp1, 3
	sub ml_tmp1, ml_tmp2
	add YL, ml_tmp1
	clr ml_tmp1
	adc YH, ml_tmp1
	ld ml_tmp1, Y
	lsl ml_tmp1
	lsl ml_tmp1
	mov ml_tmp2, ml_col
	andi ml_tmp2, 0b11
	add ml_tmp1, ml_tmp2
	ldi YL, LOW( _s_ram_bm_digits )
	ldi YH, HIGH( _s_ram_bm_digits )
	add YL, ml_tmp1
	clr ml_tmp1
	adc YH, ml_tmp1
	ld ml_cl, Y
	rjmp s_l_draw_done

s_l_set:
	; set timer
	lds rma, _s_ram_tccrb
	sts _S_TCCRB, rma
	; save score
	; load score
	ldi XL, LOW(_s_ram_bcd_top)
	ldi XH, HIGH(_s_ram_bcd_top)
	ldi ml_tmp1, LOW(987)
	ldi ml_tmp2, HIGH(987)
	rcall _s_sr_tobcd
	ldi XL, LOW(_s_ram_bcd_scr)
	ldi XH, HIGH(_s_ram_bcd_scr)
	ldi ml_tmp1, LOW(987)
	ldi ml_tmp2, HIGH(987)
	rcall _s_sr_tobcd
	rjmp s_l_set_done

_s_sr_tobcd:
	cpi ml_tmp1, LOW(1000)
	ldi ml_tmp3, HIGH(1000)
	cpc ml_tmp2, ml_tmp3
	brsh _s_l_sr_tobcd_overflow
	rjmp _s_l_sr_tobcd_overflow ; remove
	ret
_s_l_sr_tobcd_overflow:
	ldi ml_tmp3, 9
	st X+, ml_tmp3
	st X+, ml_tmp3
	st X+, ml_tmp3
	ldi ml_tmp3, 10
	st X, ml_tmp3
	ret
	

ISR _S_OCAaddr
	lds ria, _s_ram_state
	com ria
	sts _s_ram_state, ria
	reti
	