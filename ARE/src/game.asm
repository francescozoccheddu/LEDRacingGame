
.dseg
_g_ram_smooth: .byte 1
_g_ram_smooth_slow: .byte 1
_g_ram_dsval: .byte 1
_g_ram_dsval_slow: .byte 1
_g_ram_col: .byte 1
_g_ram_frame: .byte 16*3
_g_ram_tpropf_minl: .byte 1
_g_ram_tpropf_minh: .byte 1
_g_ram_tpropf_maxl: .byte 1
_g_ram_tpropf_maxh: .byte 1
_g_ram_tpropf_currl: .byte 1
_g_ram_tpropf_currh: .byte 1
_g_ram_spawn_countdown: .byte 1
_g_ram_spawn_period: .byte 1
_g_ram_difficulty_countdown: .byte 1
_g_ram_difficulty_period: .byte 1
.cseg

#define _G_TIMER 3

TIM_DEF _G, _G_TIMER

#define _g_setup_tmp1 @0
#define _g_setup_tmp2 @1

.macro G_SRC_SETUP
	; clear timer control registers
	clr _g_setup_tmp1
	sts _G_TCCRA, _g_setup_tmp1
	sts _G_TCCRB, _g_setup_tmp1
	sts _G_TCCRC, _g_setup_tmp1
	; set timer interrupt mask
	ldi _g_setup_tmp1, OCIEA_VAL
	sts _G_TIMSK, _g_setup_tmp1
	; clear frame
	ldi XL, LOW( _g_ram_frame )
	ldi XH, HIGH( _g_ram_frame )
	clr _g_setup_tmp2
	ldi _g_setup_tmp1, 16*3
_g_l_setup_clear_loop:
	st X+, _g_setup_tmp2
	dec _g_setup_tmp1
	brne _g_l_setup_clear_loop
	;set empty
	ldi _g_setup_tmp1, 1
	sts _g_ram_spawn_countdown, _g_setup_tmp1 
.endmacro

#undef _g_setup_tmp1
#undef _g_setup_tmp2

.macro G_SRC_SPLOAD
#define ML_SMOOTH 8
#define ML_SMOOTH_SLOW 3
#define G_MIN_MS 500
#define G_MAX_MS 100
	ldi rma, 2
	sts _g_ram_spawn_period, rma
	ldi rma, 4
	sts _g_ram_difficulty_period, rma
	ldi rma, ML_SMOOTH
	sts _g_ram_smooth, rma
	ldi rma, ML_SMOOTH_SLOW
	sts _g_ram_smooth_slow, rma
	ldi rma, HIGH( int(G_MAX_MS * T16_PROPF + 0.5))
	sts _g_ram_tpropf_maxh, rma
	ldi rma, LOW( int(G_MAX_MS * T16_PROPF + 0.5))
	sts _g_ram_tpropf_maxl, rma
	ldi rma, HIGH( int(G_MIN_MS * T16_PROPF + 0.5))
	sts _g_ram_tpropf_minh, rma
	sts _g_ram_tpropf_currh, rma
	ldi rma, LOW( int(G_MIN_MS * T16_PROPF + 0.5))
	sts _g_ram_tpropf_minl, rma
	sts _g_ram_tpropf_currl, rma
.endmacro


#define _g_tmp1 ml_tmp1
#define _g_tmp2 ml_tmp2
#define _g_tmp3 ml_tmp3
#define _g_tmp4 ml_tmp4

; tmp1 (a)
; tmp2 (b)
; tmp3 (prog)
_g_l_smooth:
	cp _g_tmp1, _g_tmp2
	brsh _g_l_smooth_greater
	mov _g_tmp4, _g_tmp2
	sub _g_tmp4, _g_tmp1
	cp _g_tmp4, _g_tmp3
	brlo _g_l_smooth_clamp
	add _g_tmp1, _g_tmp3
	ret
_g_l_smooth_greater:
	mov _g_tmp4, _g_tmp1
	sub _g_tmp4, _g_tmp2
	cp _g_tmp4, _g_tmp3
	brlo _g_l_smooth_clamp
	sub _g_tmp1, _g_tmp3
	ret
_g_l_smooth_clamp:
	mov _g_tmp1, _g_tmp2
	ret

g_l_update:
	; smooth
	lds _g_tmp1, ds_ram_out_state
	tst _g_tmp1
	breq _g_l_update_smooth_zombie
	lds _g_tmp2, ds_ram_out_val
	; svals = svals * smooths + rval * (1-smooths)
	lds _g_tmp1, _g_ram_dsval_slow
	lds _g_tmp3, _g_ram_smooth_slow
	rcall _g_l_smooth
	sts _g_ram_dsval_slow, _g_tmp1
	; sval = sval * smooth + rval * (1-smooth)
	lds _g_tmp1, _g_ram_dsval
	lds _g_tmp3, _g_ram_smooth
	rcall _g_l_smooth
	sts _g_ram_dsval, _g_tmp1
	rjmp _g_l_update_smooth_done
_g_l_update_smooth_zombie:
	; sval = sval * smooth + svals * (1-smooth)
	lds _g_tmp1, _g_ram_dsval
	lds _g_tmp2, _g_ram_dsval_slow
	lds _g_tmp3, _g_ram_smooth
	rcall _g_l_smooth
	sts _g_ram_dsval, _g_tmp1
_g_l_update_smooth_done:
	com _g_tmp1
	swap _g_tmp1
	andi _g_tmp1, 0b00001111
	sts _g_ram_col, _g_tmp1
	rjmp g_l_update_done

#define _g_col ml_col
#define _g_cl ml_cl
#define _g_ch ml_ch

g_l_draw:
	ldi XH, HIGH(_g_ram_frame + 1)
	ldi XL, LOW(_g_ram_frame + 1)
	ldi _g_tmp1, 3
	mul _g_tmp1, _g_col
	clr _g_tmp1
	add XL, mull
	adc XH, _g_tmp1
	ld _g_ch, X+
	ld _g_cl, X
	; add ship
/*	lds _g_tmp1, _g_ram_dsval_slow
	com _g_tmp1
	lsr _g_tmp1
	lsr _g_tmp1
	lsr _g_tmp1
	lsr _g_tmp1
	cp _g_col, _g_tmp1
	brne PC + 2
	ori _g_cl, 4
	;delete*/
	lds _g_tmp1, _g_ram_col
	cp _g_col, _g_tmp1
	brne _g_l_draw_done
	sbrc _g_ch, 7
	nop ; lose
	ori _g_cl, 1
_g_l_draw_done:
	rjmp g_l_draw_done

#undef _g_col
#undef _g_cl
#undef _g_ch

g_l_pause:
	clr _g_tmp1
	sts _G_TCCRB, _g_tmp1
	rjmp g_l_pause_done

g_l_resume:
	lds _g_tmp1, ds_ram_out_val
	sts _g_ram_dsval, _g_tmp1
	sts _g_ram_dsval_slow, _g_tmp1
	; start timer
	rcall _g_l_set_timer
	rjmp g_l_resume_done

_g_l_set_timer:
	lds rma, _g_ram_tpropf_currl
	lds rmb, _g_ram_tpropf_currh
	call t_sr_calc
	sts _G_OCRAH, rmb
	sts _G_OCRAL, rma
	sts _G_TCCRB, rmc
	ret

#undef _g_tmp1
#undef _g_tmp2
#undef _g_tmp3

#define _g_tmp1 ria
#define _g_tmp2 rib
#define _g_tmp3 ric

ISR _G_OCAaddr
	lds _g_tmp1, _g_ram_spawn_countdown
	dec _g_tmp1
	brne _g_l_oca_vframe_done
	ldi _g_tmp1, 1
	sts _g_ram_frame, _g_tmp1
	sts _g_ram_frame + 6, _g_tmp1
	lds _g_tmp1, _g_ram_spawn_period
_g_l_oca_vframe_done:
	sts _g_ram_spawn_countdown, _g_tmp1
	lds _g_tmp1, _g_ram_difficulty_countdown
	dec _g_tmp1
	brne _g_l_oca_difficulty_done
	; update difficulty
	lds _g_tmp1, _g_ram_difficulty_period
_g_l_oca_difficulty_done:
	sts _g_ram_difficulty_countdown, _g_tmp1
	ldi XL, LOW( _g_ram_frame )
	ldi XH, HIGH( _g_ram_frame )
	ldi _g_tmp1, 16
_g_l_oca_shift_loop:
	ld _g_tmp2, X
	lsr _g_tmp2
	st X+, _g_tmp2
	ld _g_tmp2, X
	ror _g_tmp2
	st X+, _g_tmp2
	ld _g_tmp2, X
	ror _g_tmp2
	st X+, _g_tmp2
	dec _g_tmp1
	brne _g_l_oca_shift_loop
	reti

#undef _g_tmp1
#undef _g_tmp2
#undef _g_tmp3

