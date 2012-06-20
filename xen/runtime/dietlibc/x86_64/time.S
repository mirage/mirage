/* implement time(2) via gettimeofday(2) on x86-64 because gettimeofday
   is a vsyscall (i.e. no actual switch to kernel mode) */
.text
.global time
.type time,@function
time:
	push    %rdi
	xor	%rsi,%rsi
	sub	$16,%rsp
	mov	%rsp,%rdi
	call	gettimeofday
	pop	%rax
	pop	%rdi
	pop	%rdi
	test	%rdi,%rdi
	jz	1f
	mov	%rax,(%rdi)
1:
	ret
.Lhere:
	.size	 time,.Lhere-time
