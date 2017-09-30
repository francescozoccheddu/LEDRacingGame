; Francesco Zoccheddu
; ARE
; UART communication
; dirty USART0 module and registers

.equ _UC_BAUDRATE = 9600

.equ _UC_UCSRA_VAL = 0
.equ _UC_UCSRB_VAL = (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0)
.equ _UC_UCSRC_VAL = (2 << UMSEL0) | (3 << UCSZ00)
.equ _UC_UDRE_VAL = (1 << UDRIE0)
.equ _UC_UBRR = FOSC / 16 / _UC_BAUDRATE - 1

.equ UC_TREADY_INTaddr = UDRE0addr
.equ UC_RCOMPLETE_INTaddr = URXC0addr

; [SOURCE] setup
; @0 (dirty immediate register)
.macro UC_SRC_SETUP
	; set UBRRR
	ldi @0, HIGH( _UC_UBRR )
	sts UBRR0H, @0
	ldi @0, LOW( _UC_UBRR )
	sts UBRR0L, @0
	; set UCSRA
	ldi @0, _UC_UCSRA_VAL
	sts UCSR0A, @0
	; set UCSRB
	ldi @0, _UC_UCSRB_VAL
	sts UCSR0B, @0
	; set UCSRC
	ldi @0, _UC_UCSRC_VAL
	sts UCSR0C, @0
.endmacro

; [SOURCE] transmit '@0' data without checking whether the buffer is empty
; @0 (data register)
.macro UC_SRC_FT
	sts UDR0, @0
.endmacro

; [SOURCE] receive to '@0' register without checking whether the buffer is not empty
; @0 (data register)
.macro UC_SRC_FR
	lds @0, UDR0
.endmacro

; [SOURCE] enable / disable transmit ready interrupt
; @0 (boolean interrupt state)
; @1 (dirty immediate register)
.macro UC_SRC_TREADY_INTE
	ldi @1, @0 ? ( _UC_UCSRB_VAL | _UC_UDRE_VAL ) : _UC_UCSRB_VAL
	sts UCSR0B, @1
.endmacro