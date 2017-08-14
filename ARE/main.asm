#ifdef CODE

l_reset:
	SEI

l_loop:	
	UC_SR_C ds_out_l
	UC_SR_C ds_out_r
	rjmp l_loop

#endif
