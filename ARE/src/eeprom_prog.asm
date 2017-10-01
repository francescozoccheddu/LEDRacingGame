; Francesco Zoccheddu
; ARE
; EEPROM programming

#define _ep_addrl @0
#define _ep_addrh @1

; [SOURCE] set EEPROM address to '@1:@0'
; @0 (eeprom address l)
; @1 (eeprom address h)
.macro EP_SRC_ADDR
	out EEARL, _ep_addrl
	out EEARH, _ep_addrh
.endmacro

; [SOURCE] wait until EEPROM is ready
.macro EP_SRC_WAIT
_ep_l_src_wait:
	sbic EECR, EEPE
	rjmp _ep_l_src_wait
.endmacro

#define _ep_data @0

; [SOURCE] immediately write '@2' to EEPROM
; @0 (data)
.macro EP_SRC_FWRITE
	out EEDR, _ep_data
	sbi EECR, EEMPE
	sbi EECR, EEPE
.endmacro

; [SOURCE] immediately read to '@2' register from EEPROM
; @0 (data out)
.macro EP_SRC_FREAD
	sbi EECR, EERE
	in _ep_data, EEDR
.endmacro

#undef _ep_data
