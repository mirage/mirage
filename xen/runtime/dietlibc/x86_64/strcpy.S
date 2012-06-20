.text
.align 0
.global strcpy
.type	 strcpy,@function
strcpy:
	mov %rdi,%rdx

.Lloop:
	lodsb
	test %al, %al
	stosb
	jnz .Lloop

	mov %rdx,%rax
	ret
