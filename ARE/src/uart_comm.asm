; Francesco Zoccheddu
; ARE
; UART communication

.equ UC_BAUDRATE = 9600
.equ UC_UBRR = FOSC / 16 / UC_BAUDRATE - 1

.equ UC_UBRRH = UBRR0H
.equ UC_UBRRL = UBRR0L
.equ UC_UDR = UDR0
.equ UC_UCSRA = UCSR0A
.equ UC_UCSRA_VAL = 0
.equ UC_UCSRB = UCSR0B
.equ UC_UCSRB_VAL = (0 << RXEN0) | (1 << TXEN0)
.equ UC_UCSRC = UCSR0C
.equ UC_UCSRC_VAL = (2 << UMSEL0) | (3 << UCSZ00)

; [SOURCE] setup
; @0 (dirty immediate register)
.macro UC_SRC_SETUP
	; set UBRRR
	ldi @0, LOW( UC_UBRR )
	sts UC_UBRRL, @0
	ldi @0, HIGH( UC_UBRR )
	sts UC_UBRRH, @0
	; set UCSRA
	ldi @0, UC_UCSRA_VAL
	sts UC_UCSRA, @0
	; set UCSRB
	ldi @0, UC_UCSRB_VAL
	sts UC_UCSRB, @0
	; set UCSRC
	ldi @0, UC_UCSRC_VAL
	sts UC_UCSRC, @0
.endmacro

.macro UC_SR_I
	lds @1, UC_UCSRA
	sbrs @1, UDRE0
	rjmp PC - 3
	ldi @1, @0
	sts UC_UDR, @1
.endmacro

.macro UC_SR
	lds @1, UC_UCSRA
	sbrs @1, UDRE0
	rjmp PC - 3
	sts UC_UDR, @0
.endmacro