; Francesco Zoccheddu
; ARE
; main

; assembler setup

.cseg
.nooverlap
.org INT_VECTORS_SIZE

#define FOSC 16000000

#include "m2560def.inc"

#include "utils.asm"
#include "eeprom_prog.asm"
#include "builtin_led.asm"
#include "serial_prog.asm"
#include "buzzer.asm"
#include "led_matrix.asm"
#include "distance_sens.asm"
#include "score.asm"
#include "pause.asm"
#include "game.asm"
#include "main_loop.asm"

.eseg
#include "bitmaps.asm"
.cseg

; main

.eseg
ee_m_snd_start:
.dw 20000, int( 0.1 * T16_PROPF + 0.5)
.dw 15000, int( 0.1 * T16_PROPF + 0.5)
.dw 10000, int( 0.1 * T16_PROPF + 0.5)
.dw 0, 0
.cseg

.dseg
_m_ram_snd_start: .byte BZ_SND_BYTES
.cseg

#define m_tmp rma

ISR 0
m_l_reset:
	
	cli
	; setup stack
	STACK_SETUP m_tmp
	; setup serial programming
	SP_SRC_SETUP m_tmp
	; setup builtin LED
	BL_SRC_SETUP m_tmp
	BL_SRC_OFF m_tmp
	; setup LED matrix
	LM_SRC_SETUP m_tmp
	;setup distance sensor
	DS_SRC_SETUP m_tmp
	; setup buzzer
	BZ_SRC_SETUP m_tmp
	; setup screens
	P_SRC_SETUP m_tmp
	G_SRC_SETUP m_tmp
	S_SRC_SETUP m_tmp
	; setup draw loop
	ML_SRC_SETUP m_tmp
	; play startup sound
	BZ_SRC_LOAD ee_m_snd_start, _m_ram_snd_start, m_tmp
	BZ_SRC_START _m_ram_snd_start
	cli
	rcall ds_isr_trig
	; enter main loop
	rjmp ml_l_loop


#undef m_tmp
