#ifdef SETUP
;################## SETUP #################

	ldi ZH, HIGH( sh_sr_draw )
	ldi ZL, LOW( sh_sr_draw)

;##########################################
#endif

#ifdef CODE
;################## CODE ##################

sh_sr_draw:
	clr m_cl
	lds m_ch, DS_R_OUT_L
	cp m_col, m_ch
	brne PC + 2
	ser m_cl
	clr m_ch
	ret 

;##########################################
#endif

