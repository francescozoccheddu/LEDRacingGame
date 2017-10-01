; Francesco Zoccheddu
; ARE
; LED matrix
; dirty PORTC, DDRC, PINC

#define _LM_IO C

IO_DEF _LM, _LM_IO
#define _LM_BIT_ABCD 0 ; digital pin 34-37
#define _LM_BIT_G 4 ; digital pin 33
#define _LM_BIT_DI 5 ; digital pin 32
#define _LM_BIT_CLK 6 ; digital pin 31
#define _LM_BIT_LAT 7 ; digital pin 30

#define _lm_tmp @0

; [SOURCE] setup
; @0 (dirty immediate register)
.macro LM_SRC_SETUP
	ser _lm_tmp
	out _LM_DDR, _lm_tmp
.endmacro

#undef _lm_tmp

#define _ds_cdl @0
#define _ds_cdh @1
#define _ds_ci @2
#define _ds_tmp1 @3
#define _ds_tmp2 @4

; [SOURCE] send column data '@0:@1' with column index '@2' 
; @0 (column data low register)
; @1 (column data high register)
; @2 (column index register)
; @3 (dirty immediate register)
; @4 (dirty immediate register)
.macro LM_SRC_SEND_COL
	ldi _ds_tmp1, 16
_lm_l_src_send_col_row:
	ldi _ds_tmp2, (1 << _LM_BIT_G) | (1 << _LM_BIT_DI)
	lsr _ds_cdh
	ror _ds_cdl
	brcc _lm_l_src_send_col_out_dot
	ldi _ds_tmp2, (1 << _LM_BIT_G)
_lm_l_src_send_col_out_dot:
	out _LM_PORT, _ds_tmp2
	ori _ds_tmp2, 1 << _LM_BIT_CLK
	out _LM_PORT, _ds_tmp2
	andi _ds_tmp2, ~(1 << _LM_BIT_CLK)
	out _LM_PORT, _ds_tmp2
	;loop
	dec _ds_tmp1
	brne _lm_l_src_send_col_row
	;send LAT
	ldi _ds_tmp2, (1 << _LM_BIT_G) | (1 << _LM_BIT_LAT)
	out _LM_PORT, _ds_tmp2
	ldi _ds_tmp2, (1 << _LM_BIT_G)
	out _LM_PORT, _ds_tmp2
	;send col
	or _ds_tmp2, _ds_ci
	out _LM_PORT, _ds_tmp2
	;end G
	out _LM_PORT, _ds_ci
.endmacro

#undef _ds_cdl
#undef _ds_cdh
#undef _ds_ci
#undef _ds_tmp1
#undef _ds_tmp2
