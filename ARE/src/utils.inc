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

#define COMA 6
#define COMA_MSK(x) (x & 0b11)
#define COMA_VAL(x) (COMA_MSK(x) << COMA)
#define COMB 4
#define COMB_MSK(x) (x & 0b11)
#define COMB_VAL(x) (COMB_MSK(x) << COMB)
#define COMC 2
#define COMC_MSK(x) (x & 0b11)
#define COMC_VAL(x) (COMC_MSK(x) << COMC)
#define WGMA 0
#define WGMA_MSK(x) (x & 0b11)
#define WGMA_VAL(x) (WGMA_MSK(x) << WGMA)
#define WGMB 3
#define WGMB_MSK(x) (x >> 2)
#define WGMB_VAL(x) (WGMB_MSK(x) << WGMB)
#define CS 0
#define CS_MSK(x) (x & 0b111)
#define CS_VAL(x) (CS_MSK(x) << CS)
#define ICN 7
#define ICES 6
#define FOCA 7
#define FOCB 6
#define FOCC 5
#define ICIE 5
#define OCIEC 3
#define OCIEB 2
#define OCIEA 1
#define TOIE 0
#define ICF 5
#define OCFC 3
#define OCFB 2
#define OCFA 1
#define TOV 0
#define ICN_VAL (1 << 7)
#define ICES_VAL (1 << 6)
#define FOCA_VAL (1 << 7)
#define FOCB_VAL (1 << 6)
#define FOCC_VAL (1 << 5)
#define ICIE_VAL (1 << 5)
#define OCIEC_VAL (1 << 3)
#define OCIEB_VAL (1 << 2)
#define OCIEA_VAL (1 << 1)
#define TOIE_VAL (1 << 0)
#define ICF_VAL (1 << 5)
#define OCFC_VAL (1 << 3)
#define OCFB_VAL (1 << 2)
#define OCFA_VAL (1 << 1)
#define TOV_VAL (1 << 0)



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
			.equ @0_ICPaddr = ICP@1addr
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
