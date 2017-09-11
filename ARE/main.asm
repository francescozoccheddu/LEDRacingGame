#ifdef CODE
;################## CODE ##################
	
l_reset:
	sei
	ldi r16, 0

l_loop:	
	ldi r24, 1 << 3
	ldi r25, 1 << 1
	LM_SR_DRAW_COL r16, r24, r25

	ldi  r18, 3
    ldi  r19, 19
L1: dec  r19
    brne L1
    dec  r18
    brne L1

	inc r16
	cpi r16, 16
	brne l_loop
	rjmp l_reset


;##########################################
#endif
