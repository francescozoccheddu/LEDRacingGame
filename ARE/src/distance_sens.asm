; Francesco Zoccheddu
; ARE
; distance sensor

#define _DS_TIMER 4
#define _DS_IO L

TIM_DEF _DS, _DS_TIMER
IO_DEF _DS, _DS_IO

#define _DS_ICP_BIT 0 ; digital pin 49
#define _DS_TRIG_BIT 6 ; digital pin 43

#define _DS_MAX_WAIT_TIME TMS(60)
#define _DS_PSCL TPSCL_MIN_16(_DS_MAX_WAIT_TIME)
#define _DS_CS TCS_MIN_16(_DS_MAX_WAIT_TIME)
#define _DS_TOP int( TTOP(_DS_PSCL, _DS_MAX_WAIT_TIME) + 0.5 )

#define _ds_tmp @0

; [SOURCE] setup
; @0 (dirty immediate register)
.macro DS_SRC_SETUP
	; set timer control register A
	clr _ds_tmp
	sts _DS_TCCRA, _ds_tmp
	; set timer control register B
	ldi _ds_tmp, ICN_VAL
	sts _DS_TCCRB, _ds_tmp
	; set timer control register C
	clr _ds_tmp
	sts _DS_TCCRC, _ds_tmp
	; clear timer counter
	clr _ds_tmp
	sts _DS_TCNTH, _ds_tmp
	sts _DS_TCNTL, _ds_tmp
	; set timer interrupt mask
	ldi _ds_tmp, ICIE_VAL | OCIEA_VAL
	sts _DS_TIMSK, _ds_tmp
	; set timer output compare value A
	ldi _ds_tmp, HIGH( _DS_TOP )
	sts _DS_OCRAH, _ds_tmp
	ldi _ds_tmp, LOW( _DS_TOP )
	sts _DS_OCRAL, _ds_tmp
	; set data direction register to output for trig pin
	ldi _ds_tmp, 1 << _DS_TRIG_BIT
	sts _DS_DDR, _ds_tmp

#define DS_EMAX 300
#define DS_MAX 250
#define DS_MIN 70
	
	ldi @0, LOW( DS_MIN )
	sts _ds_ram_in_lol, @0
	ldi @0, HIGH( DS_MIN )
	sts _ds_ram_in_loh, @0
	ldi @0, LOW( DS_MAX )
	sts _ds_ram_in_hil, @0
	ldi @0, HIGH( DS_MAX )
	sts _ds_ram_in_hih, @0
	ldi @0, LOW( DS_EMAX )
	sts _ds_ram_in_ehil, @0
	ldi @0, HIGH( DS_EMAX )
	sts _ds_ram_in_ehih, @0


.endmacro

#undef _ds_tmp

.dseg
_ds_ram_in_lol: .byte 1
_ds_ram_in_loh: .byte 1
_ds_ram_in_hil: .byte 1
_ds_ram_in_hih: .byte 1
_ds_ram_in_ehil: .byte 1
_ds_ram_in_ehih: .byte 1
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
	breq _ds_l_isr_trig_clamp_stop
	dec _ds_out_hi
	breq _ds_l_isr_trig_clamp_stop
	add _ds_out_hi, _ds_out_lo
	inc _ds_out_hi
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

#define _ds_tmp ria

_ds_l_isr_trig_clamp_stop:
	; write output value
	sts ds_ram_out_val, _ds_out
	; set output state to true
	ser _ds_tmp
	rjmp _ds_isr_trig_done

#undef _ds_out

_ds_isr_trig_bad:
	; set output state to false
	clr _ds_tmp
_ds_isr_trig_done:
	; write output state
	sts ds_ram_out_state, _ds_tmp
	; enable interrupts
	ldi _ds_tmp, ICIE_VAL | OCIEA_VAL
	sts _DS_TIMSK, _ds_tmp
	; stop trig
	clr _ds_tmp
	sts _DS_PORT, _ds_tmp
	; start timer
	ldi _ds_tmp, CS_VAL(_DS_CS) | ICES_VAL | ICN_VAL
	sts _DS_TCCRB, _ds_tmp
	reti

#undef _ds_tmp

.dseg
_ds_ram_ltimel: .byte 1
_ds_ram_ltimeh: .byte 1
.cseg

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

