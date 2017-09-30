; Francesco Zoccheddu
; ARE
; main

; assembler setup

.cseg
.nooverlap
.org INT_VECTORS_SIZE

.include "m2560def.inc"
#include "utils.inc"

.equ FOSC = 16000000

.def intr0 = r17
.def intr1 = r18
.def intr2 = r19
.def intr3 = r20
.def intr4 = r2
.def intr5 = r3
.def intr6 = r4
.def intr7 = r5
.def intr8 = r6
.def intr9 = r7

.include "builtin_led.asm"
.include "led_matrix.asm"
.include "uart_comm.asm"
.include "distance_sens.asm"

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
	;setup distance sensor
	DS_SRC_SETUP m_tmp
	call ds_isr_trig
	;enable interrupts
	sei

.undef m_tmp

m_l_loop:
	
	.def m_col = r23
	.def m_ch = r24
	.def m_cl = r25
	
	ldi m_col, 16
m_l_cloop:
	mov m_ch, m_col
	ldi m_cl, 3
	LM_SRC_SEND_COL m_ch, m_cl, m_col, r19, r20

	;wait
	ldi m_cl, 255
m_l_wait:
	dec m_cl
	brne m_l_wait


	;loop col
	dec m_col
	brne m_l_cloop

	;loop draw
	rjmp m_l_loop

ISR UC_RCOMPLETE_INTaddr
m_isr_tx:
	UC_SRC_FR intr1
	UC_SRC_TREADY_INTE 1, intr1
	reti

ISR UC_TREADY_INTaddr
m_isr_e:
	ldi intr1, '+'
	UC_SRC_FT intr1
	UC_SRC_TREADY_INTE 0, intr1
	reti