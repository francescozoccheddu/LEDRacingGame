; Francesco Zoccheddu
; ARE
; main

; assembler setup

.cseg
.nooverlap

.include "m2560def.inc"
#include "utils.inc"

.equ FOSC = 16000000

.include "builtin_led.asm"
.include "led_matrix.asm"
.include "uart_comm.asm"
.include "distance_sens.asm"

.org INT_VECTORS_SIZE

; main

.def m_tmp = r16

ISR 0
m_l_reset:
	; setup stack
	STACK_SETUP m_tmp
	; setup builtin LED
	BL_SRC_SETUP m_tmp
	BL_SRC_OFF m_tmp
	; setup LED matrix
	LM_SRC_SETUP m_tmp
	; setup UART communication
	UC_SRC_SETUP m_tmp
	;enable interrupts
	sei

.undef m_tmp

m_l_loop:
	
	.def m_col = r16
	.def m_ch = r17
	.def m_cl = r18
	
	ldi m_col, 16
m_l_cloop:
	mov m_ch, m_col
	ldi m_cl, 3
	LM_SRC_SEND_COL m_ch, m_cl, m_col, r19, r20

	;wait
	ldi r19, 255
m_l_wait:
	dec r19
	brne m_l_wait


	;loop col
	dec m_col
	brne m_l_cloop

	;loop draw
	rjmp m_l_loop

ISR UC_RCOMPLETE_INTaddr
m_isr_tx:
	BL_SRC_TOGGLE r25
	UC_SRC_FR r25
	UC_SRC_TREADY_INTE 1, r26
	reti

ISR UC_TREADY_INTaddr
m_isr_e:
	UC_SRC_FT r25
	UC_SRC_TREADY_INTE 0, r26
	reti