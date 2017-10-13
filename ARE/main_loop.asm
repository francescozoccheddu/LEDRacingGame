#ifdef _INC_ML
#error __FILE__ already included
#else
#define _INC_ML

; Francesco Zoccheddu
; ARE
; EEPROM programming
; dirty timer 0 and registers


#define _ML_TIMER 2

TIM_DEF _ML, _ML_TIMER

.equ ML_SCREEN_PAUSE = 2
.equ ML_SCREEN_SCORE = 1
.equ ML_SCREEN_GAME = 0

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

	SP_SRC_LOADI_TIME ee_ml_tim_propf
	sts _ML_OCRA, sp_data_th
	sts _ml_ram_tcs, sp_data
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


#define ml_cl @0
#define ml_ch @1
#define ml_tmp1 @2
#define ml_tmp2 @3
#define ml_col @4
#define ml_tmp3 @5
#define ml_tmp4 @6

.macro ML_SRC_LOOP
_ml_l_loop:
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
	G_SRC_PAUSE ml_tmp1
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

_ml_l_loop_flush:
	cli
	rjmp _ml_lm_l_sendcol

_ml_l_sendcol_done:

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
	rjmp _ml_l_loop

ISR _ML_OCAaddr
	clr _ml_lock
	sts _ML_TCCRB, _ml_lock
	reti

#undef _ml_lock

_ml_p_l_update:
	P_SRC_UPDATE ml_tmp1, ml_tmp2
	rjmp _ml_l_loop_column

_ml_s_l_draw:
	S_SRC_DRAW ml_col, ml_cl, ml_ch, ml_tmp1, ml_tmp2
	rjmp _ml_l_loop_flush

_ml_p_l_draw:
	P_SRC_DRAW ml_col, ml_cl, ml_ch, ml_tmp1
	rjmp _ml_l_loop_flush

_ml_g_l_draw:
	G_SRC_DRAW ml_col, ml_cl, ml_ch, ml_tmp1, ml_tmp2
	lds ml_tmp1, ml_ram_screen
	cpi ml_tmp1, ML_SCREEN_SCORE
	breq _ml_l_gameover
	rjmp _ml_l_loop_flush

_ml_lm_l_sendcol:
	LM_SRC_SENDCOL ml_col, ml_cl, ml_ch, ml_tmp1, ml_tmp2
	rjmp _ml_l_sendcol_done

_ml_l_gameover:
	S_SRC_SET ml_tmp1, ml_tmp2, ml_cl, ml_ch
	rjmp _ml_l_loop

_ml_g_l_update:
	G_SRC_UPDATE ml_tmp1, ml_tmp2, ml_tmp3, ml_tmp4
	rjmp _ml_g_update_done

.endmacro

#undef ml_col 
#undef ml_cl 
#undef ml_ch 
#undef ml_tmp1 
#undef ml_tmp2 
#undef ml_tmp3 
#undef ml_tmp4 

#endif
