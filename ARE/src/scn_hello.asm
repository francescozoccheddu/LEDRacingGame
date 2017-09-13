#ifdef SETUP
;################## SETUP #################

	ldi ZH, HIGH( sh_sr_draw )
	ldi ZL, LOW( sh_sr_draw )

;##########################################
#endif

#ifdef CODE
;################## CODE ##################

sh_sr_draw:
	cpi m_col, 6
	breq sh_l_draw_dot
	cpi m_col, 9
	brne sh_l_draw_ret
sh_l_draw_dot:
	ldi m_ch, (1 << 0) | (1 << 1) 
	ldi m_cl, (1 << 6) | (1 << 7) 
sh_l_draw_ret:
	ret 

;##########################################
#endif

