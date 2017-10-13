#ifdef _INC_G
#error __FILE__ already included
#else
#define _INC_G

#define _G_TIMER 3

TIM_DEF _G, _G_TIMER

#define _G_SPAWN_COUNT 4
#define _G_SPAWN_RAND_MASK (_G_SPAWN_COUNT - 1)

#define _g_setup_tmp1 @0

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
	clr YL
	ldi _g_setup_tmp1, 16*3
_g_l_setup_clear_loop:
	st X+, YL
	dec _g_setup_tmp1
	brne _g_l_setup_clear_loop
	;set empty
	ldi _g_setup_tmp1, 1
	sts _g_ram_spawn_countdown, _g_setup_tmp1
	clr _g_setup_tmp1
	sts g_ram_score, _g_setup_tmp1
	sts g_ram_score + 1, _g_setup_tmp1
	; set ds
	ldi _g_setup_tmp1, 7
	sts _g_ram_col, _g_setup_tmp1
	ldi _g_setup_tmp1, 127
	sts _g_ram_dsval, _g_setup_tmp1
	sts _g_ram_dsval_slow, _g_setup_tmp1
	; load
	SP_SRC_LOAD_TO_RAM ee_g_bm_player_acs, _g_ram_bm_player_acs, 16
	SP_SRC_LOAD_TO_RAM ee_g_bm_enemy_al, _g_ram_bm_enemy_al, 16
	SP_SRC_LOAD_TO_RAM ee_g_bm_spawns, _g_ram_bm_spawns, 2*_G_SPAWN_COUNT
	SP_SRC_LOAD_TO_RAM ee_g_spawn_period, _g_ram_spawn_period, 1
	SP_SRC_LOAD_TO_RAM ee_g_smooth, _g_ram_smooth, 1
	SP_SRC_LOAD_TO_RAM ee_g_smooth_slow, _g_ram_smooth_slow, 1
	SP_SRC_LOADI_TIME ee_g_tim_propf
	sts _G_OCRAH, sp_data_th
	sts _G_OCRAL, sp_data_tl
	ori sp_data, WGMB_VAL(4)
	sts _g_ram_tccrb, sp_data
	BZ_SRC_LOAD ee_g_snd_pause, _g_ram_snd_pause, _g_setup_tmp1
	BZ_SRC_LOAD ee_g_snd_resume, _g_ram_snd_resume, _g_setup_tmp1
	BZ_SRC_LOAD ee_g_snd_over, _g_ram_snd_over, _g_setup_tmp1
.endmacro

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
g_ram_score: .byte 2
_g_ram_bm_player_acs: .byte 16
_g_ram_bm_enemy_al: .byte 16
_g_ram_bm_spawns: .byte 2*_G_SPAWN_COUNT
_g_ram_snd_pause: .byte BZ_SND_BYTES
_g_ram_snd_resume: .byte BZ_SND_BYTES
_g_ram_snd_over: .byte BZ_SND_BYTES
.cseg

.eseg
ee_g_spawn_period: .db 8
ee_g_smooth: .db 8
ee_g_smooth_slow: .db 3
ee_g_tim_propf: .dw int( 0.1 * T16_PROPF + 0.5 )
ee_g_snd_pause:
.dw 10000, int( 0.1 * T16_PROPF + 0.5)
.dw 15000, int( 0.1 * T16_PROPF + 0.5)
.dw 0, 0
ee_g_snd_resume:
.dw 15000, int( 0.1 * T16_PROPF + 0.5)
.dw 10000, int( 0.1 * T16_PROPF + 0.5)
.dw 0, 0
ee_g_snd_over:
.dw 10000, int( 0.1 * T16_PROPF + 0.5)
.dw 15000, int( 0.1 * T16_PROPF + 0.5)
.dw 20000, int( 0.1 * T16_PROPF + 0.5)
.dw 0, 0
.cseg

#undef _g_setup_tmp1
#undef _g_setup_tmp2

#define _g_tmp1 @0
#define _g_tmp2 @1
#define _g_tmp3 @2
#define _g_tmp4 @3

.macro G_SRC_UPDATE
	rjmp _g_l_update
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

_g_l_update:
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
	swap _g_tmp1
	andi _g_tmp1, 0b00001111
	sts _g_ram_col, _g_tmp1

.endmacro

#undef _g_tmp1
#undef _g_tmp2
#undef _g_tmp3
#undef _g_tmp4

#define _g_col @0
#define _g_cl @1
#define _g_ch @2
#define _g_tmp1 @3
#define _g_tmp2 @4

.macro G_SRC_DRAW
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
	ldi XH, HIGH( _g_ram_bm_player_acs )
	ldi XL, LOW( _g_ram_bm_player_acs )
	add XL, _g_tmp1
	clr _g_tmp1
	adc XH, _g_tmp1
	ld _g_tmp1, X
	mov _g_tmp2, _g_cl
	or _g_cl, _g_tmp1
	and _g_tmp2, _g_tmp1
	breq _g_l_draw_done
	BZ_SRC_START _g_ram_snd_over
	ldi _g_tmp1, ML_SCREEN_SCORE
	sts ml_ram_screen, _g_tmp1
	clr _g_tmp1
	sts _G_TCCRB, _g_tmp1
_g_l_draw_done:
.endmacro

#undef _g_tmp1
#undef _g_tmp2
#undef _g_col
#undef _g_cl
#undef _g_ch

#define _g_tmp @0

.macro G_SRC_PAUSE
	BZ_SRC_START _g_ram_snd_pause
	clr _g_tmp
	sts _G_TCCRB, _g_tmp
.endmacro

#undef _g_tmp

#define _g_tmp @0

.macro G_SRC_RESUME
	BZ_SRC_START _g_ram_snd_resume
	lds _g_tmp, _g_ram_tccrb
	sts _G_TCCRB, _g_tmp
.endmacro

#undef _g_tmp

#define _g_tmp1 ria
#define _g_tmp2 rib
#define _g_tmp3 ric
#define _g_sl ri0
#define _g_sh ri1

ISR _G_OCAaddr
	; score
	lds ZL, g_ram_score
	lds ZH, g_ram_score + 1
	adiw ZH:ZL, 1
	sts g_ram_score, ZL
	sts g_ram_score + 1, ZH
	; spawn
	lds _g_tmp1, _g_ram_spawn_countdown
	dec _g_tmp1
	brne _g_l_oca_vframe_done
	; spawn begin
	push XL
	push XH
	lds _g_tmp1, _DS_TCNTL
	andi _g_tmp1, _G_SPAWN_RAND_MASK
	; _g_tmp1 is rand betweeen 0 and _G_SPAWN_COUNT
	ldi XL, LOW( _g_ram_bm_spawns )
	ldi XH, HIGH( _g_ram_bm_spawns )
	clr _g_tmp2
	lsl _g_tmp1
	rol _g_tmp2
	add XL, _g_tmp1
	adc XH, _g_tmp2
	ld _g_sh, X+
	ld _g_sl, X
	ldi ZL, LOW( _g_ram_frame )
	ldi ZH, HIGH( _g_ram_frame )
	ldi _g_tmp2, 16
	clr _g_tmp3
	; sh:sl is the spawn pattern, Z is the frame, tmp2 is 16, tmp3 is 0
_g_l_spawn_loop:
	lsl _g_sl
	rol _g_sh
	brcc _g_l_spawn_loop_continue
	ldi XL, LOW( _g_ram_bm_enemy_al )
	ldi XH, HIGH( _g_ram_bm_enemy_al )
	ldi _g_tmp3, 16
_g_l_spawn_loop_continue:
	tst _g_tmp3
	breq _g_l_spawn_loop_void
	dec _g_tmp3
	ld _g_tmp1, X+
	rjmp _g_l_spawn_loop_draw
_g_l_spawn_loop_void:
	clr _g_tmp1
_g_l_spawn_loop_draw:
	st Z, _g_tmp1
	adiw ZH:ZL, 3
	dec _g_tmp2
	brne _g_l_spawn_loop
	; spawn end
	lds _g_tmp1, _g_ram_spawn_period
	pop XH
	pop XL
_g_l_oca_vframe_done:
	sts _g_ram_spawn_countdown, _g_tmp1
	; shift
	ldi ZL, LOW( _g_ram_frame )
	ldi ZH, HIGH( _g_ram_frame )
	ldi _g_tmp1, 16
_g_l_oca_shift_loop:
	ld _g_tmp2, Z
	lsr _g_tmp2
	st Z+, _g_tmp2
	ld _g_tmp2, Z
	ror _g_tmp2
	st Z+, _g_tmp2
	ld _g_tmp2, Z
	ror _g_tmp2
	st Z+, _g_tmp2
	dec _g_tmp1
	brne _g_l_oca_shift_loop
	reti

#undef _g_tmp1
#undef _g_tmp2
#undef _g_sh
#undef _g_sl

#endif
