; Francesco Zoccheddu
; ARE
; builtin LED
; dirty PORTB[7], DDRB[7], PINB[7]

.equ BL_DDR = DDRB
.equ BL_PORT = PORTB
.equ BL_PIN = PINB
.equ BL_BIT = 7

; [SOURCE] setup
; @0 (dirty immediate register)
.macro BL_SRC_SETUP
	; set data direction register to output for LED pin
	in @0, BL_DDR
	ori @0, 1 << BL_BIT
	out BL_DDR, @0
.endmacro

; [SOURCE] turn builtin LED on
; @0 (dirty immediate register)
.macro BL_SRC_ON
	in @0, BL_PORT
	ori @0, 1 << BL_BIT
	out BL_PORT, @0
.endmacro

; [SOURCE] turn builtin LED off
; @0 (dirty immediate register)
.macro BL_SRC_OFF
	in @0, BL_PORT
	andi @0, ~(1 << BL_BIT)
	out BL_PORT, @0
.endmacro

; [SOURCE] toggle builtin LED state
; @0 (dirty immediate register)
.macro BL_SRC_TOGGLE
	ldi @0, 1 << BL_BIT
	out BL_PIN, @0
.endmacro


