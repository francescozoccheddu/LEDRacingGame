#define _BZ_PWM_TIMER 0
#define _BZ_SQ_TIMER 1
#define _BZ_IO G

IO_DEF _BZ, _BZ_IO
TIM_DEF _BZ_PWM, _BZ_PWM_TIMER
TIM_DEF _BZ_SQ, _BZ_SQ_TIMER

#define BZ_TICKS 10

.dseg
_bz_ram_tick: .byte 1
_bz_ram_ticks: .byte 2*2*BZ_TICKS
.cseg

#define _BZ_WGM 2
#define _BZ_COMA 0
#define _BZ_COMB 1

#define _bz_setup_tmp @0

.macro BZ_SRC_SETUP
	; set data direction register to output
	ldi _bz_setup_tmp, 1 << 5
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

.macro _BZ_SRC_PWM
	out _BZ_PWM_OCRA, bz_top
	ori bz_cs, WGMB_VAL(_BZ_WGM)
	out _BZ_PWM_TCCRB, bz_cs
.endmacro

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

_bz_isr_start:
	ldi XH, HIGH( _bz_ram_ticks )
	ldi XL, LOW( _bz_ram_ticks )
	ldi bz_tmp2, 2*2*BZ_TICKS
_bz_isr_start_copy_loop:
	ld bz_tmp1, Z+
	st X+, bz_tmp1
	dec bz_tmp2
	brne _bz_isr_start_copy_loop
	sts _bz_ram_tick, bz_tmp2
ISR _BZ_SQ_OCAaddr
	; set PWM
	; set SQ
	; increment tick
	reti

