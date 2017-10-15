#ifndef _INC_LM
#define _INC_LM

; Francesco Zoccheddu
; ARE
; LED matrix
; dirty IO C

#include "utils.asm"

#define _LM_IO C

IO_DEF _LM, _LM_IO
#define _LM_BIT_ABCD 0 ; digital pin 34-37
#define _LM_BIT_G 4 ; digital pin 33
#define _LM_BIT_DI 5 ; digital pin 32
#define _LM_BIT_CLK 6 ; digital pin 31
#define _LM_BIT_LAT 7 ; digital pin 30

#define _lm_r_setup_tmp @0

; [SOURCE] setup
; @0 (dirty immediate register)
.macro LM_SRC_SETUP
	ser _lm_r_setup_tmp
	out _LM_DDR, _lm_r_setup_tmp
.endmacro

#undef _lm_r_setup_tmp

#define _lm_r_col @0
#define _lm_r_cl @1
#define _lm_r_ch @2
#define _lm_r_tmp1 @3
#define _lm_r_tmp2 @4

.macro LM_SRC_SENDCOL
	ldi _lm_r_tmp1, 16
_lm_l_src_send_col_row:
	ldi _lm_r_tmp2, (1 << _LM_BIT_G) | (1 << _LM_BIT_DI)
	lsr _lm_r_ch
	ror _lm_r_cl
	brcc _lm_l_src_send_col_out_dot
	ldi _lm_r_tmp2, (1 << _LM_BIT_G)
_lm_l_src_send_col_out_dot:
	out _LM_PORT, _lm_r_tmp2
	ori _lm_r_tmp2, 1 << _LM_BIT_CLK
	out _LM_PORT, _lm_r_tmp2
	andi _lm_r_tmp2, ~(1 << _LM_BIT_CLK)
	out _LM_PORT, _lm_r_tmp2
	;loop
	dec _lm_r_tmp1
	brne _lm_l_src_send_col_row
	;send LAT
	ldi _lm_r_tmp2, (1 << _LM_BIT_G) | (1 << _LM_BIT_LAT)
	out _LM_PORT, _lm_r_tmp2
	ldi _lm_r_tmp2, (1 << _LM_BIT_G)
	out _LM_PORT, _lm_r_tmp2
	;send col
	ldi _lm_r_tmp1, 15
	sub _lm_r_tmp1, _lm_r_col
	or _lm_r_tmp2, _lm_r_tmp1
	out _LM_PORT, _lm_r_tmp2
	;end G
	out _LM_PORT, _lm_r_tmp1
.endmacro

#undef _lm_r_cl
#undef _lm_r_ch
#undef _lm_r_col
#undef _lm_r_tmp1
#undef _lm_r_tmp2

#endif
