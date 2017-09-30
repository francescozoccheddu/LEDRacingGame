; Francesco Zoccheddu
; ARE
; distance sensor

#define _DS_TIMER 4
#define _DS_IO L

TIM_DEF _DS, _DS_TIMER
IO_DEF _DS, _DS_IO

.equ _DS_ICP_BIT = 0 ; digital pin 49
.equ _DS_TRIG_BIT = 6 ; digital pin 43

#define _DS_MAX_WAIT_TIME TMS(60)
.equ _DS_PSCL = TPSCL_MIN_16(_DS_MAX_WAIT_TIME)
.equ _DS_CS = TCS_MIN_16(_DS_MAX_WAIT_TIME)
.equ _DS_TOP = int( TTOP(_DS_PSCL, _DS_MAX_WAIT_TIME) + 0.5 )

; [SOURCE] setup
; @0 (dirty immediate register)
.macro DS_SRC_SETUP
	; set timer control register A
	clr @0
	sts _DS_TCCRA, @0
	; set timer control register B
	ldi @0, ICN_VAL
	sts _DS_TCCRB, @0
	; set timer control register C
	clr @0
	sts _DS_TCCRC, @0
	; clear timer counter
	clr @0
	sts _DS_TCNTH, @0
	sts _DS_TCNTL, @0
	; set timer interrupt mask
	ldi @0, ICIE_VAL | OCIEA_VAL
	sts _DS_TIMSK, @0
	; set timer output compare value A
	ldi @0, HIGH( _DS_TOP )
	sts _DS_OCRAH, @0
	ldi @0, LOW( _DS_TOP )
	sts _DS_OCRAL, @0
	; set data direction register to output for trig pin
	ldi @0, 1 << _DS_TRIG_BIT
	sts _DS_DDR, @0
.endmacro

#define _DS_OUT intr4

; [SOURCE] clamp input '@0:@1' between '@2:@3' and '@4:@5' and return '_DS_OUT' between '@6' and '@7'
; @0 (input h)
; @1 (input l)
; @2 (input bottom l)
; @3 (input bottom h)
; @4 (input top h)
; @5 (input top l)
; @6 (output bottom)
; @7 (output high)
; @8 (dirty register)
; @9 (dirty register)
.macro DS_SRC_CLAMP
	.equ _DS_SRC_CLAMP_BACKUP_CURS = 1
	.if _DS_SRC_CLAMP_BACKUP_CURS
		push @8
		push @9
	.endif
	movw @8:@9, @4:@5
	mov _DS_OUT, @7
_ds_l_sr_clamp_loop:
	sub @7, @6
	dec @7
	breq _ds_l_sr_clamp_return
	add @7, @6
	inc @7
	cp @9, @1
	cpc @8, @0
	breq _ds_l_sr_clamp_return
	brsh _ds_l_sr_clamp_smaller
_ds_l_sr_clamp_greater:
	movw @2:@3, @8:@9
	mov @6, _DS_OUT
	add @9, @5
	adc @8, @4
	ror @8
	ror @9
	add _DS_OUT, @7
	ror _DS_OUT
	rjmp _ds_l_sr_clamp_loop
_ds_l_sr_clamp_smaller:
	movw @4:@5, @8:@9
	mov @7, _DS_OUT
	add @9, @3
	adc @8, @2
	ror @8
	ror @9
	add _DS_OUT, @6
	ror _DS_OUT
	rjmp _ds_l_sr_clamp_loop
_ds_l_sr_clamp_stop:
	.if _DS_SRC_CLAMP_BACKUP_CURS
		pop @9
		pop @8
	.endif
.endmacro

ISR _DS_OCAaddr
ds_isr_trig:
	; start trig
	ldi intr0, 1 << _DS_TRIG_BIT
	sts _DS_PORT, intr0
	; stop timer
	clr intr0
	sts _DS_TCCRB, intr0
	; clear counter
	sts _DS_TCNTH, intr0
	sts _DS_TCNTL, intr0
	
    ldi  intr0, 53
L1: dec  intr0
    brne L1
    nop

	; enable interrupts
	ldi intr0, ICIE_VAL | OCIEA_VAL
	sts _DS_TIMSK, intr0
	; stop trig
	clr intr0
	sts _DS_PORT, intr0
	; start timer
	ldi intr0, CS_VAL(_DS_CS) | ICES_VAL | ICN_VAL
	sts _DS_TCCRB, intr0
	reti

.dseg
_ds_ram_ltimeh: .byte 1
_ds_ram_ltimel: .byte 1
.cseg

ISR _DS_ICPaddr
	; load ICR
	lds intr0, _DS_ICRL
	lds intr1, _DS_ICRH
	; check if rising or falling edge
	lds intr2, _DS_TCCRB
	sbrs intr2, ICES
	rjmp _ds_l_isr_icp_falling
_ds_l_isr_icp_rising:
	; save ICR to sram
	sts _ds_ram_ltimeh, intr1
	sts _ds_ram_ltimel, intr0
	; set input capture to falling edge
	lds intr0, _DS_TCCRB
	andi intr0, ~(ICES_VAL)
	sts _DS_TCCRB, intr0
	reti
_ds_l_isr_icp_falling:
	; save difference to sram
	lds intr2, _ds_ram_ltimel
	lds intr3, _ds_ram_ltimeh
	sub intr0, intr2
	sbc intr1, intr3
	sts _ds_ram_ltimeh, intr1
	sts _ds_ram_ltimel, intr0
	; disable input capture interrupt
	ldi intr0, OCIEA_VAL
	sts _DS_TIMSK, intr0
	reti

