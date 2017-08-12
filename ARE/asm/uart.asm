;reserved
.def uart_int = r24
.def uart_char = r25

.set UART_MACROS_ENABLED = 1

.include "asm/math.asm"

.equ UART_BAUD_RATE = 9600
.equ UART_UBRR = (FOSC / 16 / UART_BAUD_RATE - 1)

.equ UART_UBRRH = UBRR0H
.equ UART_UBRRL = UBRR0L
.equ UART_UCSRA = UCSR0A
.equ UART_UCSRB = UCSR0B
.equ UART_UCSRC = UCSR0C
.equ UART_UMSEL = UMSEL0
.equ UART_UDRE = UDRE0
.equ UART_TXEN = TXEN0
.equ UART_UDR = UDR0
.equ UART_UCSZ = UCSZ00

;setup macro
.macro UART_SR_SETUP
	push r16
	ldi r16, LOW(UART_UBRR)
	sts UART_UBRRL, r16
	ldi r16, HIGH(UART_UBRR)
	sts UART_UBRRH, r16
	clr r16
	sts UART_UCSRA, r16
	ldi r16, (1 << UART_TXEN)
	sts UART_UCSRB, r16
	ldi r16, (2 << UART_UMSEL) | (3 << UART_UCSZ)
	sts UART_UCSRC, r16
	pop r16
.endmacro

;fast print subroutine
;params (0)'immediate char'
.macro UART_SR_CI
.if UART_MACROS_ENABLED
	push uart_char
	ldi uart_char, @0
	call uart_sr_send
	pop uart_char
.endif
.endmacro

;fast print subroutine
.macro UART_SR_L
.if UART_MACROS_ENABLED
	UART_SR_CI '\n'
.endif
.endmacro

;fast print subroutine
;params (0)'int register'
.macro UART_SR_I
.if UART_MACROS_ENABLED
	push uart_int
	mov uart_int, @0
	call uart_sr_send_int
	pop uart_int
.endif
.endmacro

;fast print subroutine
;params (0)'immediate int'
.macro UART_SR_II
.if UART_MACROS_ENABLED
	push uart_int
	ldi uart_int, @0
	call uart_sr_send_int
	pop uart_int
.endif
.endmacro

;fast print subroutine
;params (0)'str label'
.macro UART_SR_STR
.if UART_MACROS_ENABLED
	push ZH
	push ZL
	ldi ZH, HIGH(2 * @0)
	ldi ZL, LOW(2 * @0)
	call uart_sr_send_str
	pop ZL
	pop ZH
.endif
.endmacro

;fast print subroutine
;params (0)'unique id' (1)'immediate str'
.macro UART_SR_STRI_N
.if UART_MACROS_ENABLED
	rjmp UART_L_STRI_CODE@0
	.set UART_L_STRI_STR@0 = PC
	.db @1, 0
	.set UART_L_STRI_CODE@0 = PC
	UART_SR_STR UART_L_STRI_STR@0
.endif
.endmacro

;fast print subroutine
;params (0)'immediate str'
#define UART_SR_STRI UART_SR_STRI_N __LINE__ ,

;send char subroutine
;'uart_char' must be the character to send
uart_sr_send:
	push uart_char
uart_l_send_loop:
	lds uart_char, UART_UCSRA
	sbrs uart_char, UART_UDRE
	rjmp uart_l_send_loop
	pop uart_char
	sts UART_UDR, uart_char
	ret

;send string subroutine
;overrides 'Z'
;'Z' must be the address of the first character of the zero-terminated string
uart_sr_send_str:
	push uart_char
uart_l_send_str_loop:
	lpm uart_char, Z+
	cpi uart_char, 0
	breq uart_l_send_str_return
	rcall uart_sr_send
	rjmp uart_l_send_str_loop
uart_l_send_str_return:
	pop uart_char
	ret

;send int subroutine
;'uart_int' must be the integer to send
uart_sr_send_int:
	push uart_int
	push math_dvd_res
	push math_dvr_rem
	push uart_char
	mov math_dvd_res, uart_int
	ldi math_dvr_rem, 100
	rcall math_sr_div8
	mov uart_int, math_dvd_res
	cpi math_dvd_res, 0
	breq uart_l_send_int_nd
	mov uart_char, math_dvd_res
	subi uart_char, -'0'
	rcall uart_sr_send
uart_l_send_int_nd:
	mov math_dvd_res, math_dvr_rem
	ldi math_dvr_rem, 10
	rcall math_sr_div8
	cpi math_dvd_res, 0
	brne uart_l_send_int_nd_f
	cpi uart_int, 0
	breq uart_l_send_int_rd
uart_l_send_int_nd_f:
	mov uart_char, math_dvd_res
	subi uart_char, -'0'
	rcall uart_sr_send
uart_l_send_int_rd:
	mov uart_char, math_dvr_rem
	subi uart_char, -'0'
	rcall uart_sr_send
	pop uart_char
	pop math_dvr_rem
	pop math_dvd_res
	pop uart_int
	ret
