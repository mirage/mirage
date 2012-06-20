.text
.global strcmp
.type	strcmp,@function
.weak	strcoll
.type	strcoll,@function

strcoll:
strcmp:
.Lloop:
	mov (%rdi),%al
	cmp (%rsi),%al
	jnz .Lmismatch
	inc %rsi
	inc %rdi
	or %al,%al
	jnz .Lloop
	/* end of string reached, return NULL */
	xor %eax,%eax
	ret
.Lmismatch:
/* In the C version we return (unsigned char)*b-(unsigned char)*a
   but in assembler it is less trouble to return 1 or -1
   depending on whether the carry flag is set.
   The standard only wants positive, zero, or negative, so both are OK */
	sbb %eax,%eax
	or $1,%eax
	ret
