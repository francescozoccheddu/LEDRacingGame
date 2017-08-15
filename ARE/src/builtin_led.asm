#ifdef MACROS
;################# MACROS #################

	.equ BL_PORTD = DDRB
	.equ BL_PORT = PORTB
	.equ BL_PORT_BIT = PORTB7

;params (0)'dirty register'
.macro BL_SR_ON
	in @0, BL_PORT
	ori @0, 1 << BL_PORT_BIT
	out BL_PORT, @0
.endmacro

;params (0)'dirty register'
.macro BL_SR_OFF
	in @0, BL_PORT
	andi @0, !(1 << BL_PORT_BIT)
	out BL_PORT, @0
.endmacro

;params (0)'dirty register'
.macro BL_SR_TOGGLE
	in @0, BL_PORT
	andi @0, !(1 << BL_PORT_BIT)
	sbrs @0, BL_PORT_BIT
	ori @0, 1 << BL_PORT_BIT
	out BL_PORT, @0
.endmacro

;params (0)'subroutine'
.macro BL_M_SAFE
	push r16
	@0 r16
	pop r16
.endmacro

;##########################################
#endif


#ifdef SETUP
;################## SETUP #################

	push r16
	in r16, BL_PORT
	ori r16, 1 << BL_PORT_BIT
	out BL_PORTD, r16
	pop r16

;##########################################
#endif
