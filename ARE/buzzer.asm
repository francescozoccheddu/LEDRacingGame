#ifndef _INC_BZ
#define _INC_BZ

; Francesco Zoccheddu
; ARE
; buzzer
; dirty IO G, timer 0, timer 1

#include "utils.asm"
#include "serial_prog.asm"

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

#define _bz_r_start_ram @0

.macro BZ_SRC_START
	cli
	ldi ZH, HIGH( _bz_r_start_ram )
	ldi ZL, LOW( _bz_r_start_ram )
	rcall _bz_isr_start
.endmacro

#undef _bz_r_start_ram

#define _bz_load_ee @0
#define _bz_load_ram @1
#define _bz_r_load_tmp @2

.macro BZ_SRC_LOAD
	ldi _bz_r_load_tmp, BZ_TICKS
	ldi YL, LOW( _bz_load_ee )
	ldi YH, HIGH( _bz_load_ee )
	ldi XL, LOW( _bz_load_ram )
	ldi XH, HIGH( _bz_load_ram )
_bz_load_loop:
	SP_SRC_LOAD_TIME
	adiw YH:YL, 1
	st X+, sp_data
	st X+, sp_data_th
	SP_SRC_LOAD_TIME
	adiw YH:YL, 1
	st X+, sp_data
	st X+, sp_data_th
	st X+, sp_data_tl
	dec _bz_r_load_tmp
	brne _bz_load_loop
.endmacro

#undef _bz_load_ee
#undef _bz_load_ram
#undef _bz_r_load_tmp

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

#endif
