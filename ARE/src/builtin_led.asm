; Francesco Zoccheddu
; ARE
; builtin LED

.equ BL_DDR = DDRB
.equ BL_PORT = PORTB
.equ BL_PIN = PINB
.equ BL_BIT = 7

; @0 (dirty immediate register)
.macro BL_SRC_SETUP
	in @0, BL_DDR
	ori @0, 1 << BL_BIT
	out BL_DDR, @0
.endmacro

; @0 (dirty immediate register)
.macro BL_SRC_ON
	in @0, BL_PORT
	ori @0, 1 << BL_BIT
	out BL_PORT, @0
.endmacro

; @0 (dirty immediate register)
.macro BL_SRC_OFF
	in @0, BL_PORT
	andi @0, ~(1 << BL_BIT)
	out BL_PORT, @0
.endmacro

; @0 (dirty immediate register)
.macro BL_SRC_TOGGLE
	ldi @0, 1 << BL_BIT
	out BL_PIN, @0
.endmacro


