
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
#define ML_SMOOTH_SLOW 0.85
#define ML_SMOOTH 0.6
	ldi rma, int(ML_SMOOTH * 255)
	sts _g_ram_smooth, rma
	ldi rma, int(ML_SMOOTH_SLOW * 255)
	sts _g_ram_smooth_slow, rma
.endmacro


#define _g_tmp1 ml_tmp1
#define _g_tmp2 ml_tmp2
#define _g_tmp3 ml_tmp3
#define _g_tmp4 ml_tmp4

; mull (a) (dirty)
; tmp4 (b)
; tmp3 (factor) (dirty)
; mulh (out)
_g_l_smooth:
	mul mull, _g_tmp3
	movw _g_tmp2:_g_tmp1, mulh:mull
	com _g_tmp3
	mov mull, _g_tmp4
	mul mull, _g_tmp3
	add mull, _g_tmp1
	adc mulh, _g_tmp2
	ret

g_l_update:
	; smooth
	lds _g_tmp1, ds_ram_out_state
	tst _g_tmp1
	breq _g_l_update_smooth_zombie
	lds _g_tmp4, ds_ram_out_val
	; svals = svals * smooths + rval * (1-smooths)
	lds mull, _g_ram_dsval_slow
	lds _g_tmp3, _g_ram_smooth_slow
	rcall _g_l_smooth
	sts _g_ram_dsval_slow, mulh
	; sval = sval * smooth + rval * (1-smooth)
	lds mull, _g_ram_dsval
	lds _g_tmp3, _g_ram_smooth
	rcall _g_l_smooth
	sts _g_ram_dsval, mulh
	rjmp _g_l_update_smooth_done
_g_l_update_smooth_zombie:
	; sval = sval * smooth + svals * (1-smooth)
	lds _g_tmp4, _g_ram_dsval_slow
	lds mull, _g_ram_dsval
	lds _g_tmp3, _g_ram_smooth
	rcall _g_l_smooth
	sts _g_ram_dsval, mulh
_g_l_update_smooth_done:
	com mulh
	lsr mulh
	lsr mulh
	lsr mulh
	lsr mulh
	sts _g_ram_col, mulh
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
	lds _g_tmp1, _g_ram_dsval_slow
	com _g_tmp1
	lsr _g_tmp1
	lsr _g_tmp1
	lsr _g_tmp1
	lsr _g_tmp1
	cp _g_col, _g_tmp1
	brne PC + 2
	ori _g_cl, 2
	lds _g_tmp1, _g_ram_col
	cp _g_col, _g_tmp1
	brne _g_l_draw_done
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
