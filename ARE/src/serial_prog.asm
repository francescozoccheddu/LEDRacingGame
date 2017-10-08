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

#define _SP_OPCODE_MSK ~(1 << _SP_OPCODE_RW)
#define _SP_OPCODE_RW 7

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
	sbrc _sp_b1, _SP_OPCODE_RW
	rjmp _sp_l_isr_write
	EP_SRC_WAIT
	EP_SRC_ADDR _sp_b2, _sp_tmp
	EP_SRC_FREAD _sp_data
	rcall _sp_sr_ut
	reti
_sp_l_isr_write:
	rcall _sp_sr_ur
	EP_SRC_WAIT
	EP_SRC_ADDR _sp_b2, _sp_tmp
	EP_SRC_FWRITE _sp_data
	reti

#undef _sp_b1
#undef _sp_b2

#undef _sp_data
#undef _sp_tmp

#define sp_data rma
#define sp_addrh rmb
#define sp_addrl rmc

sp_sr_load:
	EP_SRC_WAIT
	EP_SRC_ADDR sp_addrl, sp_addrh
	EP_SRC_FREAD sp_data
	ret

sp_sr_store:
	EP_SRC_WAIT
	EP_SRC_ADDR sp_addrl, sp_addrh
	EP_SRC_FWRITE sp_data
	ret

