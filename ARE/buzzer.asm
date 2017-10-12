#define _BZ_PWM_TIMER 0
#define _BZ_SQ_TIMER 1
#define _BZ_IO G

IO_DEF _BZ, _BZ_IO
TIM_DEF _BZ_PWM, _BZ_PWM_TIMER
TIM_DEF _BZ_SQ, _BZ_SQ_TIMER

#define BZ_TICKS 10
#define BZ_TICKS_BYTES BZ_TICKS*5
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

#define _bz_start_ticks @0

.macro BZ_SRC_START
	cli
	ldi ZH, HIGH( _bz_start_ticks )
	ldi ZL, LOW( _bz_start_ticks )
	call _bz_isr_start
.endmacro

#undef _bz_start_ticks

#define bz_tmp1 rma
#define bz_tmp2 rmb

#define _bz_ee @0

.macro BZ_SRC_LOAD
	ldi sp_addrl, LOW( _bz_ee )
	ldi sp_addrh, HIGH( _bz_ee )
	clr r0
	ldi ria, BZ_TICKS
	mov r1, ria
_bz_load_loop:
	rcall sp_sr_load
	inc sp_addrl
	adc sp_addrh, r0
	mov rma, sp_data
	rcall sp_sr_load
	inc sp_addrl
	adc sp_addrh, r0
	mov rmb, sp_data

	cp rma, r0
	cpc rmb, r0
	brne _bz_load_calc_pwm
	clr rmc
	clr rmb
	rjmp _bz_load_store_pwm
_bz_load_calc_pwm:
	rcall t_sr_calc
_bz_load_store_pwm:
	st X+, rmc
	st X+, rmb

	rcall sp_sr_load
	inc sp_addrl
	adc sp_addrh, r0
	mov rma, sp_data
	rcall sp_sr_load
	inc sp_addrl
	adc sp_addrh, r0
	mov rmb, sp_data

	cp rma, r0
	cpc rmb, r0
	brne _bz_load_calc_sq
	clr rmc
	clr rmb
	clr rma
	rjmp _bz_load_store_sq
_bz_load_calc_sq:
	rcall t_sr_calc
_bz_load_store_sq:
	st X+, rmc
	st X+, rmb
	st X+, rma

	dec r1
	brne _bz_load_loop
.endmacro

#undef _bz_ee

ISR _BZ_SQ_OCAaddr
	; increment tick and set Z pointer
	lds ZL, _bz_ram_ticks
	lds ZH, _bz_ram_ticks + 1
_bz_isr_start:
	; set PWM
	ld bz_tmp1, Z+
	out _BZ_PWM_TCCRB, bz_tmp1
	tst bz_tmp1
	breq _bz_isr_start_mute
	ldi bz_tmp1, 1 << _BZ_IO_BIT
_bz_isr_start_mute:
	out _BZ_DDR, bz_tmp1
	ld bz_tmp1, Z+
	out _BZ_PWM_OCRA, bz_tmp1
	; set SQ
	clr bz_tmp1
	sts _BZ_SQ_TCCRB, bz_tmp1
	sts _BZ_SQ_TCNTH, bz_tmp1
	sts _BZ_SQ_TCNTL, bz_tmp1
	ld bz_tmp1, Z+
	sts _BZ_SQ_TCCRB, bz_tmp1
	ld bz_tmp1, Z+
	sts _BZ_SQ_OCRAH, bz_tmp1
	ld bz_tmp1, Z+
	sts _BZ_SQ_OCRAL, bz_tmp1
	; store pointer
	sts _bz_ram_ticks, ZL
	sts _bz_ram_ticks + 1, ZH
	reti

