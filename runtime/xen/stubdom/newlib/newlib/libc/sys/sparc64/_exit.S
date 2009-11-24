! _exit() system call

#include "sys/syscallasm.h"

	TEXT_SECTION
	ALIGN (4)
	GLOBAL (ASM_SYMBOL (_exit))
ASM_SYMBOL (_exit):
	mov	SYS_exit,%g1
	ta	%icc,SYSCALL_TRAP

! If that returns (yikes!), try an illegal insn ...

	WORD (0)