.include "m2560def.inc"
.include "distance_sens.inc"

.equ FOSC = 16000000
.equ RESET_ADDR = 0

.org RESET_ADDR
rjmp l_reset

.org INT_VECTORS_SIZE

.include "led.asm"
.include "uart.asm"
.include "distance_sens.asm"

l_reset:
	;setup stack
	ldi r16, HIGH(RAMEND)
	out SPH, r16
	ldi r16, LOW(RAMEND)
	out SPL, r16
	;setup power reduction
	ldi r16, (1 << PRTIM2)
	sts PRR0, r16
	ser r16
	sts PRR1, r16
	;disable JTAG
	in r16, MCUCR
	ori r16, 1 << JTD 
	out MCUCR, r16
	;setup modules
	UART_SR_SETUP
	LED_SR_SETUP
	DSENS_SR_SETUP
	;turn off led
	call led_sr_off
	;set interrupts
	SEI

l_loop:	
	UART_SR_I dsens_l 
	UART_SR_CI ':'
	UART_SR_I dsens_r
	UART_SR_L 
	rjmp l_loop
