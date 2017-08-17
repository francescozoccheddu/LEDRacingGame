#ifdef MACROS
;################# MACROS #################

	.equ TIMUTILS_PSCL_1 = 1
	.equ TIMUTILS_PSCL_2 = 8
	.equ TIMUTILS_PSCL_3 = 64
	.equ TIMUTILS_PSCL_4 = 256
	.equ TIMUTILS_PSCL_5 = 1024

;params (0)'time sec' (1)'timer bits' (2)'equ export name'
.macro TIMUTILS_M_PSCL
	.if ( (@0) * FOSC < ((1 << (@1)) * TIMUTILS_PSCL_1) )
		.equ @2 = TIMUTILS_PSCL_1
	.elif ( (@0) * FOSC < ((1 << (@1)) * TIMUTILS_PSCL_2) )
		.equ @2 = TIMUTILS_PSCL_2
	.elif ( (@0) * FOSC < ((1 << (@1)) * TIMUTILS_PSCL_3) )
		.equ @2 = TIMUTILS_PSCL_3
	.elif ( (@0) * FOSC < ((1 << (@1)) * TIMUTILS_PSCL_4) )
		.equ @2 = TIMUTILS_PSCL_4
	.elif ( (@0) * FOSC < ((1 << (@1)) * TIMUTILS_PSCL_5) )
		.equ @2 = TIMUTILS_PSCL_5
	.else
		.error "Too long time for timer"
	.endif
.endmacro


;params (0)'prescaler' (1)'equ export name'
.macro TIMUTILS_M_CS
	.if ( (@0) == TIMUTILS_PSCL_1 )
		.equ @1 = 1
	.elif ( (@0) == TIMUTILS_PSCL_2 )
		.equ @1 = 2
	.elif ( (@0) == TIMUTILS_PSCL_3 )
		.equ @1 = 3
	.elif ( (@0) == TIMUTILS_PSCL_4 )
		.equ @1 = 4
	.elif ( (@0) == TIMUTILS_PSCL_5 )
		.equ @1 = 5
	.else
		.error "Wrong prescaler value"
	.endif
.endmacro

;params (0)'prescaler' (1)'time sec' (2)'export name'
.macro TIMUTILS_M_TOP
	.equ @2 = INT( (FOSC / (@0)) * (@1) )
.endmacro

;##########################################
#endif
