; Francesco Zoccheddu
; ARE
; EEPROM programming
; dirty timer 0 and registers


#define _ML_TIMER 2

TIM_DEF _ML, _ML_TIMER

#define ML_SCREEN_PAUSE 2
#define ML_SCREEN_SCORE 1
#define ML_SCREEN_GAME 0

#define _ml_setup_tmp @0

; [SOURCE] setup
; @0 (dirty immediate register)
.macro ML_SRC_SETUP
	; clear timer control registers
	clr _ml_setup_tmp
	sts _ML_TCCRA, _ml_setup_tmp
	sts _ML_TCCRB, _ml_setup_tmp
	; set timer interrupt mask
	ldi _ml_setup_tmp, OCIEA_VAL
	sts _ML_TIMSK, _ml_setup_tmp
	; setup pause
	clr _ml_setup_tmp
	sts _ml_ram_pprog, _ml_setup_tmp
	ldi _ml_setup_tmp, ML_SCREEN_PAUSE
	sts ml_ram_screen, _ml_setup_tmp
	; load
	SP_SRC_LOAD_TO_RAM ee_ml_dsoff_add, _ml_ram_pabsnc_add, 1
	SP_SRC_LOAD_TO_RAM ee_ml_dson_sub, _ml_ram_pprsnc_sub, 1

	SP_SRC_LOAD ee_ml_tim_propf
	mov rma, sp_data
	SP_SRC_LOAD ee_ml_tim_propf + 1
	mov rmb, sp_data
	call t_sr_calc
	sts _ML_OCRA, rmb
	sts _ml_ram_tcs, rmc
	; submodules
	P_SRC_SETUP _ml_setup_tmp
	G_SRC_SETUP _ml_setup_tmp, rmc
	S_SRC_SETUP _ml_setup_tmp
.endmacro

#undef _ml_setup_tmp


.dseg
_ml_ram_tcs: .byte 1
ml_ram_screen: .byte 1
_ml_ram_pprog: .byte 1
_ml_ram_pabsnc_add: .byte 1
_ml_ram_pprsnc_sub: .byte 1
.cseg

.eseg
ee_ml_tim_propf: .dw int( 0.002 * T8_PROPF + 0.5 )
ee_ml_dsoff_add: .db 4
ee_ml_dson_sub: .db 16
.cseg


#define ml_col rmd
#define ml_cl rme
#define ml_ch rmf
#define ml_tmp1 rma
#define ml_tmp2 rmb
#define ml_tmp3 rmc
#define ml_tmp4 rm0

#include "score.asm"
#include "pause.asm"
#include "game.asm"

ml_l_loop:
s_l_set_done:
_ml_l_loop_begin:
	ldi ml_col, 16

	lds ml_tmp1, ml_ram_screen
	cpi ml_tmp1, ML_SCREEN_GAME
	brne _ml_l_loop_update_paused
	rjmp _ml_g_l_update
_ml_g_update_done:
	
	lds ml_tmp1, ds_ram_out_state
	lds ml_tmp2, _ml_ram_pprog
	tst ml_tmp1
	brne _ml_l_update_sub
	lds ml_tmp1, _ml_ram_pabsnc_add
	add ml_tmp2, ml_tmp1
	brcc _ml_l_update_done
	ldi ml_tmp1, ML_SCREEN_PAUSE
	sts ml_ram_screen, ml_tmp1
	G_SRC_PAUSE
	rjmp _ml_l_update_done
_ml_l_update_sub:
	lds ml_tmp1, _ml_ram_pprsnc_sub
	sub ml_tmp2, ml_tmp1
	brcc _ml_l_update_done
	clr ml_tmp2
_ml_l_update_done:
	sts _ml_ram_pprog, ml_tmp2
	
	rjmp _ml_l_loop_column
_ml_l_loop_update_paused:
	cpi ml_tmp1, ML_SCREEN_PAUSE
	brne _ml_l_loop_column
	rjmp _ml_p_l_update

_ml_l_loop_column:
	dec ml_col

	lds ml_tmp1, ml_ram_screen
	cpi ml_tmp1, ML_SCREEN_GAME
	brne _ml_l_loop_draw_paused
	rjmp _ml_g_l_draw
_ml_l_loop_draw_paused:
	cpi ml_tmp1, ML_SCREEN_PAUSE
	brne _ml_s_l_draw
	rjmp _ml_p_l_draw

s_l_draw_done:
p_l_draw_done:
g_l_draw_done:
_ml_l_loop_flush:
	cli
	rjmp lm_l_sendcol

ml_l_sendcol_done:

#define _ml_lock ml_ch

	clr ml_tmp1
	sts _ML_TCNT, ml_tmp1
	lds ml_tmp1, _ml_ram_tcs
	sts _ML_TCCRB, ml_tmp1
	ser _ml_lock
	sei

_ml_l_loop_wait:
	tst _ml_lock
	brne _ml_l_loop_wait

	tst ml_col
	brne _ml_l_loop_column
	rjmp _ml_l_loop_begin

ISR _ML_OCAaddr
	clr _ml_lock
	sts _ML_TCCRB, _ml_lock
	reti

#undef _ml_lock

_ml_p_l_update:
	P_SRC_UPDATE ml_tmp1, ml_tmp2
	rjmp _ml_l_loop_column

_ml_s_l_draw:
	S_SRC_DRAW
	rjmp _ml_l_loop_flush

_ml_p_l_draw:
	P_SRC_DRAW
	rjmp _ml_l_loop_flush

_ml_g_l_draw:
	G_SRC_DRAW
	rjmp _ml_l_loop_flush

ml_l_gameover:
	S_SRC_SET
	rjmp ml_l_loop

_ml_g_l_update:
	G_SRC_UPDATE
	rjmp _ml_g_update_done