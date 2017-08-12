.ifdef INC_DEFS
	.exit
.endif
.equ INC_DEFS = 0

;device defs

.include "m2560def.inc"

;configuration defs

.equ FOSC = 16000000
.equ RESET_ADDR = 0

