! Set errno.
! This function is called by all the syscall stubs.
!
! FIXME: We assume errno is the first member of struct _reent.
! Not sure what to do about this.

#include "syscallasm.h"

	DATA_SECTION
	ALIGN (4)
	GLOBAL (ASM_SYMBOL (errno))	! FIXME: ASM_PRIVATE_SYMBOL ?
ASM_SYMBOL (errno):
	WORD (0)

	TEXT_SECTION
	ALIGN (4)

	GLOBAL (ASM_PRIVATE_SYMBOL (cerror))
ASM_PRIVATE_SYMBOL (cerror):
	sethi	%hi (ASM_SYMBOL (errno)),%g1
	st	%o0,[%g1+%lo (ASM_SYMBOL (errno))]
	jmpl	%o7+8,%g0
	mov	-1,%o0

	GLOBAL (ASM_PRIVATE_SYMBOL (cerror_r))
ASM_PRIVATE_SYMBOL (cerror_r):
	st	%o0,[%o1]
	jmpl	%o7+8,%g0
	mov	-1,%o0

! Since all system calls need this file, we put various state globals
! here as well.

	DATA_SECTION

! CURBRK contains the current top of allocated space.
! END is a private symbol in svr4, but a public one in sunos4.
! FIXME: CURBRK is 4 bytes for now.

	ALIGN (4)
	GLOBAL (ASM_PRIVATE_SYMBOL (curbrk))
ASM_PRIVATE_SYMBOL (curbrk):
#ifdef SVR4
	WORD (ASM_PRIVATE_SYMBOL (end))
#else
	WORD (ASM_SYMBOL (end))
#endif
