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
.equ UC_UCSRB_VAL = (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0)
.equ UC_UDRE_VAL = (1 << UDRIE0)
.equ UC_UCSRC = UCSR0C
.equ UC_UCSRC_VAL = (2 << UMSEL0) | (3 << UCSZ00)

.equ UC_UDREaddr = UDRE0addr
.equ UC_UTXCaddr = UTXC0addr
.equ UC_URXCaddr = URXC0addr

.equ UC_TREADY_INTaddr = UC_UDREaddr
.equ UC_RCOMPLETE_INTaddr = UC_URXCaddr

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

; [SOURCE] transmit '@0' data without checking whether the buffer is empty
; @0 (data register)
.macro UC_SRC_FT
	sts UC_UDR, @0
.endmacro

; [SOURCE] receive to '@0' register without checking whether the buffer is not empty
; @0 (data register)
.macro UC_SRC_FR
	lds @0, UC_UDR
.endmacro

; [SOURCE] enable / disable transmit ready interrupt
; @0 (boolean interrupt state)
; @1 (dirty immediate register)
.macro UC_SRC_TREADY_INTE
	ldi @1, @0 ? ( UC_UCSRB_VAL | UC_UDRE_VAL ) : UC_UCSRB_VAL
	sts UC_UCSRB, @1
.endmacro