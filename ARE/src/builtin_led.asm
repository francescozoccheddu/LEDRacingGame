; Francesco Zoccheddu
; ARE
; builtin LED
; dirty PORTB[7], DDRB[7], PINB[7]

.warning "TODO: stop keeping PORTB[6:0] clean"

#define _BL_IO B

IO_DEF _BL, _BL_IO
.equ _BL_BIT = 7

; [SOURCE] setup
; @0 (dirty immediate register)
.macro BL_SRC_SETUP
	; set data direction register to output for LED pin
	in @0, _BL_DDR
	ori @0, 1 << _BL_BIT
	out _BL_DDR, @0
.endmacro

; [SOURCE] turn builtin LED on
; @0 (dirty immediate register)
.macro BL_SRC_ON
	in @0, _BL_PORT
	ori @0, 1 << _BL_BIT
	out _BL_PORT, @0
.endmacro

; [SOURCE] turn builtin LED off
; @0 (dirty immediate register)
.macro BL_SRC_OFF
	in @0, _BL_PORT
	andi @0, ~(1 << _BL_BIT)
	out _BL_PORT, @0
.endmacro

; [SOURCE] toggle builtin LED state
; @0 (dirty immediate register)
.macro BL_SRC_TOGGLE
	ldi @0, 1 << _BL_BIT
	out _BL_PIN, @0
.endmacro


