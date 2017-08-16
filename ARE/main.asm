#ifdef CODE
;################## CODE ##################

l_reset:
	SEI

l_loop:	
	UC_SR_R DS_R_OUT_L
	UC_SR_R DS_R_OUT_R
	rjmp l_loop

;##########################################
#endif
