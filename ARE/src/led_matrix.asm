; Francesco Zoccheddu
; ARE
; LED matrix
; dirty PORTC, DDRC, PINC

.equ LM_PORT = PORTC
.equ LM_DDR = DDRC
.equ LM_BIT_ABCD = 0 ;digital pin 34-37
.equ LM_BIT_G = 4 ;digital pin 33
.equ LM_BIT_DI = 5 ;digital pin 32
.equ LM_BIT_CLK = 6 ;digital pin 31
.equ LM_BIT_LAT = 7 ;digital pin 30

; [SOURCE] setup
; @0 (dirty immediate register)
.macro LM_SRC_SETUP
	ser @0
	out LM_DDR, @0
.endmacro

; [SOURCE] send column data '@0:@1' with column index '@2' 
; @0 (column data high register)
; @1 (column data low register)
; @2 (column index register)
; @3 (dirty immediate register)
; @4 (dirty immediate register)
.macro LM_SRC_SEND_COL
	ldi @3, 16
	;row
	ldi @4, (1 << LM_BIT_G) | (1 << LM_BIT_DI)
	lsr @0
	ror @1
	brcc PC + 2
	ldi @4, (1 << LM_BIT_G)
	out LM_PORT, @4
	ori @4, 1 << LM_BIT_CLK
	out LM_PORT, @4
	andi @4, ~(1 << LM_BIT_CLK)
	out LM_PORT, @4
	;loop
	dec @3
	brne PC - 11
	;send LAT
	ldi @4, (1 << LM_BIT_G) | (1 << LM_BIT_LAT)
	out LM_PORT, @4
	ldi @4, (1 << LM_BIT_G)
	out LM_PORT, @4
	;send col
	or @4, @2
	out LM_PORT, @4
	;end G
	out LM_PORT, @2
.endmacro


