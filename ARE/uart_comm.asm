#ifdef _INC_UC
#error __FILE__ already included
#else
#define _INC_UC

; Francesco Zoccheddu
; ARE
; UART communication
; dirty USART0 module and registers

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
