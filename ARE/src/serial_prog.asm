; Francesco Zoccheddu
; ARE
; serial programming
; dirty UART RX complete interrupt

#define _sp_data ric
#define _sp_tmp rib

_sp_sr_ut:
	UC_SRC_T _sp_data, _sp_tmp
	ret

_sp_sr_ur:
	UC_SRC_R _sp_data
	ret

#define _SP_OPCODE_MSK 0b00111111
#define _SP_OPCODE_R_W 7
#define _SP_OPCODE_EEPR_RAM 6

#define _sp_b1 ri0
#define _sp_b2 ria

ISR UC_RCOMPLETE_INTaddr
	BL_SRC_OFF _sp_tmp
	; store bit 1 in 'b1'
	rcall _sp_sr_ur 
	mov _sp_b1, _sp_data
	; store bit 2 in 'b2'
	rcall _sp_sr_ur 
	mov _sp_b2, _sp_data
	; eventually store bit 3 in 'data'
	sbrc _sp_b1, _SP_OPCODE_R_W
	rcall _sp_sr_ur
	; store address h in 'tmp'
	mov _sp_tmp, _sp_b1
	andi _sp_tmp, _SP_OPCODE_MSK
	sbrc _sp_b1, _SP_OPCODE_EEPR_RAM
	rjmp _sp_l_isr_incoming_addr_ram
	; EEPROM address
	EP_SRC_WAIT
	EP_SRC_ADDR _sp_b2, _sp_tmp
	sbrc _sp_b1, _SP_OPCODE_R_W
	rjmp _sp_l_isr_incoming_eeprom_write
	; EEPROM read
	EP_SRC_FREAD _sp_data
	rcall _sp_sr_ut
	reti
_sp_l_isr_incoming_eeprom_write:
	; EEPROM write
	EP_SRC_FWRITE _sp_data
	reti
_sp_l_isr_incoming_addr_ram:
	; SRAM address
	push ZL
	push ZH
	movw ZH:ZL, _sp_tmp:_sp_b2
	sbrc _sp_b1, _SP_OPCODE_R_W
	rjmp _sp_l_isr_incoming_sram_write
	; EEPROM read
	ld _sp_data, Z
	rcall _sp_sr_ut
	rjmp _sp_l_isr_incoming_sram_done
_sp_l_isr_incoming_sram_write:
	; EEPROM write
	st Z, _sp_data
_sp_l_isr_incoming_sram_done:
	pop ZH
	pop ZL
	reti

#undef _sp_b1
#undef _sp_b2

#undef _sp_data
#undef _sp_tmp
