.include "defs.inc"

;interrupt vector space

.include "intv/distance_sens_v2.inc"

.org RESET_ADDR
rjmp l_reset


;code space declaration
.org INT_VECTORS_SIZE
;code space

.include "asm/uart.asm"
.include "asm/distance_sens_v2.asm"

;main space

l_reset:
	;setup stack
	ldi r16, HIGH(RAMEND)
	out SPH, r16
	ldi r16, LOW(RAMEND)
	out SPL, r16
	;setup power reduction
	/*ldi r16, (1 << PRTIM2)
	sts PRR0, r16
	ser r16
	sts PRR1, r16*/
	;disable JTAG
	in r16, MCUCR
	ori r16, 1 << JTD 
	out MCUCR, r16
	;setup modules
	DSENS_SR_SETUP
	UART_SR_SETUP
/*	LED_SR_SETUP
	DSENS_SR_SETUP*/
	;turn off led
	/*call led_sr_off*/
	;set interrupts
	SEI

l_loop:	
	lds r16, ICR4L
	UART_SR_I r16
	UART_SR_L
	rjmp l_loop
