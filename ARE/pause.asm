#ifndef _INC_P
#define _INC_P

; Francesco Zoccheddu
; ARE
; pause

#include "utils.asm"
#include "distance_sens.asm"
#include "main_loop.asm"
#include "game.asm"
#include "serial_prog.asm"

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

#define _p_r_setup_tmp @0

.macro P_SRC_SETUP
	clr _p_r_setup_tmp
	sts _p_ram_prog, _p_r_setup_tmp
	; load
	SP_SRC_LOAD_TO_RAM ee_p_dsoff_sub, _p_ram_absnc_sub, 1
	SP_SRC_LOAD_TO_RAM ee_p_dson_add, _p_ram_prsnc_add, 1
	SP_SRC_LOAD_TO_RAM ee_p_bm_paused, _p_ram_bm_paused, 2*16
	SP_SRC_LOAD_TO_RAM ee_p_bm_resuming, _p_ram_bm_resuming, 2*16
.endmacro

#undef _p_r_setup_tmp

#define _p_r_draw_col @0
#define _p_r_draw_cl @1
#define _p_r_draw_ch @2
#define _p_r_draw_tmp @3

.macro P_SRC_DRAW
	lds _p_r_draw_tmp, _p_ram_prog
	swap _p_r_draw_tmp
	andi _p_r_draw_tmp, 0b1111
	cp _p_r_draw_col, _p_r_draw_tmp
	brsh _p_l_src_draw_pause
	ldi XH, HIGH(_p_ram_bm_resuming)
	ldi XL, LOW(_p_ram_bm_resuming)
	rjmp _p_l_src_draw_begin
_p_l_src_draw_pause:
	ldi XH, HIGH(_p_ram_bm_paused)
	ldi XL, LOW(_p_ram_bm_paused)
_p_l_src_draw_begin:
	mov _p_r_draw_tmp, _p_r_draw_col
	lsl _p_r_draw_tmp
	add XL, _p_r_draw_tmp
	clr _p_r_draw_tmp
	adc XH, _p_r_draw_tmp
	ld _p_r_draw_ch, X+
	ld _p_r_draw_cl, X
_p_l_src_draw_done:
.endmacro

#undef _p_r_draw_col
#undef _p_r_draw_cl
#undef _p_r_draw_ch
#undef _p_r_draw_tmp

#define _p_r_update_tmp1 @0
#define _p_r_update_tmp2 @1

.macro P_SRC_UPDATE
	lds _p_r_update_tmp1, ds_ram_out_state
	lds _p_r_update_tmp2, _p_ram_prog
	tst _p_r_update_tmp1
	breq _p_l_src_update_sub
	lds _p_r_update_tmp1, _p_ram_prsnc_add
	add _p_r_update_tmp2, _p_r_update_tmp1
	brcc _p_l_src_update_done
	ldi _p_r_update_tmp1, ML_SCREEN_GAME
	sts ml_ram_screen, _p_r_update_tmp1
	G_SRC_RESUME _p_r_update_tmp1
	rjmp _p_l_src_update_done
_p_l_src_update_sub:
	lds _p_r_update_tmp1, _p_ram_absnc_sub
	sub _p_r_update_tmp2, _p_r_update_tmp1
	brcc _p_l_src_update_done
	clr _p_r_update_tmp2
_p_l_src_update_done:
	sts _p_ram_prog, _p_r_update_tmp2
.endmacro

#undef _p_r_update_tmp1
#undef _p_r_update_tmp2

#endif
