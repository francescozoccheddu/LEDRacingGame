.ifndef INC_DSENS_ASM
.equ INC_DSENS_ASM = 0

;reserved
.def dsens_time_l = r18
.def dsens_time_h = r19
.def dsens_l = r4
.def dsens_r = r5
.def dsens_stat = r20

.equ DSENS_OUT_MIN = 60
.equ DSENS_OUT_MMAX = 320
.equ DSENS_OUT_HOLD = 300

.equ DSENS_MULI_FACT = INT( (1 << 16) / (DSENS_OUT_MMAX - DSENS_OUT_MIN) )
.equ DSENS_OUT_CMAX = INT( (1 << 16) / DSENS_MULI_FACT ) 

.equ DSENS_PRESCALER = 64
.equ DSENS_MAX_PERIOD_MS = (1 << 16) * DSENS_PRESCALER * 1000 / FOSC
.equ DSENS_PERIOD_MS = 80
.equ DSENS_ECHO_MAX_WIDTH_MS = 30

.if DSENS_PERIOD_MS > DSENS_MAX_PERIOD_MS
.error "DSENS_PERIOD_MS is too long for selected prescaler"
.endif

.if DSENS_ECHO_MAX_WIDTH_MS > DSENS_PERIOD_MS
.error "DSENS_ECHO_MAX_WIDTH_MS is longer than DSENS_PERIOD_MS"
.endif

.equ DSENS_TOP = DSENS_PERIOD_MS * FOSC / 1000 / DSENS_PRESCALER
.equ DSENS_ECHO_TOP = DSENS_ECHO_MAX_WIDTH_MS * FOSC / 1000 / DSENS_PRESCALER

.equ DSENS_STAT_R_BIT = 1
.equ DSENS_STAT_FALLING_BIT = 2
.equ DSENS_STAT_DONE_BIT = 3

.equ DSENS_TRIG_PORT = PORTJ
.equ DSENS_TRIG_PORTD = DDRJ
.equ DSENS_TRIG_PORT_BIT_L = PJ0 ;pin 15
.equ DSENS_TRIG_PORT_BIT_R = PJ1 ;pin 14

.equ DSENS_ECHO_PORT = PORTD
.equ DSENS_ECHO_PORTD = DDRD
.equ DSENS_ECHO_PORT_BIT_L = PD0 ;pin 21
.equ DSENS_ECHO_PORT_BIT_R = PD1 ;pin 20
.equ DSENS_ECHO_EICR = EICRA
.equ DSENS_ECHO_EICR_ZERO_MASK = 3
.equ DSENS_ECHO_EICR_FALLING_BITS = 2
.equ DSENS_ECHO_EICR_RISING_BITS = 3
.equ DSENS_ECHO_EICR_BIT_L = ISC00
.equ DSENS_ECHO_EICR_BIT_R = ISC10
.equ DSENS_ECHO_EIMSK = EIMSK
.equ DSENS_ECHO_EIMSK_BIT_L = INT0
.equ DSENS_ECHO_EIMSK_BIT_R = INT1
.equ DSENS_ECHO_EIFR = EIFR
.equ DSENS_ECHO_EIFR_BITS = (1 << INTF0) | (1 << INTF1)

.if DSENS_PRESCALER == 1
.equ DSENS_CLOCK_SEL = 1
.elif DSENS_PRESCALER == 8
.equ DSENS_CLOCK_SEL = 2
.elif DSENS_PRESCALER == 64
.equ DSENS_CLOCK_SEL = 3
.elif DSENS_PRESCALER == 256
.equ DSENS_CLOCK_SEL = 4
.elif DSENS_PRESCALER == 1024
.equ DSENS_CLOCK_SEL = 5
.else
.error "Unknown prescaler value"
.endif

.equ DSENS_TCCRA = TCCR1A
.equ DSENS_TCCRA_BITS = 0
.equ DSENS_TCCRB = TCCR1B
.equ DSENS_TCCRB_BITS = (1 << WGM12) | (DSENS_CLOCK_SEL << CS10)
.equ DSENS_TCCRC = TCCR1C
.equ DSENS_TCCRC_BITS = 0

.equ DSENS_TCNTH = TCNT1H
.equ DSENS_TCNTL = TCNT1L

.equ DSENS_OCRAH = OCR1AH
.equ DSENS_OCRAL = OCR1AL

.equ DSENS_TIMSK = TIMSK1
.equ DSENS_TIMSK_BITS = (1 << OCIE1A)

;setup macro
;overrides 'r16'
.macro DSENS_SR_SETUP
	push r16
	;set trig port output
	lds r16, DSENS_TRIG_PORTD
	ori r16, (1 << DSENS_TRIG_PORT_BIT_L) | (1 << DSENS_TRIG_PORT_BIT_R)
	sts DSENS_TRIG_PORTD, r16
	;set echo port input
	in r16, DSENS_ECHO_PORTD
	andi r16, !((1 << DSENS_ECHO_PORT_BIT_L) | (1 << DSENS_ECHO_PORT_BIT_R))
	out DSENS_ECHO_PORTD, r16
	;clear timer counter
	clr r16
	sts DSENS_TCNTL, r16
	sts DSENS_TCNTH, r16
	;set timer top
	ldi r16, high(DSENS_TOP)
	sts DSENS_OCRAH, r16
	ldi r16, low(DSENS_TOP)
	sts DSENS_OCRAL, r16
	;set timer interrupt
	ldi r16, DSENS_TIMSK_BITS
	sts DSENS_TIMSK, r16
	;set timer control registers
	ldi r16, DSENS_TCCRA_BITS
	sts DSENS_TCCRA, r16
	ldi r16, DSENS_TCCRB_BITS
	sts DSENS_TCCRB, r16
	ldi r16, DSENS_TCCRC_BITS
	sts DSENS_TCCRC, r16
	pop r16
.endmacro

;params (0)'TRIG_PORT_BIT' (1)'ECHO_EICR_BIT' (2)'ECHO_EIMSK_BIT' (3)'label' (4)'res'
.macro DSENS_ISRM_OCA
	push r16
	;start 10us trigger
	lds r16, DSENS_TRIG_PORT
	ori r16, 1 << @0
	sts DSENS_TRIG_PORT, r16
	;disable interrupts
	in r16, DSENS_ECHO_EIMSK
	andi r16, !((1 << DSENS_ECHO_EIMSK_BIT_L) | (1 << DSENS_ECHO_EIMSK_BIT_R))
	out DSENS_ECHO_EIMSK, r16
	;cancel pending interrupts
	ldi r16, DSENS_ECHO_EIFR_BITS
	out DSENS_ECHO_EIFR, r16
	;set interrupt sense
	lds r16, DSENS_ECHO_EICR
	andi r16, !(DSENS_ECHO_EICR_ZERO_MASK << @1)
	ori r16, DSENS_ECHO_EICR_RISING_BITS << @1
	sts DSENS_ECHO_EICR, r16
	;set interrupt mask
	in r16, DSENS_ECHO_EIMSK
	ori r16, 1 << @2
	out DSENS_ECHO_EIMSK, r16
	;save measured time
	;skip if not done
	sbrs dsens_stat, DSENS_STAT_DONE_BIT
	rjmp @3_wait
	;clamping
	;clear near noise
	subi dsens_time_l, LOW( DSENS_OUT_MIN )
	sbci dsens_time_h, HIGH( DSENS_OUT_MIN )
	;skip if smaller
	brcs @3_smaller
	;skip if greater
	cpi dsens_time_l, LOW( DSENS_OUT_CMAX )
	ldi r16, HIGH( DSENS_OUT_CMAX )
	cpc dsens_time_h, r16
	brsh @3_greater
	;translate to 8-bit range
	ldi r16, DSENS_MULI_FACT
	mul dsens_time_h, r16
	mov dsens_time_h, r0
	mul dsens_time_l, r16
	add dsens_time_h, r1
	add @4, dsens_time_h
	ror @4
	;128 cycles wait
	ldi r16, 42
	nop
	nop
	rjmp @3_wait
@3_smaller:
	lsr @4
	;135 cycles wait
	ldi r16, 45
	rjmp @3_wait
@3_greater:
	cpi dsens_time_l, LOW( DSENS_OUT_CMAX + DSENS_OUT_HOLD )
	ldi r16, HIGH( DSENS_OUT_CMAX + DSENS_OUT_HOLD )
	cpc dsens_time_h, r16
	brsh @3_ggwait
	ser r16
	add @4, r16
	sbrc @4, 0
	inc @4
	ror @4
	;123 cycles wait
	ldi r16, 41
	rjmp @3_wait
@3_ggwait:
	;129 cycles wait
	ldi r16, 43
@3_wait:
	dec  r16
    brne @3_wait
	;end trigger
	lds r16, DSENS_TRIG_PORT
	andi r16, !(1 << @0)
	sts DSENS_TRIG_PORT, r16
	pop r16
.endmacro

dsens_isr_oca:
	sbrc dsens_stat, DSENS_STAT_R_BIT
	rjmp dsens_l_oca_r
	;set to right
	DSENS_ISRM_OCA DSENS_TRIG_PORT_BIT_R, DSENS_ECHO_EICR_BIT_R, DSENS_ECHO_EIMSK_BIT_R, dsens_lm_oca_r, dsens_r
	ldi dsens_stat, 1 << DSENS_STAT_R_BIT
	reti
dsens_l_oca_r:
	;set to left
	DSENS_ISRM_OCA DSENS_TRIG_PORT_BIT_L, DSENS_ECHO_EICR_BIT_L, DSENS_ECHO_EIMSK_BIT_L, dsens_lm_oca_l, dsens_l
	clr dsens_stat
	reti

;params (0)'label' (1)'ECHO_EIMSK_BIT' (2)'ECHO_EICR_BIT'
.macro DSENS_ISRM_ECHO
	sbrc dsens_stat, DSENS_STAT_FALLING_BIT
	rjmp @0_falling
	;rising
	;save current timer
	lds dsens_time_l, DSENS_TCNTL
	lds dsens_time_h, DSENS_TCNTH
	;set stat to falling
	ori dsens_stat, 1 << DSENS_STAT_FALLING_BIT
	;disable interrupt
	push r16
	in r16, DSENS_ECHO_EIMSK
	andi r16, !(1 << @1)
	out DSENS_ECHO_EIMSK, r16
	;set interrupt sense to falling edge
	lds r16, DSENS_ECHO_EICR
	andi r16, !(DSENS_ECHO_EICR_ZERO_MASK << @2)
	ori r16, DSENS_ECHO_EICR_FALLING_BITS << @2
	sts DSENS_ECHO_EICR, r16
	;enable interrupt
	in r16, DSENS_ECHO_EIMSK
	ori r16, 1 << @1
	out DSENS_ECHO_EIMSK, r16
	pop r16
	reti
@0_falling:
	;falling
	;save elapsed time
	push r16
	push r17
	lds r16, DSENS_TCNTL
	lds r17, DSENS_TCNTH
	sub r16, dsens_time_l
	sbc r17, dsens_time_h
	movw dsens_time_h:dsens_time_l, r17:r16
	pop r17
	;set stat done
	ori dsens_stat, 1 << DSENS_STAT_DONE_BIT 
	;disable interrupt
	in r16, DSENS_ECHO_EIMSK
	andi r16, !(1 << @1)
	out DSENS_ECHO_EIMSK, r16
	pop r16
	reti
.endmacro

dsens_isr_echo_l:
	DSENS_ISRM_ECHO dsens_lm_echo_l, DSENS_ECHO_EIMSK_BIT_L, DSENS_ECHO_EICR_BIT_L

dsens_isr_echo_r:
	DSENS_ISRM_ECHO dsens_lm_echo_r, DSENS_ECHO_EIMSK_BIT_R, DSENS_ECHO_EICR_BIT_R

.endif
