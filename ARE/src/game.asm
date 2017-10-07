
.dseg
_g_ram_smooth: .byte 1
_g_ram_smooth_slow: .byte 1
_g_ram_dsval: .byte 1
_g_ram_dsval_slow: .byte 1
_g_ram_col: .byte 1
_g_ram_frame: .byte 16*2
.cseg

.macro G_SRC_SETUP
.endmacro

.macro G_SRC_SPLOAD
#define ML_SMOOTH 8
#define ML_SMOOTH_SLOW 3
	ldi rma, ML_SMOOTH
	sts _g_ram_smooth, rma
	ldi rma, ML_SMOOTH_SLOW
	sts _g_ram_smooth_slow, rma
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
	ldi ZH, HIGH(_g_ram_frame)
	ldi ZL, LOW(_g_ram_frame)
	clr _g_tmp1
	add ZL, _g_col
	adc ZH, _g_tmp1
	ld _g_cl, Z+
	ld _g_ch, Z
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
	rjmp g_l_pause_done

g_l_resume:
	lds _g_tmp1, ds_ram_out_val
	sts _g_ram_dsval, _g_tmp1
	sts _g_ram_dsval_slow, _g_tmp1
	rjmp g_l_resume_done

#undef _g_tmp1
#undef _g_tmp2
#undef _g_tmp3
