#ifdef CODE
;################## CODE ##################
	
l_reset:
	sei
	ldi r16, 0

l_loop:	

	cli
	lds r17, DS_R_OUT_L
	cp r16, r17
	brne lol
	mov r24, r16
	ser r25
	rjmp go
lol:
	clr r24
	clr r25
go:
	LM_SR_DRAW_COL r16, r24, r25
	
    ldi  r18, 11
    ldi  r19, 99
L1: dec  r19
    brne L1
    dec  r18
    brne L1

	inc r16
	cpi r16, 16
	sei
	brne l_loop
	rjmp l_reset


;##########################################
#endif
