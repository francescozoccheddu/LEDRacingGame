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

.def lm_rowcnt = r21
.def lm_outprt = r22

;params (0)'column register' (1)'data high' (2)'data low' 
.macro LM_SR_DRAW_COL
	ldi lm_rowcnt, 16
	;row
	ldi lm_outprt, (1 << LM_BIT_G) | (1 << LM_BIT_DI)
	lsr @1
	ror @2
	brcc PC + 2
	ldi lm_outprt, (1 << LM_BIT_G)
	out LM_PORT, lm_outprt
	ori lm_outprt, 1 << LM_BIT_CLK
	out LM_PORT, lm_outprt
	andi lm_outprt, ~(1 << LM_BIT_CLK)
	out LM_PORT, lm_outprt
	;loop
	dec lm_rowcnt
	brne PC - 11
	;send LAT
	ldi lm_outprt, (1 << LM_BIT_G) | (1 << LM_BIT_LAT)
	out LM_PORT, lm_outprt
	ldi lm_outprt, (1 << LM_BIT_G)
	out LM_PORT, lm_outprt
	;send col
	or lm_outprt, @0
	out LM_PORT, lm_outprt
	;end G
	out LM_PORT, @0
.endmacro

;##########################################
#endif
