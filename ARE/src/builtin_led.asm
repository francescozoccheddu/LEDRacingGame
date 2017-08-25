#ifdef MACROS
;################# MACROS #################

	.equ BL_PORTD = DDRB
	.equ BL_PORT = PORTB
	.equ BL_PIN = PINB
	.equ BL_BIT = PORTB7 ;digital pin 13

;params (0)'dirty register'
.macro BL_SR_ON
	in @0, BL_PORT
	ori @0, 1 << BL_BIT
	out BL_PORT, @0
.endmacro

;params (0)'dirty register'
.macro BL_SR_OFF
	in @0, BL_PORT
	andi @0, !(1 << BL_BIT)
	out BL_PORT, @0
.endmacro

;params (0)'dirty register'
.macro BL_SR_TOGGLE
	ldi @0, 1 << BL_BIT
	out BL_PIN, @0
.endmacro

;##########################################
#endif


#ifdef SETUP
;################## SETUP #################

	push r16
	in r16, BL_PORT
	ori r16, 1 << BL_BIT
	out BL_PORTD, r16
	pop r16

;##########################################
#endif
