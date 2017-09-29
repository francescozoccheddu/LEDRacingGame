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

m_l_loop:
	
    ldi  r18, 9
    ldi  r19, 30
    ldi  r20, 229
L1: dec  r20
    brne L1
    dec  r19
    brne L1
    dec  r18
    brne L1
    nop

	BL_SRC_TOGGLE m_tmp

	rjmp m_l_loop