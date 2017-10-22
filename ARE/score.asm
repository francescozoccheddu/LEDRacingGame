#ifndef _INC_S
#define _INC_S

; Francesco Zoccheddu
; ARE
; score
; dirty timer 5

#include "utils.asm"
#include "main_loop.asm"
#include "game.asm"
#include "serial_prog.asm"

#define _S_TIMER 5

TIM_DEF _S, _S_TIMER

#define _S_STATE_SCR 0
#define _S_STATE_TOP 1
#define _S_STATE_SPLASH 2

#define _s_r_setup_tmp @0

.macro S_SRC_SETUP
	; clear timer control registers
	clr _s_r_setup_tmp
	sts _S_TCCRA, _s_r_setup_tmp
	sts _S_TCCRB, _s_r_setup_tmp
	sts _S_TCCRC, _s_r_setup_tmp
	; set timer interrupt mask
	ldi _s_r_setup_tmp, OCIEA_VAL
	sts _S_TIMSK, _s_r_setup_tmp
	; set state
	ldi _s_r_setup_tmp, _S_STATE_SPLASH
	sts _s_ram_state, _s_r_setup_tmp
	; load bitmaps
	SP_SRC_LOAD_TO_RAM ee_s_bm_splash, _s_ram_bm_splash, 2*16
	SP_SRC_LOAD_TO_RAM ee_s_bm_scr, _s_ram_bm_scr, 16
	SP_SRC_LOAD_TO_RAM ee_s_bm_top, _s_ram_bm_top, 16
	SP_SRC_LOAD_TO_RAM ee_s_bm_digits, _s_ram_bm_digits, 12*4

	SP_SRC_LOADI_TIME ee_s_tim_splash
	sts _s_ram_ttop_splash, sp_data_tl
	sts _s_ram_ttop_splash + 1, sp_data_th
	sts _s_ram_tccrb_splash, sp_data

	SP_SRC_LOADI_TIME ee_s_tim_scr
	sts _s_ram_ttop_scr, sp_data_tl
	sts _s_ram_ttop_scr + 1, sp_data_th
	sts _s_ram_tccrb_scr, sp_data

	SP_SRC_LOADI_TIME ee_s_tim_top
	sts _s_ram_ttop_top, sp_data_tl
	sts _s_ram_ttop_top + 1, sp_data_th
	sts _s_ram_tccrb_top, sp_data
.endmacro

#undef _s_r_setup_tmp

.eseg
; name="Game over screen duration"
; description=""
; type="real"
; size=2
; data={"fromh":499.968,"toh":4194.24,"fromb":7812,"tob":65535,"unit":"ms"}
ee_s_tim_splash: .dw int( 1 * T16_PROPF + 0.5)
; name="Last score screen duration"
; description=""
; type="real"
; size=2
; data={"fromh":499.968,"toh":4194.24,"fromb":7812,"tob":65535,"unit":"ms"}
ee_s_tim_scr: .dw int( 2 * T16_PROPF + 0.5)
; name="Record score screen duration"
; description=""
; type="real"
; size=2
; data={"fromh":499.968,"toh":4194.24,"fromb":7812,"tob":65535,"unit":"ms"}
ee_s_tim_top: .dw int( 1.5 * T16_PROPF + 0.5)
; name="Record score"
; description=""
; type="int"
; size=2
; data={"from":0,"to":65535}
ee_s_top: .dw 14
; name="Digits bitmap"
; description="Description"
; type="bitmap"
; size=48
; data={"rows":8,"columns":4,"horizontaldata":false,"count":12}
ee_s_bm_digits:
#include "bitmaps/s_bm_digits.asm"
; name="Last score bitmap"
; description=""
; type="bitmap"
; size=16
; data={"rows":8,"columns":16,"horizontaldata":false,"count":1}
ee_s_bm_scr:
#include "bitmaps/s_bm_scr.asm"
; name="Game over bitmap"
; description=""
; type="bitmap"
; size=16
; data={"rows":8,"columns":16,"horizontaldata":false,"count":1}
ee_s_bm_splash:
#include "bitmaps/s_bm_splash.asm"
; name="Record score bitmap"
; description=""
; type="bitmap"
; size=32
; data={"rows":16,"columns":16,"horizontaldata":false,"count":1}
ee_s_bm_top:
#include "bitmaps/s_bm_top.asm"
.cseg

.dseg
_s_ram_state: .byte 1
_s_ram_tccrb_splash: .byte 1
_s_ram_ttop_splash: .byte 2
_s_ram_tccrb_scr: .byte 1
_s_ram_ttop_scr: .byte 2
_s_ram_tccrb_top: .byte 1
_s_ram_ttop_top: .byte 2
_s_ram_bcd_top: .byte 4
_s_ram_bcd_scr: .byte 4
_s_ram_bm_splash: .byte 2*16
_s_ram_bm_top: .byte 16
_s_ram_bm_scr: .byte 16
_s_ram_bm_digits: .byte 12*4
.cseg

#define _s_r_draw_col @0
#define _s_r_draw_cl @1
#define _s_r_draw_ch @2
#define _s_r_draw_tmp1 @3
#define _s_r_draw_tmp2 @4

.macro S_SRC_DRAW
	lds _s_r_draw_tmp1, _s_ram_state
	cpi _s_r_draw_tmp1, _S_STATE_SCR
	breq _s_l_draw_scr
	cpi _s_r_draw_tmp1, _S_STATE_SPLASH
	breq _s_l_draw_splash
	ldi XL, LOW( _s_ram_bm_top )
	ldi XH, HIGH( _s_ram_bm_top )
	ldi YL, LOW( _s_ram_bcd_top )
	ldi YH, HIGH( _s_ram_bcd_top )
	rjmp _s_l_draw_text
_s_l_draw_scr:
	ldi XL, LOW( _s_ram_bm_scr )
	ldi XH, HIGH( _s_ram_bm_scr )
	ldi YL, LOW( _s_ram_bcd_scr )
	ldi YH, HIGH( _s_ram_bcd_scr )
_s_l_draw_text:
	clr _s_r_draw_tmp1
	add XL, _s_r_draw_col
	adc XH, _s_r_draw_tmp1
	ld _s_r_draw_ch, X
	; draw score
	mov _s_r_draw_tmp1, _s_r_draw_col
	lsr _s_r_draw_tmp1
	lsr _s_r_draw_tmp1
	add YL, _s_r_draw_tmp1
	clr _s_r_draw_tmp1
	adc YH, _s_r_draw_tmp1
	ld _s_r_draw_tmp1, Y
	lsl _s_r_draw_tmp1
	lsl _s_r_draw_tmp1
	mov _s_r_draw_tmp2, _s_r_draw_col
	andi _s_r_draw_tmp2, 0b11
	add _s_r_draw_tmp1, _s_r_draw_tmp2
	ldi YL, LOW( _s_ram_bm_digits )
	ldi YH, HIGH( _s_ram_bm_digits )
	add YL, _s_r_draw_tmp1
	clr _s_r_draw_tmp1
	adc YH, _s_r_draw_tmp1
	ld _s_r_draw_cl, Y
	rjmp _s_l_draw_done
_s_l_draw_splash:
	ldi XL, LOW( _s_ram_bm_splash )
	ldi XH, HIGH( _s_ram_bm_splash )
	mov _s_r_draw_tmp1, _s_r_draw_col
	lsl _s_r_draw_tmp1
	add XL, _s_r_draw_tmp1
	clr _s_r_draw_tmp1
	adc XH, _s_r_draw_tmp1
	ld _s_r_draw_ch, X+
	ld _s_r_draw_cl, X
_s_l_draw_done:
.endmacro

#undef _s_r_draw_col
#undef _s_r_draw_cl
#undef _s_r_draw_ch
#undef _s_r_draw_tmp1
#undef _s_r_draw_tmp2

#define _s_r_set_tmp1 @0
#define _s_r_set_tmp2 @1
#define _s_r_set_tmp3 @2
#define _s_r_set_tmp4 @3

.macro S_SRC_SET
	rjmp _s_l_set

#define _s_rr_set_bcd_l _s_r_set_tmp1
#define _s_rr_set_bcd_h _s_r_set_tmp2
#define _s_rr_set_bcd_z _s_r_set_tmp3
#define _s_rr_set_bcd_c _s_r_set_tmp4

_s_sr_tobcd:
	ldi _s_rr_set_bcd_z, HIGH(1000)
	cpi _s_rr_set_bcd_l, LOW(1000)
	cpc _s_rr_set_bcd_h, _s_rr_set_bcd_z
	brsh _s_l_sr_to_s_rr_set_bcd_overflow
	ldi _s_rr_set_bcd_z, 11
	std Y+1, _s_rr_set_bcd_z
	std Y+2, _s_rr_set_bcd_z
	std Y+3, _s_rr_set_bcd_z
_s_l_sr_to_s_rr_set_bcd_th_begin:
	ldi _s_rr_set_bcd_c, 0
	clr _s_rr_set_bcd_z
_s_l_sr_to_s_rr_set_bcd_th_loop:
	cpi _s_rr_set_bcd_l, 100
	cpc _s_rr_set_bcd_h, _s_rr_set_bcd_z
	brlo _s_l_sr_to_s_rr_set_bcd_th_done
	inc _s_rr_set_bcd_c
	subi _s_rr_set_bcd_l, 100
	sbc _s_rr_set_bcd_h, _s_rr_set_bcd_z
	rjmp _s_l_sr_to_s_rr_set_bcd_th_loop
_s_l_sr_to_s_rr_set_bcd_th_done:
	tst _s_rr_set_bcd_c
	breq _s_l_sr_to_s_rr_set_bcd_nd_loop
	st Y+, _s_rr_set_bcd_c
	ldi _s_rr_set_bcd_c, 1 << 7
_s_l_sr_to_s_rr_set_bcd_nd_loop:
	cpi _s_rr_set_bcd_l, 10
	brlo _s_l_sr_to_s_rr_set_bcd_nd_done
	inc _s_rr_set_bcd_c
	subi _s_rr_set_bcd_l, 10
	rjmp _s_l_sr_to_s_rr_set_bcd_nd_loop
_s_l_sr_to_s_rr_set_bcd_nd_done:
	tst _s_rr_set_bcd_c
	breq _s_l_sr_to_s_rr_set_bcd_rd
	andi _s_rr_set_bcd_c, ~(1 << 7)
	st Y+, _s_rr_set_bcd_c
_s_l_sr_to_s_rr_set_bcd_rd:
	st Y+, _s_rr_set_bcd_l
	ret
_s_l_sr_to_s_rr_set_bcd_overflow:
	ldi _s_rr_set_bcd_z, 9
	st Y+, _s_rr_set_bcd_z
	st Y+, _s_rr_set_bcd_z
	st Y+, _s_rr_set_bcd_z
	ldi _s_rr_set_bcd_z, 10
	st Y, _s_rr_set_bcd_z
	ret

#undef _s_rr_set_bcd_l
#undef _s_rr_set_bcd_h
#undef _s_rr_set_bcd_z
#undef _s_rr_set_bcd_c

_s_l_set:
	; set state
	ldi _s_r_set_tmp1, _S_STATE_SPLASH
	sts _s_ram_state, _s_r_set_tmp1
	; set timer
	lds _s_r_set_tmp1, _s_ram_ttop_splash
	lds _s_r_set_tmp2, _s_ram_ttop_splash + 1
	sts _S_OCRAH, _s_r_set_tmp2
	sts _S_OCRAL, _s_r_set_tmp1
	lds _s_r_set_tmp1, _s_ram_tccrb_splash
	sts _S_TCCRB, _s_r_set_tmp1
	; save score
	SP_SRC_LOAD ee_s_top
	mov _s_r_set_tmp1, sp_data
	SP_SRC_LOAD ee_s_top + 1
	mov _s_r_set_tmp2, sp_data
	lds _s_r_set_tmp3, g_ram_score
	lds _s_r_set_tmp4, g_ram_score + 1
	cp _s_r_set_tmp1, _s_r_set_tmp3
	cpc _s_r_set_tmp2, _s_r_set_tmp4
	brsh _s_l_set_stored
	mov sp_data, _s_r_set_tmp3
	SP_SRC_STORE ee_s_top
	mov sp_data, _s_r_set_tmp4
	SP_SRC_STORE ee_s_top + 1
	movw _s_r_set_tmp2:_s_r_set_tmp1, _s_r_set_tmp4:_s_r_set_tmp3
_s_l_set_stored:
	; load score
	ldi YL, LOW(_s_ram_bcd_top)
	ldi YH, HIGH(_s_ram_bcd_top)
	rcall _s_sr_tobcd
	ldi YL, LOW(_s_ram_bcd_scr)
	ldi YH, HIGH(_s_ram_bcd_scr)
	lds _s_r_set_tmp1, g_ram_score
	lds _s_r_set_tmp2, g_ram_score + 1
	rcall _s_sr_tobcd
.endmacro

#undef _s_r_set_tmp1
#undef _s_r_set_tmp2
#undef _s_r_set_tmp3
#undef _s_r_set_tmp4

#define _s_r_ocia_tmp1 ria
#define _s_r_ocia_tmp2 ri0
#define _s_r_ocia_tmp3 ri1
#define _s_r_ocia_tmp4 ri2

ISR _S_OCAaddr
	clr _s_r_ocia_tmp1
	sts _S_TCCRB, _s_r_ocia_tmp1
	sts _S_TCNTH, _s_r_ocia_tmp1
	sts _S_TCNTL, _s_r_ocia_tmp1
	lds _s_r_ocia_tmp1, _s_ram_state
	cpi _s_r_ocia_tmp1, _S_STATE_SCR
	breq _s_l_isr_oca_scr
	; from top
	ldi _s_r_ocia_tmp1, _S_STATE_SCR
	lds _s_r_ocia_tmp2, _s_ram_ttop_scr
	lds _s_r_ocia_tmp3, _s_ram_ttop_scr + 1
	lds _s_r_ocia_tmp4, _s_ram_tccrb_scr
	rjmp _s_l_isr_oca_done
_s_l_isr_oca_scr:
	; from scr
	ldi _s_r_ocia_tmp1, _S_STATE_TOP
	lds _s_r_ocia_tmp2, _s_ram_ttop_top
	lds _s_r_ocia_tmp3, _s_ram_ttop_top + 1
	lds _s_r_ocia_tmp4, _s_ram_tccrb_top
_s_l_isr_oca_done:
	sts _s_ram_state, _s_r_ocia_tmp1
	sts _S_OCRAH, _s_r_ocia_tmp3
	sts _S_OCRAL, _s_r_ocia_tmp2
	sts _S_TCCRB, _s_r_ocia_tmp4
	reti

#undef _s_r_ocia_tmp1
#undef _s_r_ocia_tmp2
#undef _s_r_ocia_tmp3
#undef _s_r_ocia_tmp4
	
#endif
