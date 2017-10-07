
.dseg
_g_ram_smooth: .byte 1
_g_ram_smooth_slow: .byte 1
_g_ram_dsval: .byte 1
_g_ram_dsval_slow: .byte 1
.cseg

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

_g_l_smooth:
_g_l_src_loop_begin:
	lds _g_tmp1, ds_ram_out_state
	tst _g_tmp1
	breq _g_l_src_loop_smooth_zombie
	lds _g_tmp3, _g_ram_smooth
	lds mull, _g_ram_dsval
	mul mull, _g_tmp3
	movw _g_tmp2:_g_tmp1, mulh:mull
	com _g_tmp3
	lds mull, ds_ram_out_val
	mul mull, _g_tmp3
	add mull, _g_tmp1
	adc mulh, _g_tmp2
	sts _g_ram_dsval, mulh
	lds _g_tmp3, _g_ram_smooth_slow
	lds mull, _g_ram_dsval_slow
	mul mull, _g_tmp3
	movw _g_tmp2:_g_tmp1, mulh:mull
	com _g_tmp3
	lds mull, ds_ram_out_val
	mul mull, _g_tmp3
	add mull, _g_tmp1
	adc mulh, _g_tmp2
	sts _g_ram_dsval_slow, mulh
	rjmp _g_l_src_smooth_done
_g_l_src_loop_smooth_zombie:
	lds _g_tmp3, _g_ram_smooth
	lds mull, _g_ram_dsval
	mul mull, _g_tmp3
	movw _g_tmp2:_g_tmp1, mulh:mull
	com _g_tmp3
	lds mull, _g_ram_dsval_slow
	mul mull, _g_tmp3
	add mull, _g_tmp1
	adc mulh, _g_tmp2
	sts _g_ram_dsval, mulh
_g_l_src_smooth_done:
	rjmp PC

#undef _g_tmp1
#undef _g_tmp2
#undef _g_tmp3

#define _g_col ml_col
#define _g_cl ml_cl
#define _g_ch ml_ch
#define _g_tmp ml_tmp1

g_l_draw:
	ldi _g_cl, 1<<2
	clr _g_ch
	rjmp ml_l_draw_done

#undef _g_col
#undef _g_cl
#undef _g_ch
#undef _g_tmp
