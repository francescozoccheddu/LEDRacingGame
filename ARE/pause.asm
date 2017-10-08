
.dseg
_p_ram_prog: .byte 1
_p_ram_prsnc_add: .byte 1
_p_ram_absnc_sub: .byte 1

_p_ram_bm_paused: .byte 2*16
_p_ram_bm_resuming: .byte 2*16
.cseg

.eseg
ee_p_dsoff_sub: .db 8
ee_p_dson_add: .db 4
.cseg

#define _p_setup_tmp @0

.macro P_SRC_SETUP
	clr _p_setup_tmp
	sts _p_ram_prog, _p_setup_tmp
	; load
	SP_SRC_LOAD_TO_RAM ee_p_dsoff_sub, _p_ram_absnc_sub, 1
	SP_SRC_LOAD_TO_RAM ee_p_dson_add, _p_ram_prsnc_add, 1
	SP_SRC_LOAD_TO_RAM ee_p_bm_paused, _p_ram_bm_paused, 2*16
	SP_SRC_LOAD_TO_RAM ee_p_bm_resuming, _p_ram_bm_resuming, 2*16
.endmacro

#undef _p_setup_tmp

#define _P_PROGRESS_COL 0b00000011

#define _p_col ml_col
#define _p_cl ml_cl
#define _p_ch ml_ch
#define _p_tmp ml_tmp1

p_l_draw:
	lds _p_tmp, _p_ram_prog
	swap _p_tmp
	andi _p_tmp, 0b1111
	cp _p_col, _p_tmp
	brsh _p_l_src_draw_pause
	ldi XH, HIGH(_p_ram_bm_resuming)
	ldi XL, LOW(_p_ram_bm_resuming)
	rjmp _p_l_src_draw_begin
_p_l_src_draw_pause:
	ldi XH, HIGH(_p_ram_bm_paused)
	ldi XL, LOW(_p_ram_bm_paused)
_p_l_src_draw_begin:
	mov _p_tmp, _p_col
	lsl _p_tmp
	add XL, _p_tmp
	clr _p_tmp
	adc XH, _p_tmp
	ld _p_ch, X+
	ld _p_cl, X
_p_l_src_draw_done:
	rjmp p_l_draw_done

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
	brcc _p_l_src_update_done
	sts ml_ram_screen, _p_tmp2
	rjmp g_l_resume
_p_l_src_update_sub:
	lds _p_tmp1, _p_ram_absnc_sub
	sub _p_tmp2, _p_tmp1
	brcc _p_l_src_update_done
	clr _p_tmp2
g_l_resume_done:
_p_l_src_update_done:
	sts _p_ram_prog, _p_tmp2
	rjmp p_l_update_done

#undef _p_tmp1
#undef _p_tmp2
