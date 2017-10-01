; Francesco Zoccheddu
; ARE
; builtin LED
; dirty PORTB, DDRB, PINB

#define _BL_IO B

IO_DEF _BL, _BL_IO
#define _BL_BIT 7

#define _BL_BACKUP_EXTRA_PINS 0

#define _bl_tmp @0

; [SOURCE] setup
; @0 (dirty immediate register)
.macro BL_SRC_SETUP
	; set data direction register to output for LED pin
	#if _BL_BACKUP_EXTRA_PINS
		in _bl_tmp, _BL_DDR
		ori _bl_tmp, 1 << _BL_BIT
	#else
		ldi _bl_tmp, 1 << _BL_BIT
	#endif
	out _BL_DDR, _bl_tmp
.endmacro

; [SOURCE] turn builtin LED on
; @0 (dirty immediate register)
.macro BL_SRC_ON
	#if _BL_BACKUP_EXTRA_PINS
		in _bl_tmp, _BL_PORT
		ori _bl_tmp, 1 << _BL_BIT
	#else
		ldi _bl_tmp, 1 << _BL_BIT
	#endif
	out _BL_PORT, _bl_tmp
.endmacro

; [SOURCE] turn builtin LED off
; @0 (dirty immediate register)
.macro BL_SRC_OFF
	#if _BL_BACKUP_EXTRA_PINS
		in _bl_tmp, _BL_PORT
		andi _bl_tmp, ~(1 << _BL_BIT)
	#else
		clr _bl_tmp
	#endif
	out _BL_PORT, _bl_tmp
.endmacro

; [SOURCE] toggle builtin LED state
; @0 (dirty immediate register)
.macro BL_SRC_TOGGLE
	ldi _bl_tmp, 1 << _BL_BIT
	out _BL_PIN, _bl_tmp
.endmacro

#undef _bl_tmp
