; Francesco Zoccheddu
; ARE
; utils

#ifndef _INC_UTILS
#define _INC_UTILS

; [SOURCE] stack setup
; @0 (dirty immediate register)
.macro STACK_SETUP
	ldi @0, HIGH(RAMEND)
	out SPH, @0
	ldi @0, LOW(RAMEND)
	out SPL, @0
.endmacro

; define 16 bit register H / L macros
; @0 (name)
; @1 (value)
.macro _U_16R_DEF
	.equ @0H = @1H
	.equ @0L = @1L
.endmacro

; define ISR for interrupt address '@0'
; @0 (interrupt vector address)
.macro ISR
	.set ISR_PC = PC
	.org @0
		jmp ISR_PC
	.org ISR_PC
.endmacro

; define ISR entry '@1' for interrupt address '@0'
; @0 (interrupt vector address)
; @1 (ISR entry label)
.macro ISRJ
	.set ISR_PC = PC
	.org @0
		jmp @1
	.org ISR_PC
.endmacro

; timer

#define _TPSCL_0 0
#define _TPSCL_1 1
#define _TPSCL_2 8
#define _TPSCL_3 64
#define _TPSCL_4 256
#define _TPSCL_5 1024

#define _TCS_0 0
#define _TCS_1 1
#define _TCS_8 2
#define _TCS_64 3
#define _TCS_256 4
#define _TCS_1024 5

#define TMS(s) (s / 1000.0)
#define TUS(s) (s / 1000000.0)
#define TNS(s) (s / 1000000000.0)

#define TTOP(pscl, s) (s * FOSC / pscl)
#define _TPSCL_OK(pscl, m, s) ((s * FOSC) < (pscl * m))
#define _TPSCL_MIN(m, s) (_TPSCL_OK(_TPSCL_1, m, s) ? _TPSCL_1 : (_TPSCL_OK(_TPSCL_2, m, s) ? _TPSCL_2 : (_TPSCL_OK(_TPSCL_3, m, s) ? _TPSCL_3 : (_TPSCL_OK(_TPSCL_4, m, s) ? _TPSCL_4 : (_TPSCL_OK(_TPSCL_5, m, s) ? _TPSCL_5 : -1)))))
#define TPSCL_MIN_8(s) _TPSCL_MIN(255, s)
#define TPSCL_MIN_16(s) _TPSCL_MIN(65535, s)
#define _TCS_MIN(m, s) (_TPSCL_OK(_TPSCL_1, m, s) ? 1 : (_TPSCL_OK(_TPSCL_2, m, s) ? 2 : (_TPSCL_OK(_TPSCL_3, m, s) ? 3 : (_TPSCL_OK(_TPSCL_4, m, s) ? 4 : (_TPSCL_OK(_TPSCL_5, m, s) ? 5 : -1)))))
#define TCS_MIN_8(s) _TCS_MIN(255, s)
#define TCS_MIN_16(s) _TCS_MIN(65535, s)

#define TCCRA_VAL(wgm, coma, comb, comc) ((coma << 6) | (comb << 4) | (comc << 2) | (wgm & 0b11))
#define TCCRB_VAL(cs, wgm, ices, icn) ((icn << 7) | (ices << 6) | ((wgm >> 2) << 3) | cs)
#define TCCRC_VAL(foca, focb, focc) ((foca << 7) | (focb << 6) | (focc << 5))
#define TIMSK_VAL(toie, icie, ociea, ocieb, ociec) ((icie << 5) | (ociec << 3) | (ocieb << 2) | (ociea << 1) | toie)
#define TIFR_VAL(tov, icf, ocfa, ocfb, ocfc) ((icf << 5) | (ocfc << 3) | (ocfb << 2) | (ocfa << 1) | tov)

; define timer macros
; @0 (prefix)
; @1 (timer index)
.macro TIM_DEF
	.if (@1 != 0) && (@1 != 1) && (@1 != 2) && (@1 != 3) && (@1 != 4) && (@1 != 5) 
		.error "Bad timer index"
	.else
		.equ @0_TCCRA = TCCR@1A
		.equ @0_TCCRB = TCCR@1B
		.equ @0_TIMSK = TIMSK@1
		.equ @0_TIFR = TIFR@1
		.equ @0_OCAaddr = OC@1Aaddr
		.equ @0_OCBaddr = OC@1Baddr
		.equ @0_OVFaddr = OVF@1addr
		.if (@1 == 0) || (@1 == 2)
			.equ @0_TCNT = TCNT@1
			.equ @0_OCRA = OCR@1A
			.equ @0_OCRB = OCR@1B
		.else
			.equ @0_TCCRC = TCCR@1C
			.equ @0_OCCaddr = OC@1Caddr
			_U_16R_DEF @0_ICR, ICR@1
			_U_16R_DEF @0_TCNT, TCNT@1
			_U_16R_DEF @0_OCRA, OCR@1A
			_U_16R_DEF @0_OCRB, OCR@1B
			_U_16R_DEF @0_OCRC, OCR@1C
		.endif
	.endif
.endmacro

; IO

; define IO macros
; @0 (prefix)
; @1 (IO letter)
.macro IO_DEF
	.equ @0_PIN = PIN@1
	.equ @0_PORT = PORT@1
	.equ @0_DDR = DDR@1
.endmacro

#endif
