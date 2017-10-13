#define _BZ_PWM_TIMER 0
#define _BZ_SQ_TIMER 1
#define _BZ_IO G

IO_DEF _BZ, _BZ_IO
TIM_DEF _BZ_PWM, _BZ_PWM_TIMER
TIM_DEF _BZ_SQ, _BZ_SQ_TIMER

#define BZ_TICKS 10
#define BZ_SND_BYTES BZ_TICKS*5
#define _BZ_IO_BIT 5

.dseg
_bz_ram_ticks: .byte 2
.cseg

#define _BZ_WGM 2
#define _BZ_COMA 0
#define _BZ_COMB 1

#define _bz_setup_tmp @0

.macro BZ_SRC_SETUP
	; set data direction register to output
	clr _bz_setup_tmp
	out _BZ_DDR, _bz_setup_tmp
	; setup PWM timer 
	ldi _bz_setup_tmp, WGMA_VAL(2) | COMB_VAL(1)
	out _BZ_PWM_TCCRA, _bz_setup_tmp
	clr _bz_setup_tmp
	out _BZ_PWM_TCCRB, _bz_setup_tmp
	; setup SQ timer
	clr _bz_setup_tmp
	sts _BZ_SQ_TCCRA, _bz_setup_tmp
	sts _BZ_SQ_TCCRB, _bz_setup_tmp
	sts _BZ_SQ_TCCRC, _bz_setup_tmp
	; set timer interrupt mask
	ldi _bz_setup_tmp, OCIEA_VAL
	sts _BZ_SQ_TIMSK, _bz_setup_tmp
.endmacro

#undef _bz_setup_tmp

#define bz_cs @0
#define bz_top @1

#undef bz_cs
#undef bz_top

#define _bz_start_ram @0

.macro BZ_SRC_START
	cli
	ldi ZH, HIGH( _bz_start_ram )
	ldi ZL, LOW( _bz_start_ram )
	call _bz_isr_start
.endmacro

#undef _bz_start_ram

#define _bz_r_load_tmp1 rma
#define _bz_r_load_tmp2 rmb
#define _bz_r_load_tmp3 rmc
#define _bz_r_load_tmp4 r0
#define _bz_r_load_tmp5 r1
#define _bz_load_ee @0

.macro BZ_SRC_LOAD
	ldi _bz_r_load_tmp1, BZ_TICKS
	mov _bz_r_load_tmp5, _bz_r_load_tmp1
	ldi sp_addrl, LOW( _bz_load_ee )
	ldi sp_addrh, HIGH( _bz_load_ee )
	clr _bz_r_load_tmp4
_bz_load_loop:
	rcall sp_sr_load
	inc sp_addrl
	adc sp_addrh, _bz_r_load_tmp4
	mov _bz_r_load_tmp1, sp_data
	rcall sp_sr_load
	inc sp_addrl
	adc sp_addrh, _bz_r_load_tmp4
	mov _bz_r_load_tmp2, sp_data

	cp _bz_r_load_tmp1, _bz_r_load_tmp4
	cpc _bz_r_load_tmp2, _bz_r_load_tmp4
	brne _bz_load_calc_pwm
	clr _bz_r_load_tmp3
	clr _bz_r_load_tmp2
	rjmp _bz_load_store_pwm
_bz_load_calc_pwm:
	rcall t_sr_calc
_bz_load_store_pwm:
	st X+, _bz_r_load_tmp3
	st X+, _bz_r_load_tmp2

	rcall sp_sr_load
	inc sp_addrl
	adc sp_addrh, _bz_r_load_tmp4
	mov _bz_r_load_tmp1, sp_data
	rcall sp_sr_load
	inc sp_addrl
	adc sp_addrh, _bz_r_load_tmp4
	mov _bz_r_load_tmp2, sp_data

	cp _bz_r_load_tmp1, _bz_r_load_tmp4
	cpc _bz_r_load_tmp2, _bz_r_load_tmp4
	brne _bz_load_calc_sq
	clr _bz_r_load_tmp3
	clr _bz_r_load_tmp2
	clr _bz_r_load_tmp1
	rjmp _bz_load_store_sq
_bz_load_calc_sq:
	rcall t_sr_calc
_bz_load_store_sq:
	st X+, _bz_r_load_tmp3
	st X+, _bz_r_load_tmp2
	st X+, _bz_r_load_tmp1

	dec _bz_r_load_tmp5
	brne _bz_load_loop
.endmacro

#undef _bz_r_load_tmp1
#undef _bz_r_load_tmp2
#undef _bz_r_load_tmp3
#undef _bz_r_load_tmp4
#undef _bz_r_load_tmp5
#undef _bz_load_ee

#define _bz_r_sqocia_tmp ria

ISR _BZ_SQ_OCAaddr
	; increment tick and set Z pointer
	lds ZL, _bz_ram_ticks
	lds ZH, _bz_ram_ticks + 1
_bz_isr_start:
	; set PWM
	ld _bz_r_sqocia_tmp, Z+
	out _BZ_PWM_TCCRB, _bz_r_sqocia_tmp
	tst _bz_r_sqocia_tmp
	breq _bz_isr_start_mute
	ldi _bz_r_sqocia_tmp, 1 << _BZ_IO_BIT
_bz_isr_start_mute:
	out _BZ_DDR, _bz_r_sqocia_tmp
	ld _bz_r_sqocia_tmp, Z+
	out _BZ_PWM_OCRA, _bz_r_sqocia_tmp
	; set SQ
	clr _bz_r_sqocia_tmp
	sts _BZ_SQ_TCCRB, _bz_r_sqocia_tmp
	sts _BZ_SQ_TCNTH, _bz_r_sqocia_tmp
	sts _BZ_SQ_TCNTL, _bz_r_sqocia_tmp
	ld _bz_r_sqocia_tmp, Z+
	sts _BZ_SQ_TCCRB, _bz_r_sqocia_tmp
	ld _bz_r_sqocia_tmp, Z+
	sts _BZ_SQ_OCRAH, _bz_r_sqocia_tmp
	ld _bz_r_sqocia_tmp, Z+
	sts _BZ_SQ_OCRAL, _bz_r_sqocia_tmp
	; store pointer
	sts _bz_ram_ticks, ZL
	sts _bz_ram_ticks + 1, ZH
	reti

#undef _bz_r_sqocia_tmp
