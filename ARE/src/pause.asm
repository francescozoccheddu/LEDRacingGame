

.dseg
_p_ram_progress: .byte 1
_p_ram_presence_add: .byte 1
_p_ram_absence_sub: .byte 1
.cseg

#define _p_tmp @0

.macro P_SRC_SETUP
	clr _p_tmp
	sts _p_ram_progress, _p_tmp
.endmacro

#undef _p_tmp

.macro P_SRC_SPLOAD
	ldi @0, 2
	sts _p_ram_absence_sub, @0
	ldi @0, 2
	sts _p_ram_presence_add, @0
.endmacro

#define _P_PROGRESS_COL 0b00000011

#define _p_col @0
#define _p_cl @1
#define _p_ch @2
#define _p_tmp @3

.macro P_SRC_DRAW
	lds _p_tmp, _p_ram_progress
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
	lpm _p_ch, Z+
	lpm _p_cl, Z
	lds _p_tmp, _p_ram_progress
	com _p_tmp
	lsr _p_tmp
	lsr _p_tmp
	lsr _p_tmp
	lsr _p_tmp
	cp _p_tmp, _p_col
	brsh _p_l_src_draw_done
	ori _p_ch, _P_PROGRESS_COL
_p_l_src_draw_done:
.endmacro

#undef _p_col
#undef _p_cl
#undef _p_ch
#undef _p_tmp

#define _p_tmp @0
#define _p_prog @1

.macro P_SRC_UPDATE
	lds _p_tmp, ds_ram_out_state
	lds _p_prog, _p_ram_progress
	tst _p_tmp
	breq _p_l_src_update_sub
	lds _p_tmp, _p_ram_presence_add
	add _p_prog, _p_tmp
	brne _p_l_src_update_done
	clr _p_tmp
	sts ml_ram_paused, _p_tmp
	rjmp _p_l_src_update_done
_p_l_src_update_sub:
	lds _p_tmp, _p_ram_absence_sub
	sub _p_prog, _p_tmp
	brcc _p_l_src_update_done
	clr _p_prog
_p_l_src_update_done:
	sts _p_ram_progress, _p_prog
.endmacro

#undef _p_tmp
#undef _p_prog
