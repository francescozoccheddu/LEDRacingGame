; Francesco Zoccheddu
; ARE
; main

; assembler setup

.cseg
.nooverlap
.org INT_VECTORS_SIZE

#include "m2560def.inc"
#include "utils.inc"

#define FOSC 16000000

; interrupt registers

#include "builtin_led.asm"
#include "led_matrix.asm"
#include "uart_comm.asm"
#include "distance_sens.asm"
#include "eeprom_prog.asm"
#include "serial_prog.asm"

; main

#define m_tmp rma

ISR 0
m_l_reset:
	; setup stack
	STACK_SETUP m_tmp
	; setup builtin LED
	BL_SRC_SETUP m_tmp
	BL_SRC_OFF m_tmp
	; setup LED matrix
	LM_SRC_SETUP m_tmp
	; setup UART communication
	UC_SRC_SETUP m_tmp
	;setup distance sensor
	DS_SRC_SETUP m_tmp
	call ds_isr_trig
	;enable interrupts
	sei


#undef m_tmp

#define m_col rma
#define m_cl rmb
#define m_ch rmc

m_l_loop:	
	
	ldi m_col, 15
m_l_cloop:
	lds m_cl, ds_ram_out_val
	lsr m_cl
	lsr m_cl
	lsr m_cl
	lsr m_cl
	cp m_cl, m_col
	breq ciao
	clr m_cl
	clr m_ch
	rjmp go
ciao:
	lds m_cl, ds_ram_out_state
	ser m_ch
go:
	cli
	LM_SRC_SEND_COL m_ch, m_cl, m_col, rmd, rme
	sei

	;wait
	ldi m_cl, 255
m_l_wait:
	dec m_cl
	brne m_l_wait


	;loop col
	dec m_col
	cpi m_col, 255
	brne m_l_cloop

	;loop draw
	rjmp m_l_loop

#undef m_col
#undef m_cl
#undef m_ch
