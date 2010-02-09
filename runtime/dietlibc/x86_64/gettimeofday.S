.text
.global gettimeofday
.type gettimeofday,@function
gettimeofday:
	mov	$0xffffffffff600000,%rax
	callq	*%rax
	cmpq	$-128, %rax
	jbe	1f
	negl	%eax
	pushq	%rax
	call	__errno_location
	popq	%rcx
	movl	%ecx,(%rax)
	orq	$-1, %rax
1:
	ret
.Lhere:
	.size	 gettimeofday,.Lhere-gettimeofday
