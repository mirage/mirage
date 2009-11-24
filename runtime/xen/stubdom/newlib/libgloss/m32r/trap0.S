; Trap 0 handler (syscall interface).
;
; The trap handler returns the result in r0 and the error code (errno value)
; in r2.  r1 is reserved in case an 8 byte quantity ever needs to be
; returned in registers.

	.text
	.global	__trap0
__trap0:
	trap	#0		; trap 0 returns result in r0, error code in r2
	cmpui	r2,#1		; is error code zero?
	bc	.Lret		; yes, skip setting errno
	ld	r4,@(sp)	; no, set errno
	st	r2,@r4
.Lret:
	jmp	lr		; return to caller
