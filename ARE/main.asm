#ifdef CODE
;################## CODE ##################

l_reset:
	SEI

l_loop:	
	UC_SR_I 'i'
	UC_SR ds_out_l
	UC_SR_I 'b'
	UC_SR ds_out_r
	rjmp l_loop

;##########################################
#endif
