.ifndef inC_LED_ASM
.equ inC_LED_ASM = 0

.equ LED_PORTD = DDRB
.equ LED_PORT = PORTB
.equ LED_PORT_BIT = PORTB7

;setup subroutine
.macro LED_SR_SETUP
	push r16
	in r16, LED_PORT
	ori r16, 1 << LED_PORT_BIT
	out LED_PORTD, r16
	pop r16
.endmacro


;toggle subroutine
led_sr_toggle:
	push r16
	push r17
	ldi r17, 1 << LED_PORT_BIT
	in r16, LED_PORT
	eor r16, r17
	out LED_PORT, r16
	pop r17
	pop r16
	ret

;power on subroutine
led_sr_on:
	push r16
	in r16, LED_PORT
	ori r16, 1 << LED_PORT_BIT
	out LED_PORT, r16
	pop r16
	ret

;power on subroutine
led_sr_off:
	push r16
	in r16, LED_PORT
	andi r16, ! (1 << LED_PORT_BIT)
	out LED_PORT, r16
	pop r16
	ret

.endif
