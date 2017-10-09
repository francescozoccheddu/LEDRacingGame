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
ee_s_top: .dw 14
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
	mov ml_tmp1, ml_col
	lsr ml_tmp1
	lsr ml_tmp1
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

#define te1 ml_cl
#define te2 ml_ch

s_l_set:
	; set timer
	lds ml_tmp1, _s_ram_tccrb
	sts _S_TCCRB, ml_tmp1
	; save score
	SP_SRC_LOAD ee_s_top
	mov ml_tmp1, sp_data
	SP_SRC_LOAD ee_s_top + 1
	mov ml_tmp2, sp_data
	lds te1, g_ram_score
	lds te2, g_ram_score + 1
	cp ml_tmp1, te1
	cpc ml_tmp2, te2
	brsh _s_l_set_stored
	mov sp_data, te1
	SP_SRC_STORE ee_s_top
	mov sp_data, te2
	SP_SRC_STORE ee_s_top + 1
	movw ml_tmp2:ml_tmp1, te2:te1
_s_l_set_stored:
	; load score
	ldi YL, LOW(_s_ram_bcd_top)
	ldi YH, HIGH(_s_ram_bcd_top)
	rcall _s_sr_tobcd
	ldi YL, LOW(_s_ram_bcd_scr)
	ldi YH, HIGH(_s_ram_bcd_scr)
	lds ml_tmp1, g_ram_score
	lds ml_tmp2, g_ram_score + 1
	rcall _s_sr_tobcd
	rjmp s_l_set_done

#define bcd_l ml_tmp1
#define bcd_h ml_tmp2
#define bcd_z ml_tmp3
#define bcd_c ml_ch

_s_sr_tobcd:
	ldi bcd_z, HIGH(1000)
	cpi bcd_l, LOW(1000)
	cpc bcd_h, bcd_z
	brsh _s_l_sr_tobcd_overflow
	ldi bcd_z, 11
	std Y+1, bcd_z
	std Y+2, bcd_z
	std Y+3, bcd_z
_s_l_sr_tobcd_th_begin:
	ldi bcd_c, 0
	clr bcd_z
_s_l_sr_tobcd_th_loop:
	cpi bcd_l, 100
	cpc bcd_h, bcd_z
	brlo _s_l_sr_tobcd_th_done
	inc bcd_c
	subi bcd_l, 100
	sbc bcd_h, bcd_z
	rjmp _s_l_sr_tobcd_th_loop
_s_l_sr_tobcd_th_done:
	tst bcd_c
	breq _s_l_sr_tobcd_nd_loop
	st Y+, bcd_c
	ldi bcd_c, 1 << 7
_s_l_sr_tobcd_nd_loop:
	cpi bcd_l, 10
	brlo _s_l_sr_tobcd_nd_done
	inc bcd_c
	subi bcd_l, 10
	rjmp _s_l_sr_tobcd_nd_loop
_s_l_sr_tobcd_nd_done:
	tst bcd_c
	breq _s_l_sr_tobcd_rd
	andi bcd_c, ~(1 << 7)
	st Y+, bcd_c
_s_l_sr_tobcd_rd:
	st Y+, bcd_l
	ret
_s_l_sr_tobcd_overflow:
	ldi bcd_z, 9
	st Y+, bcd_z
	st Y+, bcd_z
	st Y+, bcd_z
	ldi bcd_z, 10
	st Y, bcd_z
	ret

ISR _S_OCAaddr
	lds ria, _s_ram_state
	com ria
	sts _s_ram_state, ria
	reti
	