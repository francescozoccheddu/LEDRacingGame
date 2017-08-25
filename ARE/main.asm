#ifdef CODE
;################## CODE ##################
	
l_reset:
	sei
	cli
	BZ_SR_ASQ_BEGIN 5
	BZ_SR_ASQ_PUSH 100, 40
	BZ_SR_ASQ_PUSH 200, 0
	BZ_SR_ASQ_PUSH 100, 40
	BZ_SR_ASQ_PUSH 100, 0
	BZ_SR_ASQ_PUSH 400, 30
	BZ_SR_ASQ_END

l_loop:	
	rjmp l_loop

;##########################################
#endif
