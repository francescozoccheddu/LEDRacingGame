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

;include interrupt subroutine defs
#define INTV
;################## INTV ##################

.org 0
	rjmp main

#include "includes.inc"
#include "main.asm"

;##########################################
#undef INTV

.org INT_VECTORS_SIZE
#define CODE
;################## CODE ##################

#include "includes.inc"

;##########################################
#undef CODE

main:
	;setup stack
	ldi r16, HIGH(RAMEND)
	out SPH, r16
	ldi r16, LOW(RAMEND)
	out SPL, r16

;setup includes
#define SETUP
;################## SETUP #################

#include "includes.inc"
#include "main.asm"

;##########################################
#undef SETUP

#define CODE
;################## CODE ##################

#include "main.asm"

;##########################################
#undef CODE
