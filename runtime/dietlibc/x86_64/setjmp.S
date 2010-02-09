#include <setjmp.h>
#include "dietwarning.h"

.text
.weak setjmp
.type setjmp,@function
setjmp:
.globl __setjmp
.type __setjmp,@function
__setjmp:
	xorq	%rsi,%rsi

.globl __sigsetjmp
.type __sigsetjmp,@function
__sigsetjmp:
	movq	%rbx,(JB_RBX*8)(%rdi)
	movq	%rbp,(JB_RBP*8)(%rdi)
	movq	%r12,(JB_R12*8)(%rdi)
	movq	%r13,(JB_R13*8)(%rdi)
	movq	%r14,(JB_R14*8)(%rdi)
	movq	%r15,(JB_R15*8)(%rdi)
	leaq	8(%rsp),%rdx
	movq	%rdx,(JB_RSP*8)(%rdi)
	movq	(%rsp),%rdx
	movq	%rdx,(JB_PC*8)(%rdi)
#ifdef	__PIC__
	jmp	__sigjmp_save@PLT
#else
	jmp	__sigjmp_save
#endif
.size __sigsetjmp,.-__sigsetjmp;

link_warning("setjmp","setjmp() not yet tested")
link_warning("__sigsetjmp","setjmp() not yet tested")
//link_warning("setjmp","error: setjmp() not yet implemented")
//link_warning("__sigsetjmp","error: setjmp() not yet implemented")

