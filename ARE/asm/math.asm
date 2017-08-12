;reserved
.def math_dvd_res = r22
.def math_dvr_rem = r23

;8/8 bit division subroutine
;overrides 'math_dvd_res', 'math_dvr_rem'
;'math_dvd_res' must be the dividend
;'math_dvr_rem' must be the divider
;'math_dvd_res' will be the quotient
;'math_dvr_rem' will be the remainder
math_sr_div8:
	push r16
	clr	r16
	rol	math_dvd_res
	rol	r16
	sub	r16, math_dvr_rem
	brcc math_l_div8_1
	add	r16, math_dvr_rem
	clc
	rjmp math_l_div8_2
math_l_div8_1:	
	sec
math_l_div8_2:	
	rol	math_dvd_res
	rol	r16
	sub	r16, math_dvr_rem
	brcc math_l_div8_3
	add	r16, math_dvr_rem
	clc
	rjmp math_l_div8_4
math_l_div8_3:	
	sec
math_l_div8_4:	
	rol	math_dvd_res
	rol	r16
	sub	r16, math_dvr_rem
	brcc math_l_div8_5
	add	r16, math_dvr_rem
	clc
	rjmp math_l_div8_6
math_l_div8_5:	
	sec
math_l_div8_6:	
	rol	math_dvd_res
	rol	r16
	sub	r16, math_dvr_rem
	brcc math_l_div8_7
	add	r16, math_dvr_rem
	clc
	rjmp math_l_div8_8
math_l_div8_7:	
	sec
math_l_div8_8:	
	rol	math_dvd_res
	rol	r16
	sub	r16, math_dvr_rem
	brcc math_l_div8_9
	add	r16, math_dvr_rem
	clc
	rjmp math_l_div8_10
math_l_div8_9:	
	sec
math_l_div8_10:	
	rol	math_dvd_res
	rol	r16
	sub	r16, math_dvr_rem
	brcc math_l_div8_11
	add	r16, math_dvr_rem
	clc
	rjmp math_l_div8_12
math_l_div8_11:	
	sec
math_l_div8_12:	
	rol	math_dvd_res
	rol	r16
	sub	r16, math_dvr_rem
	brcc math_l_div8_13
	add	r16, math_dvr_rem
	clc
	rjmp math_l_div8_14
math_l_div8_13:	
	sec
math_l_div8_14:	
	rol	math_dvd_res
	rol	r16
	sub	r16, math_dvr_rem
	brcc math_l_div8_15
	add	r16, math_dvr_rem
	clc
	rjmp math_l_div8_16
math_l_div8_15: 
	sec
math_l_div8_16:	
	rol	math_dvd_res
	mov math_dvr_rem, r16
	pop r16
	ret