#ifndef _INC_DS
#define _INC_DS

#include "utils.asm"
#include "builtin_led.asm"
#include "serial_prog.asm"

; Francesco Zoccheddu
; ARE
; distance sensor
; dirty IO L, timer 4, builtin_led

#define _DS_TIMER 4
#define _DS_IO L

TIM_DEF _DS, _DS_TIMER
IO_DEF _DS, _DS_IO

#define _DS_ICP_BIT 0 ; digital pin 49
#define _DS_TRIG_BIT 6 ; digital pin 43

#define _ds_r_setup_tmp @0

; [SOURCE] setup
; @0 (dirty immediate register)
.macro DS_SRC_SETUP
	; clear timer control registers
	clr _ds_r_setup_tmp
	sts _DS_TCCRA, _ds_r_setup_tmp
	sts _DS_TCCRB, _ds_r_setup_tmp
	sts _DS_TCCRC, _ds_r_setup_tmp
	; set timer interrupt mask
	ldi _ds_r_setup_tmp, ICIE_VAL | OCIEA_VAL
	sts _DS_TIMSK, _ds_r_setup_tmp
	; set data direction register to output for trig pin
	ldi _ds_r_setup_tmp, 1 << _DS_TRIG_BIT
	sts _DS_DDR, _ds_r_setup_tmp
	; load ee
	SP_SRC_LOAD_TO_RAM ee_ds_min_ic, _ds_ram_min, 2
	SP_SRC_LOAD_TO_RAM ee_ds_max_ic, _ds_ram_max, 2
	SP_SRC_LOAD_TO_RAM ee_ds_emax_ic, _ds_ram_emax, 2
	SP_SRC_LOADI_TIME ee_ds_period_propf
	ori sp_data, ICN_VAL | ICES_VAL
	sts _DS_OCRAH, sp_data_th
	sts _DS_OCRAL, sp_data_tl
	sts _ds_ram_tccrb, sp_data
.endmacro

#undef _ds_r_setup_tmp

.eseg
; name="Distance sensor period"
; description="Time between each trig"
; type="real"
; size=2
; data={"fromh":40,"toh":499.968,"fromb":625,"tob":7812,"unit":"ms"}
ee_ds_period_propf: .dw int( 0.06 * T16_PROPF + 0.5)
; name="Distance sensor minimum echo"
; description="Minimum distance sensor echo pulse duration"
; type="real"
; size=2
; data={"fromh":0,"toh":100,"fromb":0,"tob":65535,"unit":"%"}
ee_ds_min_ic: .dw 70
; name="Distance sensor maximum echo"
; description="Minimum distance sensor echo pulse duration"
; type="real"
; size=2
; data={"fromh":0,"toh":100,"fromb":0,"tob":65535,"unit":"%"}
ee_ds_max_ic: .dw 250
; name="Distance sensor timeout echo"
; description="Minimum distance sensor echo pulse duration"
; type="real"
; size=2
; data={"fromh":0,"toh":100,"fromb":0,"tob":65535,"unit":"%"}
ee_ds_emax_ic: .dw 300
.cseg

.dseg
_ds_ram_tccrb: .byte 1
_ds_ram_min: .byte 2
_ds_ram_max: .byte 2
_ds_ram_emax: .byte 2
_ds_ram_ltime: .byte 2
ds_ram_out_val: .byte 1
ds_ram_out_state: .byte 1
.cseg

ISR _DS_OCAaddr
ds_isr_trig:

#define _ds_rr_trig_tmp ria

	; start trig
	ldi _ds_rr_trig_tmp, 1 << _DS_TRIG_BIT
	sts _DS_PORT, _ds_rr_trig_tmp
	; stop timer
	clr _ds_rr_trig_tmp
	sts _DS_TCCRB, _ds_rr_trig_tmp
	; clear counter
	sts _DS_TCNTH, _ds_rr_trig_tmp
	sts _DS_TCNTL, _ds_rr_trig_tmp
	; skip if not measured
	lds _ds_rr_trig_tmp, _DS_TIMSK
	sbrc _ds_rr_trig_tmp, ICIE
	rjmp _ds_isr_trig_bad

#undef _ds_rr_trig_tmp

#define _ds_rr_trig_cursl ria
#define _ds_rr_trig_cursh rib
#define _ds_rr_trig_inl ri0
#define _ds_rr_trig_inh ri1

	; skip if greater than max
	lds _ds_rr_trig_cursl, _ds_ram_emax
	lds _ds_rr_trig_cursh, _ds_ram_emax + 1
	lds _ds_rr_trig_inl, _ds_ram_ltime
	lds _ds_rr_trig_inh, _ds_ram_ltime + 1
	cp _ds_rr_trig_inl, _ds_rr_trig_cursl
	cpc _ds_rr_trig_inh, _ds_rr_trig_cursh
	brsh _ds_isr_trig_bad

#define _ds_rr_trig_in_lol ri2
#define _ds_rr_trig_in_loh ri3
#define _ds_rr_trig_in_hil ri4
#define _ds_rr_trig_in_hih ri5
#define _ds_rr_trig_out_lo ric
#define _ds_rr_trig_out_hi rid
#define _ds_rr_trig_out ri6

	; clamp
	; setup clamp parameters
	lds _ds_rr_trig_in_lol, _ds_ram_min
	lds _ds_rr_trig_in_loh, _ds_ram_min + 1
	lds _ds_rr_trig_in_hil, _ds_ram_max
	lds _ds_rr_trig_in_hih, _ds_ram_max + 1
	clr _ds_rr_trig_out_lo
	ser _ds_rr_trig_out_hi
	; start clamping
_ds_l_isr_trig_clamp_start:
	movw _ds_rr_trig_cursh:_ds_rr_trig_cursl, _ds_rr_trig_in_hih:_ds_rr_trig_in_hil
	mov _ds_rr_trig_out, _ds_rr_trig_out_hi
_ds_l_isr_trig_clamp_loop:
	sub _ds_rr_trig_out_hi, _ds_rr_trig_out_lo
	cpi _ds_rr_trig_out_hi, 2
	brlo _ds_l_isr_trig_clamp_stop
	add _ds_rr_trig_out_hi, _ds_rr_trig_out_lo
	cp _ds_rr_trig_cursl, _ds_rr_trig_inl
	cpc _ds_rr_trig_cursh, _ds_rr_trig_inh
	breq _ds_l_isr_trig_clamp_stop
	brsh _ds_l_isr_trig_clamp_smaller
_ds_l_isr_trig_clamp_greater:
	movw _ds_rr_trig_in_loh:_ds_rr_trig_in_lol, _ds_rr_trig_cursh:_ds_rr_trig_cursl
	mov _ds_rr_trig_out_lo, _ds_rr_trig_out
	add _ds_rr_trig_cursl, _ds_rr_trig_in_hil
	adc _ds_rr_trig_cursh, _ds_rr_trig_in_hih
	ror _ds_rr_trig_cursh
	ror _ds_rr_trig_cursl
	add _ds_rr_trig_out, _ds_rr_trig_out_hi
	ror _ds_rr_trig_out
	rjmp _ds_l_isr_trig_clamp_loop
_ds_l_isr_trig_clamp_smaller:
	movw _ds_rr_trig_in_hih:_ds_rr_trig_in_hil, _ds_rr_trig_cursh:_ds_rr_trig_cursl
	mov _ds_rr_trig_out_hi, _ds_rr_trig_out
	add _ds_rr_trig_cursl, _ds_rr_trig_in_lol
	adc _ds_rr_trig_cursh, _ds_rr_trig_in_loh
	ror _ds_rr_trig_cursh
	ror _ds_rr_trig_cursl
	add _ds_rr_trig_out, _ds_rr_trig_out_lo
	ror _ds_rr_trig_out
	rjmp _ds_l_isr_trig_clamp_loop

#undef _ds_rr_trig_cursl
#undef _ds_rr_trig_cursh
#undef _ds_rr_trig_inl
#undef _ds_rr_trig_inh
#undef _ds_rr_trig_in_lol
#undef _ds_rr_trig_in_loh
#undef _ds_rr_trig_in_hil
#undef _ds_rr_trig_in_hih
#undef _ds_rr_trig_out_lo
#undef _ds_rr_trig_out_hi

#define _ds_rr_trig_tmp1 ria
#define _ds_rr_trig_tmp2 rib

_ds_l_isr_trig_clamp_stop:
	; write output value
	lds _ds_rr_trig_tmp1, ds_ram_out_val
	add _ds_rr_trig_tmp1, _ds_rr_trig_out
	ror _ds_rr_trig_tmp1
	sts ds_ram_out_val, _ds_rr_trig_tmp1
	; set output state to true
	ser _ds_rr_trig_tmp1
	rjmp _ds_isr_trig_done

#undef _ds_rr_trig_out

_ds_isr_trig_bad:
	; wait
	ldi _ds_rr_trig_tmp1, 53
_ds_isr_trig_bad_wait:
	dec _ds_rr_trig_tmp1
    brne _ds_isr_trig_bad_wait
	; set output state to false
	clr _ds_rr_trig_tmp1
_ds_isr_trig_done:
	; write output state
	sts ds_ram_out_state, _ds_rr_trig_tmp1
	BL_SRC_OUT _ds_rr_trig_tmp1
	; cancel pending interrupts
	ldi _ds_rr_trig_tmp1, ICF_VAL | OCFA_VAL
	out _DS_TIFR, _ds_rr_trig_tmp1
	; enable interrupts
	ldi _ds_rr_trig_tmp1, ICIE_VAL | OCIEA_VAL
	sts _DS_TIMSK, _ds_rr_trig_tmp1
	; stop trig
	clr _ds_rr_trig_tmp1
	sts _DS_PORT, _ds_rr_trig_tmp1
	; start timer
	lds _ds_rr_trig_tmp1, _ds_ram_tccrb
	sts _DS_TCCRB, _ds_rr_trig_tmp1
	reti

#undef _ds_rr_trig_tmp1
#undef _ds_rr_trig_tmp2

#define _ds_r_ici_icrl ri0
#define _ds_r_ici_icrh ri1
#define _ds_r_ici_tmp1 ria
#define _ds_r_ici_tmp2 rib

ISR _DS_ICPaddr
	; load ICR
	lds _ds_r_ici_icrl, _DS_ICRL
	lds _ds_r_ici_icrh, _DS_ICRH
	; check if rising or falling edge
	lds _ds_r_ici_tmp1, _DS_TCCRB
	sbrs _ds_r_ici_tmp1, ICES
	rjmp _ds_l_isr_icp_falling
_ds_l_isr_icp_rising:
	; save ICR to sram
	sts _ds_ram_ltime, _ds_r_ici_icrl
	sts _ds_ram_ltime + 1, _ds_r_ici_icrh
	; set input capture to falling edge
	lds _ds_r_ici_tmp1, _DS_TCCRB
	andi _ds_r_ici_tmp1, ~(ICES_VAL)
	sts _DS_TCCRB, _ds_r_ici_tmp1
	reti
_ds_l_isr_icp_falling:
	; save difference to sram
	lds _ds_r_ici_tmp1, _ds_ram_ltime
	lds _ds_r_ici_tmp2, _ds_ram_ltime + 1
	sub _ds_r_ici_icrl, _ds_r_ici_tmp1
	sbc _ds_r_ici_icrh, _ds_r_ici_tmp2
	sts _ds_ram_ltime, _ds_r_ici_icrl
	sts _ds_ram_ltime + 1, _ds_r_ici_icrh
	; disable input capture interrupt
	ldi _ds_r_ici_tmp1, OCIEA_VAL
	sts _DS_TIMSK, _ds_r_ici_tmp1
	reti

#undef _ds_r_ici_icrh
#undef _ds_r_ici_icrl
#undef _ds_r_ici_tmp1
#undef _ds_r_ici_tmp2

#endif
