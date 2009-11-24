! C run time start off

! This file supports:
!
! - both 32bit pointer and 64bit pointer environments (at compile time)
! - an imposed stack bias (of 2047) (at run time)
! - medium/low and medium/anywhere code models (at run time)

! Initial stack setup:
!
!    bottom of stack (higher memory address)
! 	...
!	text of environment strings
!	text of argument strings
!	envp[envc] = 0 (4/8 bytes)
!	...
!	env[0] (4/8 bytes)
!	argv[argc] = 0 (4/8 bytes)
!	...
!	argv[0] (4/8 bytes)
!	argc (4/8 bytes)
!	register save area (64 bits by 16 registers = 128 bytes)
!	top of stack (%sp)

! Stack Bias:
!
! It is the responsibility of the o/s to set this up.
! We handle both a 0 and 2047 value for the stack bias.

! Medium/Anywhere code model support:
!
! In this model %g4 points to the start of the data segment.
! The text segment can go anywhere, but %g4 points to the *data* segment.
! It is up to the compiler/linker to get this right.
!
! Since this model is statically linked the start of the data segment
! is known at link time.  Eg:
!
!	sethi	%hh(data_start), %g1
!	sethi	%lm(data_start), %g4
!	or	%g1, %hm(data_start), %g1
!	or	%g4, %lo(data_start), %g4
!	sllx	%g1, 32, %g1
!	or	%g4, %g1, %g4
!
! FIXME: For now we just assume 0.

! FIXME: if %g1 contains a non-zero value, atexit() should be invoked
! with this value.

#include "syscallasm.h"

#ifndef TARGET_PTR_SIZE
#define TARGET_PTR_SIZE 32
#endif

	TEXT_SECTION
	ALIGN (4)
	GLOBAL (ASM_PRIVATE_SYMBOL (start))
ASM_PRIVATE_SYMBOL (start):
	clr	%fp

! We use %g4 even if the code model is Medium/Low (simplifies the code).

	clr	%g4			! Medium/Anywhere base reg

! If there is a stack bias in effect, account for it in %g5.  Then always
! add %g5 to stack references below.  This way the code can be used with
! or without an imposed bias.

	andcc	%sp, 1, %g5
	bnz,a	.LHaveBias
	mov	2047, %g5
.LHaveBias:
	add	%sp, %g5, %sp

#if TARGET_PTR_SIZE == 32
	! FIXME: We apparently assume here that there is no reserved word.
	! This is probably correct, but try to verify it.
	ld	[%sp + 0x80], %o0	! argc
	add	%sp, 0x84, %o1		! argv
	add	%o0, 1, %o2
	sll	%o2, 2, %o2
#else /* TARGET_PTR_SIZE == 64 */
	ld	[%sp + 0x8c], %o0	! argc.lo
	add	%sp, 0x90, %o1		! argv
	add	%o0, 1, %o2
	sll	%o2, 3, %o2
#endif
	add	%o1, %o2, %o2		! envp
	sethi	%hi (ASM_SYMBOL (environ)), %o3
	or	%o3, %lo (ASM_SYMBOL (environ)), %o3
#if TARGET_PTR_SIZE == 32
	st	%o2, [%o3 + %g4]
#else /* TARGET_PTR_SIZE == 64 */
	stx	%o2, [%o3 + %g4]
#endif

! Restore any stack bias before we call main() ...

	sub	%sp, %g5, %sp

	GLOBAL (ASM_SYMBOL (main))
	call	ASM_SYMBOL (main)

! FIXME: Not sure if this is needed anymore.
#if TARGET_PTR_SIZE == 32
	sub	%sp, 0x20, %sp		! room to push args
#else /* TARGET_PTR_SIZE == 64 */
	sub	%sp, 0x30, %sp		! room to push args
#endif

	GLOBAL (ASM_SYMBOL (exit))
	call	ASM_SYMBOL (exit)
	nop

	GLOBAL (ASM_SYMBOL (_exit))
	call	ASM_SYMBOL (_exit)
	nop

	set	SYS_exit, %g1
	ta	SYSCALL_TRAP		! in case user redefines __exit

! If all the above methods fail to terminate the program, try an illegal insn.
! If that does not work, the o/s is hosed more than we are.

	WORD (0)
