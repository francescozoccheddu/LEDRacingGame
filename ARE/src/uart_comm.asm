#ifdef MACROS
;################# MACROS #################

	.def uc_int = r24
	.def uc_char = r25

	.set UC_MACROS_ENABLED = 1

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

	;params (0)'immediate char'
	.macro UC_SR_CI
	.if UC_MACROS_ENABLED
		push uc_char
		ldi uc_char, @0
		call uc_sr_send
		pop uc_char
	.endif
	.endmacro

	;params (0)'char register'
	.macro UC_SR_C
	.if UC_MACROS_ENABLED
		push uc_char
		mov uc_char, @0
		call uc_sr_send
		pop uc_char
	.endif
	.endmacro

	.macro UC_SR_L
	.if UC_MACROS_ENABLED
		UC_SR_CI '\n'
	.endif
	.endmacro

	;params (0)'int register'
	.macro UC_SR_I
	.if UC_MACROS_ENABLED
		push uc_int
		mov uc_int, @0
		call uc_sr_send_int
		pop uc_int
	.endif
	.endmacro

	;params (0)'immediate int'
	.macro UC_SR_II
	.if UC_MACROS_ENABLED
		push uc_int
		ldi uc_int, @0
		call uc_sr_send_int
		pop uc_int
	.endif
	.endmacro

	;params (0)'str label'
	.macro UC_SR_STR
	.if UC_MACROS_ENABLED
		push ZH
		push ZL
		ldi ZH, HIGH(2 * @0)
		ldi ZL, LOW(2 * @0)
		call uc_sr_send_str
		pop ZL
		pop ZH
	.endif
	.endmacro

	;params (0)'unique id' (1)'immediate str'
	.macro UC_SR_STRI_N
	.if UC_MACROS_ENABLED
		rjmp UC_L_STRI_CODE@0
		.set UC_L_STRI_STR@0 = PC
		.db @1, 0
		.set UC_L_STRI_CODE@0 = PC
		UC_SR_STR UC_L_STRI_STR@0
	.endif
	.endmacro

;params (0)'immediate str'
#define UC_SR_STRI UC_SR_STRI_N __LINE__ ,

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


#ifdef CODE
;################## CODE ##################

;params (char)'char to send'
uc_sr_send:
	push uc_char
uc_l_send_loop:
	lds uc_char, UC_UCSRA
	sbrs uc_char, UC_UDRE
	rjmp uc_l_send_loop
	pop uc_char
	sts UC_UDR, uc_char
	ret

;params (Z)'address of the first character of a null-terminated string'
uc_sr_send_str:
	push uc_char
uc_l_send_str_loop:
	lpm uc_char, Z+
	cpi uc_char, 0
	breq uc_l_send_str_return
	rcall uc_sr_send
	rjmp uc_l_send_str_loop
uc_l_send_str_return:
	pop uc_char
	ret

;params (int)'int to send'
uc_sr_send_int:
	push uc_int
	push math_dvd_res
	push math_dvr_rem
	push uc_char
	mov math_dvd_res, uc_int
	ldi math_dvr_rem, 100
	rcall math_sr_div8
	mov uc_int, math_dvd_res
	cpi math_dvd_res, 0
	breq uc_l_send_int_nd
	mov uc_char, math_dvd_res
	subi uc_char, -'0'
	rcall uc_sr_send
uc_l_send_int_nd:
	mov math_dvd_res, math_dvr_rem
	ldi math_dvr_rem, 10
	rcall math_sr_div8
	cpi math_dvd_res, 0
	brne uc_l_send_int_nd_f
	cpi uc_int, 0
	breq uc_l_send_int_rd
uc_l_send_int_nd_f:
	mov uc_char, math_dvd_res
	subi uc_char, -'0'
	rcall uc_sr_send
uc_l_send_int_rd:
	mov uc_char, math_dvr_rem
	subi uc_char, -'0'
	rcall uc_sr_send
	pop uc_char
	pop math_dvr_rem
	pop math_dvd_res
	pop uc_int
	ret

;##########################################
#endif
