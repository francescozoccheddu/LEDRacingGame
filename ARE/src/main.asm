; Francesco Zoccheddu
; ARE
; main

; assembler setup

.cseg
.nooverlap

.include "m2560def.inc"

.equ FOSC = 16000000

; define ISR for interrupt address '@0'
; @0 (interrupt vector address)
.macro ISR
	.set ISR_PC = PC
	.org @0
		jmp ISR_PC
	.org ISR_PC
.endmacro

; define ISR entry '@1' for interrupt address '@0'
; @0 (interrupt vector address)
; @1 (isr entry label)
.macro ISRJ
	.set ISR_PC = PC
	.org @0
		jmp @1
	.org ISR_PC
.endmacro

.include "builtin_led.asm"
.include "led_matrix.asm"
.include "uart_comm.asm"

.org INT_VECTORS_SIZE

; main

.def m_tmp = r16

ISR 0
m_l_reset:
	; setup stack
	ldi m_tmp, HIGH(RAMEND)
	out SPH, m_tmp
	ldi m_tmp, LOW(RAMEND)
	out SPL, m_tmp
	; setup modules
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

ISR UC_URXCaddr
m_isr_tx:
	BL_SRC_TOGGLE r25
	lds r25, UC_UDR
	reti
