;device defs
.include "m2560def.inc"

;configuration defs
.equ FOSC = 16000000

;include ram defs
.set ENTRY_RAM_PTR = SRAM_START

;params (0)'name' (1)'bytes'
.macro sram_bytes
	.equ @0 = ENTRY_RAM_PTR
	.set ENTRY_RAM_PTR = ENTRY_RAM_PTR + @1
.endmacro

;params (0)'name'
.macro sram_byte
	sram_bytes @0, 1
.endmacro

.org 0
	rjmp entry_l_pre_reset

#define INTV
;################## INTV ##################

#include "includes.inc"

;##########################################
#undef INTV

.org INT_VECTORS_SIZE
entry_l_pre_reset:
	;setup stack
	ldi r16, HIGH(RAMEND)
	out SPH, r16
	ldi r16, LOW(RAMEND)
	out SPL, r16

#define SETUP
;################## SETUP #################

#include "includes.inc"

;##########################################
#undef SETUP

jmp entry_l_reset

#define CODE
;################## CODE ##################

#include "includes.inc"

;##########################################
#undef CODE

