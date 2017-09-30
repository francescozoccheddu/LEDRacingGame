; Francesco Zoccheddu
; ARE
; builtin LED
; dirty PORTB[7], DDRB[7], PINB[7]

#define _BL_IO B

IO_DEF _BL, _BL_IO
.equ _BL_BIT = 7

.equ _BL_BACKUP_EXTRA_PINS = 0

; [SOURCE] setup
; @0 (dirty immediate register)
.macro BL_SRC_SETUP
	; set data direction register to output for LED pin
	.if _BL_BACKUP_EXTRA_PINS
		in @0, _BL_DDR
		ori @0, 1 << _BL_BIT
	.else
		ldi @0, 1 << _BL_BIT
	.endif
	out _BL_DDR, @0
.endmacro

; [SOURCE] turn builtin LED on
; @0 (dirty immediate register)
.macro BL_SRC_ON
	.if _BL_BACKUP_EXTRA_PINS
		in @0, _BL_PORT
		ori @0, 1 << _BL_BIT
	.else
		ldi @0, 1 << _BL_BIT
	.endif
	out _BL_PORT, @0
.endmacro

; [SOURCE] turn builtin LED off
; @0 (dirty immediate register)
.macro BL_SRC_OFF
	.if _BL_BACKUP_EXTRA_PINS
		in @0, _BL_PORT
		andi @0, ~(1 << _BL_BIT)
	.else
		clr @0
	.endif
	out _BL_PORT, @0
.endmacro

; [SOURCE] toggle builtin LED state
; @0 (dirty immediate register)
.macro BL_SRC_TOGGLE
	ldi @0, 1 << _BL_BIT
	out _BL_PIN, @0
.endmacro


