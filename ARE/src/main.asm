; Francesco Zoccheddu
; ARE
; main

; assembler setup

.cseg
.nooverlap

.include "m2560def.inc"

.equ FOSC = 16000000

.macro INTVEC
	.set INTVECM_PC = PC
	.org @0
		jmp @1
	.org INTVECM_PC
.endmacro

.include "builtin_led.asm"
.include "led_matrix.asm"

.org INT_VECTORS_SIZE

; main

INTVEC 0, m_l_reset

.def m_tmp = r16

m_l_reset:
	; setup stack
	ldi m_tmp, HIGH(RAMEND)
	out SPH, m_tmp
	ldi m_tmp, LOW(RAMEND)
	out SPL, m_tmp
	;setup modules
	;setup builtin LED
	BL_SRC_SETUP m_tmp
	;setup LED matrix
	LM_SRC_SETUP m_tmp

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