! execve.S
! This function is invoked by the other exec*() fns.
!
! If sizeof(char *) == 64, we invoke a new Shade function until the real one
! is defined.

#include "sys/syscallasm.h"

	TEXT_SECTION
	ALIGN (4)
	GLOBAL (ASM_SYMBOL (execve))
ASM_SYMBOL (execve):
	mov	SYS_execve,%g1
#if TARGET_PTR_SIZE == 64
	ta	42
#else
	ta	SYSCALL_TRAP
#endif

	bcc	noerr
	nop

	seterrno()

noerr:
	jmpl	%o7+8,%g0
	nop
