! wait() "system" call
! It is really not a system call as it uses wait4().

#include "sys/syscallasm.h"

	TEXT_SECTION
	ALIGN (4)

#ifdef REENT

	GLOBAL (ASM_SYMBOL (_wait_r))
ASM_SYMBOL (_wait_r):
	save	%sp,-136,%sp
	clr	%o1
	mov	%i1,%o2
	clr	%o3
	call	ASM_SYMBOL (_wait4_r)
	clr	%o4
	jmpl	%i7+8,%g0
	restore	%g0,%o0,%o0

#else /* ! REENT */

	GLOBAL (ASM_SYMBOL (wait))
ASM_SYMBOL (wait):
	save	%sp,-136,%sp
	clr	%o0
	mov	%i0,%o1
	clr	%o2
	call	ASM_SYMBOL (wait4)
	clr	%o3
	jmpl	%i7+8,%g0
	restore	%g0,%o0,%o0

#endif /* ! REENT */
