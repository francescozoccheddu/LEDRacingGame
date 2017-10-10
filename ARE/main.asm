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
#include "uart_comm.asm"
#include "serial_prog.asm"
#include "main_loop.asm"
#include "led_matrix.asm"
#include "distance_sens.asm"
#include "buzzer.asm"

.eseg
#include "bitmaps.asm"
.cseg

; main

#define m_tmp rma

ISR 0
m_l_reset:	
	cli
	; setup stack
	STACK_SETUP m_tmp
	; setup builtin LED
	BL_SRC_SETUP m_tmp
	BL_SRC_OFF m_tmp
	; setup LED matrix
	LM_SRC_SETUP m_tmp
	; setup UART communication
	UC_SRC_SETUP m_tmp
	;setup distance sensor
	DS_SRC_SETUP m_tmp
	call ds_isr_trig
	; setup buzzer
	BZ_SRC_SETUP m_tmp
	; setup draw loop
	ML_SRC_SETUP m_tmp
	sei
	; enter main loop
	rjmp ml_l_loop


#undef m_tmp
