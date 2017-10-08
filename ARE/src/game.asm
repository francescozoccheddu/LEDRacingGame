
.dseg
_g_ram_smooth: .byte 1
_g_ram_smooth_slow: .byte 1
_g_ram_dsval: .byte 1
_g_ram_dsval_slow: .byte 1
_g_ram_col: .byte 1
_g_ram_frame: .byte 16*3
_g_ram_tccrb: .byte 1
_g_ram_spawn_countdown: .byte 1
_g_ram_spawn_period: .byte 1
_g_ram_scorel: .byte 1
_g_ram_scoreh: .byte 1
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
	clr _g_setup_tmp1
	sts _g_ram_scorel, _g_setup_tmp1
	sts _g_ram_scoreh, _g_setup_tmp1
.endmacro

#undef _g_setup_tmp1
#undef _g_setup_tmp2

.macro G_SRC_SPLOAD
#define ML_SMOOTH 8
#define ML_SMOOTH_SLOW 3
#define G_S 0.200
	ldi rma, 3
	sts _g_ram_spawn_period, rma
	ldi rma, ML_SMOOTH
	sts _g_ram_smooth, rma
	ldi rma, ML_SMOOTH_SLOW
	sts _g_ram_smooth_slow, rma

	ldi rma, LOW( int(G_S * T16_PROPF + 0.5))
	ldi rmb, HIGH( int(G_S * T16_PROPF + 0.5))
	rcall t_sr_calc
	sts _G_OCRAH, rmb
	sts _G_OCRAL, rma
	ori rmc, WGMB_VAL(4)
	sts _g_ram_tccrb, rmc
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
	; draw frame
	ldi XH, HIGH(_g_ram_frame + 1)
	ldi XL, LOW(_g_ram_frame + 1)
	ldi _g_tmp1, 3
	mul _g_tmp1, _g_col
	clr _g_tmp1
	add XL, mull
	adc XH, _g_tmp1
	ld _g_ch, X+
	ld _g_cl, X
	; draw ship
	lds _g_tmp1, _g_ram_col
	sub _g_tmp1, _g_col
	brpl _g_l_draw_abs_done
	neg _g_tmp1
_g_l_draw_abs_done:
	ldi ZH, HIGH( bm_player * 2)
	ldi ZL, LOW( bm_player * 2)
	add ZL, _g_tmp1
	clr _g_tmp1
	adc ZH, _g_tmp1
	lpm _g_tmp1, Z
	mov _g_tmp2, _g_cl
	and _g_tmp2, _g_tmp1
	brne _g_l_over
	or _g_cl, _g_tmp1
	rjmp g_l_draw_done

_g_l_over:
	ldi _g_tmp1, ML_SCREEN_SCORE
	sts ml_ram_screen, _g_tmp1
	clr _g_tmp1
	sts _G_TCCRB, _g_tmp1
	rjmp s_l_set

#undef _g_col
#undef _g_cl
#undef _g_ch

g_l_pause:
	clr _g_tmp1
	sts _G_TCCRB, _g_tmp1
	rjmp g_l_pause_done

g_l_resume:
	/*lds _g_tmp1, ds_ram_out_val
	sts _g_ram_dsval, _g_tmp1
	sts _g_ram_dsval_slow, _g_tmp1*/
	; start timer
	lds _g_tmp1, _g_ram_tccrb
	sts _G_TCCRB, _g_tmp1
	rjmp g_l_resume_done

#undef _g_tmp1
#undef _g_tmp2
#undef _g_tmp3

#define _g_tmp1 ria
#define _g_tmp2 rib
#define _g_tmp3 ric

ISR _G_OCAaddr
	; score
	lds XL, _g_ram_scorel
	lds XH, _g_ram_scoreh
	adiw XH:XL, 1
	sts _g_ram_scorel, XL
	sts _g_ram_scoreh, XH
	; spawn
	lds _g_tmp1, _g_ram_spawn_countdown
	dec _g_tmp1
	brne _g_l_oca_vframe_done
	; spawn begin
	ldi _g_tmp1, 3
	sts _g_ram_frame, _g_tmp1
	sts _g_ram_frame + 6, _g_tmp1
	; spawn end
	lds _g_tmp1, _g_ram_spawn_period
_g_l_oca_vframe_done:
	sts _g_ram_spawn_countdown, _g_tmp1
	; shift
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

