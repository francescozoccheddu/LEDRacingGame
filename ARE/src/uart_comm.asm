#ifdef MACROS
;################# MACROS #################

	.equ UC_BAUD_RATE = 9600
	.equ UC_UBRR = (FOSC / 16 / UC_BAUD_RATE - 1)

	.equ UC_UBRRH = UBRR0H
	.equ UC_UBRRL = UBRR0L
	.equ UC_UCSRA = UCSR0A
	.equ UC_UCSRB = UCSR0B
	.equ UC_UCSRC = UCSR0C
	.equ UC_UMSEL = UMSEL0
	.equ UC_UDRE = UDRE0
	.equ UC_TXEN = TXEN0
	.equ UC_UDR = UDR0
	.equ UC_UCSZ = UCSZ00

;params (0)'register'
.macro UC_SR
	push @0
	lds @0, UC_UCSRA
	sbrs @0, UC_UDRE
	rjmp PC - 3
	pop @0
	sts UC_UDR, @0
.endmacro

;params (0)'immediate'
.macro UC_SR_I
	push r16
	lds r16, UC_UCSRA
	sbrs r16, UC_UDRE
	rjmp PC - 3
	ldi r16, @0
	sts UC_UDR, r16
	pop r16
.endmacro

;params (0)'sram address'
.macro UC_SR_R
	push r16
	lds r16, UC_UCSRA
	sbrs r16, UC_UDRE
	rjmp PC - 3
	lds r16, @0
	sts UC_UDR, r16
	pop r16
.endmacro

;##########################################
#endif


#ifdef SETUP
;################## SETUP #################

	push r16
	ldi r16, LOW(UC_UBRR)
	sts UC_UBRRL, r16
	ldi r16, HIGH(UC_UBRR)
	sts UC_UBRRH, r16
	clr r16
	sts UC_UCSRA, r16
	ldi r16, (1 << UC_TXEN)
	sts UC_UCSRB, r16
	ldi r16, (2 << UC_UMSEL) | (3 << UC_UCSZ)
	sts UC_UCSRC, r16
	pop r16

;##########################################
#endif

