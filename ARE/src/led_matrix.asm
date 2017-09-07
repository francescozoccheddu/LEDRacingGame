#ifdef SETUP
;################## SETUP #################

	push r16
	ser r16
	out LM_PORTD, r16
	pop r16

;##########################################
#endif

#ifdef CODE
;################## CODE ##################

.equ LM_PORT = PORTC
.equ LM_PORTD = DDRC
.equ LM_BIT_ABCD = 0 ;digital pin 34-37
.equ LM_BIT_G = 4 ;digital pin 33
.equ LM_BIT_DI = 5 ;digital pin 32
.equ LM_BIT_CLK = 6 ;digital pin 31
.equ LM_BIT_LAT = 7 ;digital pin 30

.def lm_row = r21
.def lm_col = r22
.def lm_out = r23
.def lm_cl = r24
.def lm_ch = r25

;params (0)'branch label'
.macro LM_SR_DRAW
	;column loop
	ldi lm_col, 0
lm_lm_sr_draw_col_@0:
	;column
	;column callback
	icall
	;row loop
	ldi lm_row, 16
lm_lm_sr_draw_row_@0:
	;row
	ldi lm_out, (1 << LM_BIT_G) | (1 << LM_BIT_DI)
	lsr lm_ch
	ror lm_cl
	brcc lm_lm_sr_draw_dot_@0
	ldi lm_out, (1 << LM_BIT_G)
lm_lm_sr_draw_dot_@0:
	out LM_PORT, lm_out
	ori lm_out, 1 << LM_BIT_CLK
	out LM_PORT, lm_out
	andi lm_out, ~(1 << LM_BIT_CLK)
	out LM_PORT, lm_out
	;loop
	dec lm_row
	brne lm_lm_sr_draw_row_@0
	;send LAT
	ldi lm_out, (1 << LM_BIT_G) | (1 << LM_BIT_LAT)
	out LM_PORT, lm_out
	ldi lm_out, (1 << LM_BIT_G)
	out LM_PORT, lm_out
	;send col
	or lm_out, lm_col
	out LM_PORT, lm_out
	;end G
	out LM_PORT, lm_col
	;wait
	ldi  lm_row, 255
    dec  lm_row
    brne PC - 1
	;loop
	inc lm_col
	cpi lm_col, 16
	brne lm_lm_sr_draw_col_@0
.endmacro

;##########################################
#endif
