.ifndef INC_DSENS
.equ INC_DSENS = 0

.equ DSENS_OCA_ADDR = OC1Aaddr

.org DSENS_OCA_ADDR
rjmp dsens_isr_oca

.equ DSENS_ECHO_ADDR_L = INT0addr

.org DSENS_ECHO_ADDR_L
rjmp dsens_isr_echo_l

.equ DSENS_ECHO_ADDR_R = INT1addr

.org DSENS_ECHO_ADDR_R
rjmp dsens_isr_echo_r

.endif
