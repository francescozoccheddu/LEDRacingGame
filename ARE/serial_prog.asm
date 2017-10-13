#ifdef _INC_SP
#error __FILE__ already included
#else
#define _INC_SP

; Francesco Zoccheddu
; ARE
; serial programming
; dirty UART RX complete interrupt

#define _SP_UC_BAUDRATE 9600

#define _SP_UC_UCSRA_VAL 0
#define _SP_UC_UCSRB_VAL (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0)
#define _SP_UC_UCSRC_VAL (2 << UMSEL0) | (3 << UCSZ00)
#define _SP_UC_UDRE_VAL (1 << UDRIE0)
#define _SP_UC_UBRR FOSC / 16 / _SP_UC_BAUDRATE - 1

#define _SP_UC_RCOMPLETE_INTaddr URXC0addr

#define _sp_r_setup_tmp @0

; [SOURCE] setup
; @0 (dirty immediate register)
.macro SP_SRC_SETUP
	; set UBRRR
	ldi _sp_r_setup_tmp, HIGH( _SP_UC_UBRR )
	sts UBRR0H, _sp_r_setup_tmp
	ldi _sp_r_setup_tmp, LOW( _SP_UC_UBRR )
	sts UBRR0L, _sp_r_setup_tmp
	; set UCSRA
	ldi _sp_r_setup_tmp, _SP_UC_UCSRA_VAL
	sts UCSR0A, _sp_r_setup_tmp
	; set UCSRB
	ldi _sp_r_setup_tmp, _SP_UC_UCSRB_VAL
	sts UCSR0B, _sp_r_setup_tmp
	; set UCSRC
	ldi _sp_r_setup_tmp, _SP_UC_UCSRC_VAL
	sts UCSR0C, _sp_r_setup_tmp
.endmacro

#undef _sp_r_setup_tmp

#define _SP_OPCODE_RW 7

#define _sp_r_rc_tmp ria

ISR _SP_UC_RCOMPLETE_INTaddr
	BL_SRC_OFF _sp_r_rc_tmp
	; wait for eeprom
_sp_l_rc_wait:
	sbic EECR, EEPE
	rjmp _sp_l_rc_wait
	; store bit 1 in 'b1'
_sp_l_rc_r1:
	lds _sp_r_rc_tmp, UCSR0A
	sbrs _sp_r_rc_tmp, RXC0
	rjmp _sp_l_rc_r1
	lds _sp_r_rc_tmp, UDR0
	out EEARL, _sp_r_rc_tmp
	; store bit 2 in 'b2'
_sp_l_rc_r2:
	lds _sp_r_rc_tmp, UCSR0A
	sbrs _sp_r_rc_tmp, RXC0
	rjmp _sp_l_rc_r2
	lds _sp_r_rc_tmp, UDR0
	out EEARH, _sp_r_rc_tmp
	; eventually store bit 3 in 'data'
	sbrc _sp_r_rc_tmp, _SP_OPCODE_RW
	rjmp _sp_l_isr_write
_sp_l_rc_read:
	lds _sp_r_rc_tmp, UCSR0A
	sbrs _sp_r_rc_tmp, UDRE0
	rjmp _sp_l_rc_read
	sbi EECR, EERE
	in _sp_r_rc_tmp, EEDR
	sts UDR0, _sp_r_rc_tmp
	reti
_sp_l_isr_write:
	lds _sp_r_rc_tmp, UCSR0A
	sbrs _sp_r_rc_tmp, RXC0
	rjmp _sp_l_isr_write
	lds _sp_r_rc_tmp, UDR0
	out EEDR, _sp_r_rc_tmp
	sbi EECR, EEMPE
	sbi EECR, EEPE
	reti

#undef _sp_r_rc_tmp

#define sp_data ria
#define sp_addrh rib
#define sp_addrl ric
#define sp_size rid

.macro SP_SRC_LOAD
	ldi sp_addrl, LOW( @0 )
	ldi sp_addrh, HIGH( @0 )
	rcall sp_sr_load
.endmacro

.macro SP_SRC_LOAD_TO_RAM
.if @2 == 1
	SP_SRC_LOAD @0
	sts @1, sp_data
.elif @2 == 2
	SP_SRC_LOAD @0
	sts @1, sp_data
	SP_SRC_LOAD @0 + 1
	sts @1 + 1, sp_data
.else
	ldi sp_addrl, LOW( @0 )
	ldi sp_addrh, HIGH( @0 )
	ldi XL, LOW( @1 )
	ldi XH, HIGH( @1 )
	ldi sp_size, @2
	rcall sp_sr_load_to_ram
.endif
.endmacro

.macro SP_SRC_STORE
	ldi sp_addrl, LOW( @0 )
	ldi sp_addrh, HIGH( @0 )
	rcall sp_sr_store
.endmacro

sp_sr_load:
	EP_SRC_WAIT
	EP_SRC_ADDR sp_addrl, sp_addrh
	EP_SRC_FREAD sp_data
	ret

sp_sr_load_to_ram:
	EP_SRC_WAIT
	EP_SRC_ADDR sp_addrl, sp_addrh
	EP_SRC_FREAD sp_data
	st X+, sp_data
	inc sp_addrl
	clr sp_data
	adc sp_addrh, sp_data
	dec sp_size
	brne sp_sr_load_to_ram
	ret

sp_sr_store:
	EP_SRC_WAIT
	EP_SRC_ADDR sp_addrl, sp_addrh
	EP_SRC_FWRITE sp_data
	ret

#endif
