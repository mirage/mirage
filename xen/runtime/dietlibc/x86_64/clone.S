#include "syscalls.h"
#include <errno.h>
#include "dietwarning.h"

.text
.type clone,@function
.weak clone
clone:
.type __clone,@function
.global __clone
__clone:
	movl	$-EINVAL,%eax
	testq	%rdi,%rdi	/* have non null thread_funcion */
	jz	.Lclone_error
	testq	%rsi,%rsi	/* have non null child_stack pointer */
	jz	.Lclone_error

	/* put the parameters on thread stack */
	subq	$16,%rsi
	movq	%rcx,8(%rsi)	/* thread parameter */
	movq	%rdi,0(%rsi)	/* thread function */

	/* syscall */
	movq	%rdx,%rdi
	movl	$__NR_clone,%eax
	syscall
	cmpl	$0,%eax
	jl	.Lclone_error
	jne	.Lreturn

.thread_start:
	/* call thread function */
	popq	%rax
	popq	%rdi
	call	*%rax
	/* exit a thread */
	movq	%rax,%rdi
#ifdef __PIC__
	jmp	_exit@PLT
#else
	jmp	_exit
#endif

.Lclone_error:
	/* set errno */
	negl	%eax
	pushq	%rax
#ifdef __PIC__
	call	__errno_location@PLT
#else
	call	__errno_location
#endif
	popq	%rcx
	movl	%ecx,(%rax)
	orq	$-1, %rax

.Lreturn:
	/* just return */
	ret

link_warning("clone", "warning: clone() not yet tested")
link_warning("__clone", "warning: clone() not yet tested")
//link_warning("clone", "warning: clone() not yet implemented")
//link_warning("__clone", "warning: clone() not yet implemented")
