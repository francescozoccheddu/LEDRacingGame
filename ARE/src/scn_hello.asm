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
	clr m_ch
	lds m_ch, DS_R_OUT_L
	cp m_col, m_ch
	brne sh_l_draw_ret
	ldi m_ch, (1 << 0) | (1 << 1) 
	ldi m_cl, (1 << 6) | (1 << 7)
	ret
sh_l_draw_ret:
	clr m_ch
	ret 

;##########################################
#endif

