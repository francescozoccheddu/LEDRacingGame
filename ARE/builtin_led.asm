#ifndef _INC_BL
#define _INC_BL

#include "utils.asm"

; Francesco Zoccheddu
; ARE
; builtin LED
; dirty IO B

#define _BL_IO B

IO_DEF _BL, _BL_IO
#define _BL_BIT 7

#define _bl_r_tmp @0

; [SOURCE] setup
; @0 (dirty immediate register)
.macro BL_SRC_SETUP
	; set data direction register to output for LED pin
	ldi _bl_r_tmp, 1 << _BL_BIT
	out _BL_DDR, _bl_r_tmp
.endmacro

; [SOURCE] turn builtin LED on
; @0 (dirty immediate register)
.macro BL_SRC_ON
	ser _bl_r_tmp
	out _BL_PORT, _bl_r_tmp
.endmacro

; [SOURCE] turn builtin LED off
; @0 (dirty immediate register)
.macro BL_SRC_OFF
	clr _bl_r_tmp
	out _BL_PORT, _bl_r_tmp
.endmacro

; [SOURCE] toggle builtin LED state
; @0 (dirty immediate register)
.macro BL_SRC_TOGGLE
	ser _bl_r_tmp
	out _BL_PIN, _bl_r_tmp
.endmacro

; [SOURCE] set builtin LED state (dirty all port pins)
; @0 (state on bit 7)
.macro BL_SRC_OUT
	out _BL_PORT, _bl_r_tmp
.endmacro

#undef _bl_r_tmp

#endif
