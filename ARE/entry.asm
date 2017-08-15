;device defs
.include "m2560def.inc"

;configuration defs
.equ FOSC = 16000000

;include ram defs
.set ENTRY_RAM_PTR = SRAM_START

;params (0)'name' (1)'bytes'
.macro def_sram_bytes
	.equ @0 = ENTRY_RAM_PTR
	.set ENTRY_RAM_PTR = ENTRY_RAM_PTR + @1
.endmacro

;params (0)'name'
.macro def_sram_byte
	def_ram_bytes @0, 1
.endmacro

#define SRAM
#include "includes.inc"
#include "main.asm"
#undef SRAM

;include macro defs
#define MACROS
#include "includes.inc"
#include "main.asm"
#undef MACROS

;include interrupt subroutine defs
#define INTV
#include "includes.inc"
#include "main.asm"
#undef INTV

.org 0
	rjmp main

;include subroutine defs
#define CODE
.org INT_VECTORS_SIZE
#include "includes.inc"
#undef CODE

main:
	;setup stack
	ldi r16, HIGH(RAMEND)
	out SPH, r16
	ldi r16, LOW(RAMEND)
	out SPL, r16

;setup includes
#define SETUP
#include "includes.inc"
#undef SETUP

;call main
#define CODE
#include "main.asm"
#undef CODE
