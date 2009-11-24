! _exit() system call

#include "syscallasm.h"

	TEXT_SECTION
	ALIGN (4)
	GLOBAL (ASM_SYMBOL (_exit))
ASM_SYMBOL (_exit):
	mov	SYS_exit,%g1
	ta	SYSCALL_TRAP

! If that returns (yikes!), try an illegal insn ...

	WORD (0)