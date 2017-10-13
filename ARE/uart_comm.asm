#ifdef _INC_UC
#error __FILE__ already included
#else
#define _INC_UC

; Francesco Zoccheddu
; ARE
; UART communication
; dirty USART0 module and registers

#define _UC_BAUDRATE 9600

#define _UC_UCSRA_VAL 0
#define _UC_UCSRB_VAL (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0)
#define _UC_UCSRC_VAL (2 << UMSEL0) | (3 << UCSZ00)
#define _UC_UDRE_VAL (1 << UDRIE0)
#define _UC_UBRR FOSC / 16 / _UC_BAUDRATE - 1

#define UC_TREADY_INTaddr UDRE0addr
#define UC_RCOMPLETE_INTaddr URXC0addr

#define _uc_tmp @0

; [SOURCE] setup
; @0 (dirty immediate register)
.macro UC_SRC_SETUP
	; set UBRRR
	ldi _uc_tmp, HIGH( _UC_UBRR )
	sts UBRR0H, _uc_tmp
	ldi _uc_tmp, LOW( _UC_UBRR )
	sts UBRR0L, _uc_tmp
	; set UCSRA
	ldi _uc_tmp, _UC_UCSRA_VAL
	sts UCSR0A, _uc_tmp
	; set UCSRB
	ldi _uc_tmp, _UC_UCSRB_VAL
	sts UCSR0B, _uc_tmp
	; set UCSRC
	ldi _uc_tmp, _UC_UCSRC_VAL
	sts UCSR0C, _uc_tmp
.endmacro

#undef _uc_tmp

#define _uc_data @0
#define _uc_tmp @1

; [SOURCE] transmit '_uc_data' data without checking whether the buffer is empty
; @0 (data register)
.macro UC_SRC_FT
	sts UDR0, _uc_data
.endmacro

; [SOURCE] receive to '_uc_data' register without checking whether the buffer is not empty
; @0 (data register)
.macro UC_SRC_FR
	lds _uc_data, UDR0
.endmacro

; [SOURCE] transmit '_uc_data' data as soon as the buffery is empty
; @0 (data register)
; @1 (dirty immediate register)
.macro UC_SRC_T
_uc_l_src_t:
	lds _uc_tmp, UCSR0A
	sbrs _uc_tmp, UDRE0
	rjmp _uc_l_src_t
	UC_SRC_FT _uc_data
.endmacro

; [SOURCE] receive to '_uc_data' register as soon as the buffer is not empty
; @0 (data register)
.macro UC_SRC_R
_uc_l_src_r:
	lds _uc_data, UCSR0A
	sbrs _uc_data, RXC0
	rjmp _uc_l_src_r
	UC_SRC_FR _uc_data
.endmacro

; [SOURCE] enable / disable transmit ready interrupt
; @0 (boolean interrupt state)
; @1 (dirty immediate register)
.macro UC_SRC_TREADY_INTE
	ldi _uc_tmp, _uc_data ? ( _UC_UCSRB_VAL | _UC_UDRE_VAL ) : _UC_UCSRB_VAL
	sts UCSR0B, _uc_tmp
.endmacro

#undef _uc_data
#undef _uc_tmp

#endif
