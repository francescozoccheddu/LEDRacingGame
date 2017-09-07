#ifdef CODE
;################## CODE ##################
	
l_reset:
	sei

l_loop:	
	ldi ZH, HIGH(lm_sr_setcol)
	ldi ZL, LOW(lm_sr_setcol)
	LM_SR_DRAW main
	rjmp l_loop

lm_sr_setcol:
	lds r16, DS_R_OUT_L
	cp lm_col, r16
	brne rere
	ser lm_cl
	ser lm_ch
	rere:
	ret

;##########################################
#endif
