! This file is called sigsetjmp.s because that is what V8 uses.
! We do not define sigsetjmp() or setlongjmp() yet.
! Solaris has setjmp/longjmp in setjmp.o.  Move this stuff there.

#include <sys/syscallasm.h>

	TEXT_SECTION
	ALIGN (4)

#ifdef __svr4__

	GLOBAL (ASM_SYMBOL (setjmp))
	.proc	04
ASM_SYMBOL (setjmp):

	clr	[%o0]
	stx	%sp,[%o0+8]
	add	%o7,8,%g1
	stx	%g1,[%o0+16]
	retl 
	mov	%g0,%o0

	GLOBAL (ASM_SYMBOL (longjmp))
	.proc	04
ASM_SYMBOL (longjmp):

	flushw				! flush register windows
	sub	%sp,136,%sp
	ldx	[%o0+8],%fp
	ldx	[%o0+16],%g1
	tst	%o1
	bne	L0
	sub	%g1,8,%o7
	mov	1,%o1
L0:
	retl 
	restore	%o1,0,%o0

#else

	GLOBAL (ASM_SYMBOL (setjmp))
	.proc	04
ASM_SYMBOL (setjmp):
	save	%sp,-136,%sp
	or	%g0,%g0,%o0		! %o0 = 0
	or	%g0,0x6d,%g1		! %g1 = 0x6d (syscall number)
	ta	SYSCALL_TRAP
	stw	%o0,[%i0+4]		! save result at [%i0+4] (sigmask?)
	add	%fp,-8,%o1		! %o1 -> tmp 8 byte buffer
	or	%g0,%g0,%o0		! %o0 = 0
	or	%g0,0x70,%g1		! %g1 = 0x70 (syscall number)
	ta	SYSCALL_TRAP
	lduw	[%fp-4],%g1		! %g1 = onsstack?
	stw	%fp,[%i0+8]		! save %fp at [%i0+8]
	stw	%g1,[%i0+0]		! save ? at [%i0+8]
	add	%i7,8,%g1		! %g1 = return address
	stw	%g1,[%i0+12]		! save return address at [%i0+12]
	add	%g1,4,%g1		! %g1 = nPC
	stw	%g1,[%i0+16]		! save nPC at [%i0+16]
	stw	%g0,[%i0+20]
	stw	%g0,[%i0+24]
	stw	%g0,[%i0+32]
	jmpl	%i7+8,%g0
	restore	%g0,0,%o0

	GLOBAL (ASM_SYMBOL (longjmp))
	.proc	04
ASM_SYMBOL (longjmp):
	orcc	%g0,%o1,%g0		! return val == 0 ?
	be,a	L1			! branch if 0
	or	%g0,1,%o1		! make it 1 (executed if branch taken)
L1:
	or	%g0,0x8b,%g1		! set syscall 0x8b
	stw	%o1,[%o0+28]		! save return val for restoration
	ta	SYSCALL_TRAP

#endif /* ! __svr4__ */
