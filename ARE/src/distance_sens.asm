; Francesco Zoccheddu
; ARE
; distance sensor
; dirty timer 4 module and registers

#define _DS_TIMER 4
#define _DS_IO L

TIM_DEF _DS, _DS_TIMER
IO_DEF _DS, _DS_IO

#define _DS_ICP_BIT 0 ; digital pin 49
#define _DS_TRIG_BIT 6 ; digital pin 43

#define _ds_tmp @0

; [SOURCE] setup
; @0 (dirty immediate register)
.macro DS_SRC_SETUP
	; clear timer control registers
	clr _ds_tmp
	sts _DS_TCCRA, _ds_tmp
	sts _DS_TCCRB, _ds_tmp
	sts _DS_TCCRC, _ds_tmp
	; set timer interrupt mask
	ldi _ds_tmp, ICIE_VAL | OCIEA_VAL
	sts _DS_TIMSK, _ds_tmp
	; set data direction register to output for trig pin
	ldi _ds_tmp, 1 << _DS_TRIG_BIT
	sts _DS_DDR, _ds_tmp
.endmacro

#undef _ds_tmp

.macro DS_SRC_SPLOAD
#define DS_EMAX 300
#define DS_MAX 250
#define DS_MIN 70
#define DS_TIM 0.06
	
	ldi rma, LOW( DS_MIN )
	sts _ds_ram_in_lol, rma
	ldi rma, HIGH( DS_MIN )
	sts _ds_ram_in_loh, rma
	ldi rma, LOW( DS_MAX )
	sts _ds_ram_in_hil, rma
	ldi rma, HIGH( DS_MAX )
	sts _ds_ram_in_hih, rma
	ldi rma, LOW( DS_EMAX )
	sts _ds_ram_in_ehil, rma
	ldi rma, HIGH( DS_EMAX )
	sts _ds_ram_in_ehih, rma


	ldi rma, LOW( int(DS_TIM * T16_PROPF+0.5) )
	ldi rmb, HIGH( int(DS_TIM * T16_PROPF+0.5) )
	call t_sr_calc
	ori rmc, ICN_VAL | ICES_VAL
	sts _ds_ram_timtopl, rma
	sts _ds_ram_timtoph, rmb
	sts _ds_ram_tccrb, rmc
.endmacro

.dseg
_ds_ram_timtoph: .byte 1
_ds_ram_timtopl: .byte 1

_ds_ram_tccrb: .byte 1

_ds_ram_in_lol: .byte 1
_ds_ram_in_loh: .byte 1

_ds_ram_in_hil: .byte 1
_ds_ram_in_hih: .byte 1

_ds_ram_in_ehil: .byte 1
_ds_ram_in_ehih: .byte 1

_ds_ram_ltimel: .byte 1
_ds_ram_ltimeh: .byte 1

ds_ram_out_val: .byte 1

ds_ram_out_state: .byte 1
.cseg

ISR _DS_OCAaddr
ds_isr_trig:

#define _ds_tmp ria

	; start trig
	ldi _ds_tmp, 1 << _DS_TRIG_BIT
	sts _DS_PORT, _ds_tmp
	; stop timer
	clr _ds_tmp
	sts _DS_TCCRB, _ds_tmp
	; clear counter
	sts _DS_TCNTH, _ds_tmp
	sts _DS_TCNTL, _ds_tmp
	; set output compare value A
	lds _ds_tmp, _ds_ram_timtoph
	sts _DS_OCRAH, _ds_tmp
	lds _ds_tmp, _ds_ram_timtopl
	sts _DS_OCRAL, _ds_tmp
	; skip if not measured
	lds _ds_tmp, _DS_TIMSK
	sbrc _ds_tmp, ICIE
	rjmp _ds_isr_trig_bad

#undef _ds_tmp

#define _ds_cursl ria
#define _ds_cursh rib
#define _ds_inl ri0
#define _ds_inh ri1

	; skip if greater than max
	lds _ds_cursl, _ds_ram_in_ehil
	lds _ds_cursh, _ds_ram_in_ehih
	lds _ds_inl, _ds_ram_ltimel
	lds _ds_inh, _ds_ram_ltimeh
	cp _ds_inl, _ds_cursl
	cpc _ds_inh, _ds_cursh
	brsh _ds_isr_trig_bad

#define _ds_in_lol ri2
#define _ds_in_loh ri3
#define _ds_in_hil ri4
#define _ds_in_hih ri5
#define _ds_out_lo ric
#define _ds_out_hi rid
#define _ds_out ri6

	; clamp
	; setup clamp parameters
	lds _ds_in_lol, _ds_ram_in_lol
	lds _ds_in_loh, _ds_ram_in_loh
	lds _ds_in_hil, _ds_ram_in_hil
	lds _ds_in_hih, _ds_ram_in_hih
	clr _ds_out_lo
	ser _ds_out_hi
	; start clamping
_ds_l_isr_trig_clamp_start:
	movw _ds_cursh:_ds_cursl, _ds_in_hih:_ds_in_hil
	mov _ds_out, _ds_out_hi
_ds_l_isr_trig_clamp_loop:
	sub _ds_out_hi, _ds_out_lo
	cpi _ds_out_hi, 2
	brlo _ds_l_isr_trig_clamp_stop
	add _ds_out_hi, _ds_out_lo
	cp _ds_cursl, _ds_inl
	cpc _ds_cursh, _ds_inh
	breq _ds_l_isr_trig_clamp_stop
	brsh _ds_l_isr_trig_clamp_smaller
_ds_l_isr_trig_clamp_greater:
	movw _ds_in_loh:_ds_in_lol, _ds_cursh:_ds_cursl
	mov _ds_out_lo, _ds_out
	add _ds_cursl, _ds_in_hil
	adc _ds_cursh, _ds_in_hih
	ror _ds_cursh
	ror _ds_cursl
	add _ds_out, _ds_out_hi
	ror _ds_out
	rjmp _ds_l_isr_trig_clamp_loop
_ds_l_isr_trig_clamp_smaller:
	movw _ds_in_hih:_ds_in_hil, _ds_cursh:_ds_cursl
	mov _ds_out_hi, _ds_out
	add _ds_cursl, _ds_in_lol
	adc _ds_cursh, _ds_in_loh
	ror _ds_cursh
	ror _ds_cursl
	add _ds_out, _ds_out_lo
	ror _ds_out
	rjmp _ds_l_isr_trig_clamp_loop

#undef _ds_cursl
#undef _ds_cursh
#undef _ds_inl
#undef _ds_inh
#undef _ds_in_lol
#undef _ds_in_loh
#undef _ds_in_hil
#undef _ds_in_hih
#undef _ds_out_lo
#undef _ds_out_hi

#define _ds_tmp1 ria
#define _ds_tmp2 rib

#define ds_state_updated ria

_ds_l_isr_trig_clamp_stop:
	; write output value
	sts ds_ram_out_val, _ds_out
	; set output state to true
	ser _ds_tmp1
	rjmp _ds_isr_trig_done

#undef _ds_out

_ds_isr_trig_bad:
	; set output state to false
	clr _ds_tmp1
_ds_isr_trig_done:
	; write output state
	lds _ds_tmp2, ds_ram_out_state
	sts ds_ram_out_state, _ds_tmp1
	cp _ds_tmp1, _ds_tmp2 
	breq _ds_isr_trig_state_unchanged
	call ml_sr_ds_state_update
_ds_isr_trig_state_unchanged:
	; enable interrupts
	ldi _ds_tmp1, ICIE_VAL | OCIEA_VAL
	sts _DS_TIMSK, _ds_tmp1
	; stop trig
	clr _ds_tmp1
	sts _DS_PORT, _ds_tmp1
	; start timer
	lds _ds_tmp1, _ds_ram_tccrb
	sts _DS_TCCRB, _ds_tmp1
	reti

#undef _ds_tmp1
#undef _ds_tmp2

#define _ds_icrl ri0
#define _ds_icrh ri1
#define _ds_tmp1 ria
#define _ds_tmp2 rib

ISR _DS_ICPaddr
	; load ICR
	lds _ds_icrl, _DS_ICRL
	lds _ds_icrh, _DS_ICRH
	; check if rising or falling edge
	lds _ds_tmp1, _DS_TCCRB
	sbrs _ds_tmp1, ICES
	rjmp _ds_l_isr_icp_falling
_ds_l_isr_icp_rising:
	; save ICR to sram
	sts _ds_ram_ltimel, _ds_icrl
	sts _ds_ram_ltimeh, _ds_icrh
	; set input capture to falling edge
	lds _ds_tmp1, _DS_TCCRB
	andi _ds_tmp1, ~(ICES_VAL)
	sts _DS_TCCRB, _ds_tmp1
	reti
_ds_l_isr_icp_falling:
	; save difference to sram
	lds _ds_tmp1, _ds_ram_ltimel
	lds _ds_tmp2, _ds_ram_ltimeh
	sub _ds_icrl, _ds_tmp1
	sbc _ds_icrh, _ds_tmp2
	sts _ds_ram_ltimel, _ds_icrl
	sts _ds_ram_ltimeh, _ds_icrh
	; disable input capture interrupt
	ldi _ds_tmp1, OCIEA_VAL
	sts _DS_TIMSK, _ds_tmp1
	reti

#undef _ds_icrh
#undef _ds_icrl
#undef _ds_tmp1
#undef _ds_tmp2

