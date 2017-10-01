; Francesco Zoccheddu
; ARE
; EEPROM programming
; dirty timer 0 and registers

#define _ml_tmp

; [SOURCE] setup
; @0 (dirty immediate register)
.macro ML_SRC_SETUP

.endmacro

#undef _ml_tmp

#define _ml_col @0
#define _ml_cl @1
#define _ml_ch @2

; [SOURCE] main loop
; @0 (dirty immediate register)
; @1 (dirty immediate register)
; @2 (dirty immediate register)
.macro ML_SRC_LOOP
_ml_l_src_loop_begin:
	ldi _ml_col, 16
_ml_l_src_loop_column:
	dec _ml_col

	;debug
	lds _ml_cl, ds_ram_out_val
	lsr _ml_cl
	lsr _ml_cl
	lsr _ml_cl
	lsr _ml_cl
	cp _ml_cl, _ml_col
	breq ciao
	clr _ml_cl
	clr _ml_ch
	rjmp go
ciao:
	lds _ml_cl, ds_ram_out_state
	ser _ml_ch
go:
	
	cli
	LM_SRC_SEND_COL _ml_ch, _ml_cl, _ml_col, rmd, rme
	sei

	tst _ml_col
	brne _ml_l_src_loop_column
	rjmp _ml_l_src_loop_begin
.endmacro

#undef _ml_col
#undef _ml_cl
#undef _ml_ch
