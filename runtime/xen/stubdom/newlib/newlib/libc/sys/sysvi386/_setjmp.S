/
/ our buffer looks like:
/  eax,ebx,ecx,edx,esi,edi,esp,ebp,pc

	.globl	_setjmp
	.globl	setjmp
_setjmp:
setjmp:
	pushl	%ebx
	movl	8(%esp), %ebx
	movl	%eax, (%ebx)
	popl	%eax
	movl	%eax, 4(%ebx)
	movl	%ecx, 8(%ebx)
	movl	%edx, 12(%ebx)
	movl	%esi, 16(%ebx)
	movl	%edi, 20(%ebx)
	movl	%esp, 24(%ebx)
	movl	%ebp, 28(%ebx)
	movl	(%esp), %eax
	movl	%eax, 32(%ebx)
	xorl	%eax, %eax
	ret

