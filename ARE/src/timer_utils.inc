; Francesco Zoccheddu
; ARE
; Timer Utils

#ifndef INC_TIMUTILS
#define INC_TIMUTILS

#define TU_PSCL_0 0
#define TU_PSCL_1 1
#define TU_PSCL_2 8
#define TU_PSCL_3 64
#define TU_PSCL_4 256
#define TU_PSCL_5 1024

#define TU_CS_0 0
#define TU_CS_1 1
#define TU_CS_8 2
#define TU_CS_64 3
#define TU_CS_256 4
#define TU_CS_1024 5

#define TU_MS(s) (s / 1000.0)
#define TU_US(s) (s / 1000000.0)
#define TU_NS(s) (s / 1000000000.0)

#define TU_TOP(pscl, s) (s * FOSC / pscl)
#define TU_PSCL_OK(pscl, m, s) ((s * FOSC) < (pscl * m))
#define TU_CS_MIN(m, s) (TU_PSCL_OK(TU_PSCL_1, m, s) ? 1 : (TU_PSCL_OK(TU_PSCL_2, m, s) ? 2 : (TU_PSCL_OK(TU_PSCL_3, m, s) ? 3 : (TU_PSCL_OK(TU_PSCL_4, m, s) ? 4 : (TU_PSCL_OK(TU_PSCL_5, m, s) ? 5 : -1)))))
#define TU_PSCL_MIN(m, s) (TU_PSCL_OK(TU_PSCL_1, m, s) ? TU_PSCL_1 : (TU_PSCL_OK(TU_PSCL_2, m, s) ? TU_PSCL_2 : (TU_PSCL_OK(TU_PSCL_3, m, s) ? TU_PSCL_3 : (TU_PSCL_OK(TU_PSCL_4, m, s) ? TU_PSCL_4 : (TU_PSCL_OK(TU_PSCL_5, m, s) ? TU_PSCL_5 : -1)))))
#define TU_CS_MIN_8(s) TU_CS_MIN(255, s)
#define TU_CS_MIN_16(s) TU_CS_MIN(65535, s)
#define TU_PSCL_MIN_8(s) TU_PSCL_MIN(255, s)
#define TU_PSCL_MIN_16(s) TU_PSCL_MIN(65535, s)

#endif
