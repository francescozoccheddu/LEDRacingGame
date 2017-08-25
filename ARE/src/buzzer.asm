#ifdef SRAM
;################## SRAM ##################

	.equ BZ_MAX_BUZZ_COUNT = 10
	sram_bytes BZ_R_VEC, BZ_MAX_BUZZ_COUNT * 3
	.equ BZ_R_VEC_END = BZ_R_VEC + BZ_MAX_BUZZ_COUNT * 3

;##########################################
#endif

#ifdef INTV
;################## INTV ##################

	.org OC1Aaddr
	rjmp bz_isr_next

;##########################################
#endif

#ifdef MACROS
;################# MACROS #################

	.def bz_tmp = r22

	.equ BZ_PORT = PORTG
	.equ BZ_PORTD = DDRG
	.equ BZ_PORT_BIT = PG5 ;PWM pin 4
	
	.equ BZ_PWM_TCCRA = TCCR0A
	.equ BZ_PWM_TCCRB = TCCR0B
	.equ BZ_PWM_OCRA = OCR0A
	.equ BZ_PWM_WGM = 2
	.equ BZ_PWM_COM = 1
	.equ BZ_PWM_COM_BIT = COM0B0
	.equ BZ_PWM_CS_ON = 4

	.equ BZ_SQ_TCCRB = TCCR1B
	.equ BZ_SQ_OCRAH = OCR1AH
	.equ BZ_SQ_OCRAL = OCR1AL
	.equ BZ_SQ_TIMSK = TIMSK1
	.equ BZ_SQ_TCNTH = TCNT1H
	.equ BZ_SQ_TCNTL = TCNT1L
	.equ BZ_SQ_TIFR = TIFR1
	.equ BZ_SQ_OCIEA = 1 << OCIE1A
	.equ BZ_SQ_OCFA = 1 << OCF1A
	.equ BZ_SQ_TCCRB_WGM = (4 >> 2) << 3	

	.equ BZ_MAX_DURATION_MS = 1000

	TIMUTILS_M_PSCL (BZ_MAX_DURATION_MS / 1000.0), 16, BZ_SQ_PSCL
	TIMUTILS_M_CS BZ_SQ_PSCL, BZ_SQ_CS

;params (0)'tone index' (1)'sequence size' (2)'duration ms' (3)'tone cycles or zero'
.macro BZ_SR_SQ_SET_TONE
	.if @0 >= BZ_MAX_BUZZ_COUNT || @0 < 0
		.error "Tone index out of bounds"
	.endif
	.if @1 > BZ_MAX_BUZZ_COUNT || @1 < 1 || @1 <= @0
		.error "Sequence size out of bounds"
	.endif
	TIMUTILS_M_TOP_SET BZ_SQ_PSCL, @2 / 1000.0, BZ_SQ_TOP_TMP
	.if BZ_SQ_TOP_TMP < 1
		.error "Too short duration"
	.elif BZ_SQ_TOP_TMP >= 1 << 16
		.error "Too long duration"
	.endif
	ldi bz_tmp, HIGH( BZ_SQ_TOP_TMP )
	sts BZ_R_VEC + (@0 + BZ_MAX_BUZZ_COUNT - @1) * 3, bz_tmp
	ldi bz_tmp, LOW ( BZ_SQ_TOP_TMP )
	sts BZ_R_VEC + (@0 + BZ_MAX_BUZZ_COUNT - @1) * 3 + 1, bz_tmp
	ldi bz_tmp, @3
	sts BZ_R_VEC + (@0 + BZ_MAX_BUZZ_COUNT - @1) * 3 + 2, bz_tmp
.endmacro

;params (0)'sequence size'
.macro BZ_SR_SQ_START
	.if @0 >= BZ_MAX_BUZZ_COUNT || @0 < 0
		.error "Tone index out of bounds"
	.endif
	;reset X
	ldi XH, HIGH( BZ_R_VEC_END - @0 * 3 )
	ldi XL, LOW( BZ_R_VEC_END - @0 * 3 )
	;manually jump to isr
	call bz_isr_next
.endmacro

;auto
;params (0)'sequence size'
.macro BZ_SR_ASQ_BEGIN
	.if @0 <= 0 || @0 > BZ_MAX_BUZZ_COUNT
		.error "Sequence size out of bounds"
	.endif
	.set BZ_ASQ_SIZE = @0
	.set BZ_ASQ_IND = 0
.endmacro

;params (0)'duration ms' (1)'tone cycles or zero'
.macro BZ_SR_ASQ_PUSH
	.if !BZ_ASQ_SIZE
		.error "Sequence not started"
	.elif BZ_ASQ_IND >= BZ_ASQ_SIZE
		.error "Sequence out of bounds"
	.endif
	BZ_SR_SQ_SET_TONE BZ_ASQ_IND, BZ_ASQ_SIZE, @0, @1
	.set BZ_ASQ_IND = BZ_ASQ_IND + 1
.endmacro

.macro BZ_SR_ASQ_END
	.if !BZ_ASQ_SIZE
		.error "Sequence not started"
	.elif BZ_ASQ_IND != BZ_ASQ_SIZE
		.error "Sequence incomplete"
	.endif
	BZ_SR_SQ_START BZ_ASQ_SIZE
	.set BZ_ASQ_SIZE = 0
	.set BZ_ASQ_IND = 0
.endmacro
;##########################################
#endif


#ifdef SETUP
;################## SETUP #################

	;set PWM port to output
	in bz_tmp, BZ_PORTD
	ori bz_tmp, 1 << BZ_PORT_BIT
	out BZ_PORTD, bz_tmp
	;set PWM timer TCCRA
	ldi bz_tmp, (BZ_PWM_COM << BZ_PWM_COM_BIT) | (BZ_PWM_WGM & 0b11)
	out BZ_PWM_TCCRA, bz_tmp
	;enable SQ timer interrupt
	ldi bz_tmp, BZ_SQ_OCIEA
	sts BZ_SQ_TIMSK, bz_tmp

;##########################################
#endif

#ifdef CODE
;################## CODE ##################

bz_isr_next:
	;stop timer
	clr bz_tmp
	sts BZ_SQ_TCCRB, bz_tmp
	;clear counter
	sts BZ_SQ_TCNTH, bz_tmp
	sts BZ_SQ_TCNTL, bz_tmp
	;clear pending interrupts
	ldi bz_tmp, BZ_SQ_OCFA
	sts BZ_SQ_TIFR, bz_tmp
	;check if finished
	cpi XL, LOW( BZ_R_VEC_END )
	ldi bz_tmp, HIGH( BZ_R_VEC_END )
	cpc XH, bz_tmp
	breq bz_l_isr_next_end
	;not finished
	;set next top
	ld bz_tmp, X+
	sts BZ_SQ_OCRAH, bz_tmp
	ld bz_tmp, X+
	sts BZ_SQ_OCRAL, bz_tmp
	;load buzzer cycles and check if tone (>0) or mute (=0)
	ld bz_tmp, X+
	tst bz_tmp
	breq bz_l_isr_next_mute
	;tone
	out BZ_PWM_OCRA, bz_tmp
	ldi bz_tmp, ((BZ_PWM_WGM & 0b100) << 3) | BZ_PWM_CS_ON
bz_l_isr_next_mute:
	out BZ_PWM_TCCRB, bz_tmp
	;start timer
	ldi bz_tmp, BZ_SQ_TCCRB_WGM | BZ_SQ_CS
	sts BZ_SQ_TCCRB, bz_tmp
	reti
bz_l_isr_next_end:
	;finished
	;stop buzzer
	clr bz_tmp
	out BZ_PWM_TCCRB, bz_tmp
	reti

;##########################################
#endif
