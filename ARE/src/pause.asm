
.dseg
_p_ram_prog: .byte 1
_p_ram_prsnc_add: .byte 1
_p_ram_absnc_sub: .byte 1
.cseg

#define _p_setup_tmp @0

.macro P_SRC_SETUP
	clr _p_setup_tmp
	sts _p_ram_prog, _p_setup_tmp
.endmacro

#undef _p_setup_tmp

.macro P_SRC_SPLOAD
	ldi @0, 2
	sts _p_ram_absnc_sub, @0
	ldi @0, 2
	sts _p_ram_prsnc_add, @0
.endmacro

#define _P_PROGRESS_COL 0b00000011

#define _p_col ml_col
#define _p_cl ml_cl
#define _p_ch ml_ch
#define _p_tmp ml_tmp1

p_l_draw:
	lds _p_tmp, _p_ram_prog
	cpi _p_tmp, 1 << 4
	brlo _p_l_src_draw_pause
	ldi ZH, HIGH(bm_resuming * 2)
	ldi ZL, LOW(bm_resuming * 2)
	rjmp _p_l_src_draw_begin
_p_l_src_draw_pause:
	ldi ZH, HIGH(bm_pause * 2)
	ldi ZL, LOW(bm_pause * 2)
_p_l_src_draw_begin:
	mov _p_tmp, _p_col
	lsl _p_tmp
	add ZL, _p_tmp
	clr _p_tmp
	adc ZH, _p_tmp
	lpm _p_cl, Z+
	lpm _p_ch, Z
	lds _p_tmp, _p_ram_prog
	com _p_tmp
	lsr _p_tmp
	lsr _p_tmp
	lsr _p_tmp
	lsr _p_tmp
	cp _p_tmp, _p_col
	brsh _p_l_src_draw_done
	ori _p_cl, _P_PROGRESS_COL
_p_l_src_draw_done:
	rjmp ml_l_draw_done

#undef _p_col
#undef _p_cl
#undef _p_ch
#undef _p_tmp

#define _p_tmp1 ml_tmp1
#define _p_tmp2 ml_tmp2

p_l_update:
	lds _p_tmp1, ds_ram_out_state
	lds _p_tmp2, _p_ram_prog
	tst _p_tmp1
	breq _p_l_src_update_sub
	lds _p_tmp1, _p_ram_prsnc_add
	add _p_tmp2, _p_tmp1
	brne _p_l_src_update_done
	sts ml_ram_paused, _p_tmp2
	rjmp g_l_resume
_p_l_src_update_sub:
	lds _p_tmp1, _p_ram_absnc_sub
	sub _p_tmp2, _p_tmp1
	brcc _p_l_src_update_done
	clr _p_tmp2
g_l_resume_done:
_p_l_src_update_done:
	sts _p_ram_prog, _p_tmp2
	rjmp ml_l_update_done

#undef _p_tmp1
#undef _p_tmp2
