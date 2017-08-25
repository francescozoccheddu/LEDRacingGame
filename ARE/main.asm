#ifdef CODE
;################## CODE ##################
	
l_reset:
	sei
	cli
	BZ_SR_SQ_SET_TONE 0, 7, 30 / 1000.0, 40
	BZ_SR_SQ_SET_MUTE 1, 7, 30 / 1000.0
	BZ_SR_SQ_SET_TONE 2, 7, 30 / 1000.0, 50
	BZ_SR_SQ_SET_MUTE 3, 7, 30 / 1000.0
	BZ_SR_SQ_SET_TONE 4, 7, 30 / 1000.0, 60
	BZ_SR_SQ_SET_MUTE 5, 7, 30 / 1000.0
	BZ_SR_SQ_SET_TONE 6, 7, 30 / 1000.0, 100
	BZ_SR_SQ_START 7

l_loop:	
	rjmp l_loop

;##########################################
#endif
