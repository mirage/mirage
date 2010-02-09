#include <setjmp.h>
#include "dietwarning.h"

.text
.global __longjmp
.type __longjmp,@function
__longjmp:
	mov	$1,%eax
	/* Restore the return address now.  */
	movq	 (JB_PC*8)(%rdi),%rdx
	/* Restore registers. */
	movq	(JB_RBX*8)(%rdi),%rbx
	movq	(JB_RBP*8)(%rdi),%rbp
	movq	(JB_R12*8)(%rdi),%r12
	movq	(JB_R13*8)(%rdi),%r13
	movq	(JB_R14*8)(%rdi),%r14
	movq	(JB_R15*8)(%rdi),%r15
	movq	(JB_RSP*8)(%rdi),%rsp
	/* never return 0 */
	test	%esi,%esi
	cmovne	%esi,%eax
	/* Jump to saved PC.  */
	jmp	*%rdx
.size __longjmp,.-__longjmp;

link_warning("__longjmp","longjmp() not yet tested")
