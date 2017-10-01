; Francesco Zoccheddu
; ARE
; main

; assembler setup

.cseg
.nooverlap
.org INT_VECTORS_SIZE

.include "m2560def.inc"
#include "utils.inc"

.equ FOSC = 16000000

; interrupt registers

; immediate
.def ria = r18
.def rib = r19
.def ric = r20
.def rid = r21
; non-immediate
.def ri0 = r2
.def ri1 = r3
.def ri2 = r4
.def ri3 = r5
.def ri4 = r6
.def ri5 = r7
.def ri6 = r8
.def ri7 = r9

.include "builtin_led.asm"
.include "led_matrix.asm"
.include "uart_comm.asm"
.include "distance_sens.asm"

; main

.def m_tmp = r16

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

.undef m_tmp

m_l_loop:
	
	.def m_col = r16
	.def m_ch = r23
	.def m_cl = r24
	
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
	LM_SRC_SEND_COL m_ch, m_cl, m_col, r19, r20
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

ISR UC_RCOMPLETE_INTaddr
m_isr_tx:
	reti

ISR UC_TREADY_INTaddr
m_isr_e:
	lds ria, ds_ram_out_val
	UC_SRC_FT ria
	UC_SRC_TREADY_INTE 0, ria
	reti