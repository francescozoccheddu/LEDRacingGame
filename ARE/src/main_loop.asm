#ifdef INTV
;################## INTV ##################

.org OC2Aaddr
	rjmp m_isr_draw_unlock

;##########################################
#endif

#ifdef SETUP
;################## SETUP #################

	ldi m_cl, M_TIM_TOP
	sts M_TIM_OCR, m_cl
	ldi m_cl, M_TIM_TIMSK_BITS
	sts M_TIM_TIMSK, m_cl
	sei

;##########################################
#endif

#ifdef CODE
;################## CODE ##################

	.def m_col = r16
	.def m_cl = r17
	.def m_ch = r18

	.equ M_TIM_DELAY_US = 5000
	TU_M_PSCL M_TIM_DELAY_US / 1000000.0, 8, M_TIM_PSCL
	TU_M_CS M_TIM_PSCL, M_TIM_CS
	TU_M_TOP_EQU M_TIM_PSCL, M_TIM_DELAY_US / 1000000.0, M_TIM_TOP

	.equ M_TIM_TCCRB = TCCR2B
	.equ M_TIM_TCNT = TCNT2
	.equ M_TIM_OCR = OCR2A
	.equ M_TIM_TIMSK = TIMSK2
	.equ M_TIM_TIMSK_BITS = 1 << OCIE2A
	
entry_l_reset:
m_l_draw_start:
	sei
	clr m_col

m_l_draw_loop:
	sei
	icall
	cli
	LM_SR_DRAW_COL m_col, m_ch, m_cl
	sts M_TIM_TCNT, m_cl
	ldi m_cl, M_TIM_CS
	sts M_TIM_TCCRB, m_cl
	sei
m_l_draw_lock:
	cpi m_cl, 0
	brne m_l_draw_lock

	inc m_col
	cpi m_col, 16
	brne m_l_draw_loop
	rjmp m_l_draw_start

m_isr_draw_unlock:
	clr m_cl
	sts M_TIM_TCCRB, m_cl
	ret

;##########################################
#endif
