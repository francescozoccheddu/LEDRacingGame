#ifdef MACROS
;################# MACROS #################

	.equ BL_PORTD = DDRB
	.equ BL_PORT = PORTB
	.equ BL_PORT_BIT = PORTB7

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


#ifdef CODE
;################## CODE ##################

bl_sr_toggle:
	push r16
	push r17
	ldi r17, 1 << BL_PORT_BIT
	in r16, BL_PORT
	eor r16, r17
	out BL_PORT, r16
	pop r17
	pop r16
	ret

bl_sr_on:
	push r16
	in r16, BL_PORT
	ori r16, 1 << BL_PORT_BIT
	out BL_PORT, r16
	pop r16
	ret

bl_sr_off:
	push r16
	in r16, BL_PORT
	andi r16, ! (1 << BL_PORT_BIT)
	out BL_PORT, r16
	pop r16
	ret

;##########################################
#endif
