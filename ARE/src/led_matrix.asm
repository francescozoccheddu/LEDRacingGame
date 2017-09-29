; Francesco Zoccheddu
; ARE
; LED matrix

.equ LM_PORT = PORTC
.equ LM_DDR = DDRC
.equ LM_BIT_ABCD = 0 ;digital pin 34-37
.equ LM_BIT_G = 4 ;digital pin 33
.equ LM_BIT_DI = 5 ;digital pin 32
.equ LM_BIT_CLK = 6 ;digital pin 31
.equ LM_BIT_LAT = 7 ;digital pin 30

; @0 (dirty immediate register)
.macro LM_SRC_SETUP
	ser @0
	out LM_DDR, @0
.endmacro

; @0 (dirty immediate register)
; @1 (dirty immediate register)
; @2 (column data high register)
; @3 (column data low register)
; @4 (column index register)
.macro LM_SRC_SEND_COL
	ldi @0, 16
	;row
	ldi @1, (1 << LM_BIT_G) | (1 << LM_BIT_DI)
	lsr @2
	ror @3
	brcc PC + 2
	ldi @1, (1 << LM_BIT_G)
	out LM_PORT, @1
	ori @1, 1 << LM_BIT_CLK
	out LM_PORT, @1
	andi @1, ~(1 << LM_BIT_CLK)
	out LM_PORT, @1
	;loop
	dec @0
	brne PC - 11
	;send LAT
	ldi @1, (1 << LM_BIT_G) | (1 << LM_BIT_LAT)
	out LM_PORT, @1
	ldi @1, (1 << LM_BIT_G)
	out LM_PORT, @1
	;send col
	or @1, @4
	out LM_PORT, @1
	;end G
	out LM_PORT, @4
.endmacro


