.text
.global memchr
.type memchr,@function
memchr:	/* rdi=ptr, esi=ch, rdx=len */
  and $0xff,%esi
  test %rdx,%rdx
  jz .Lnull		/* if (!len) return 0 */
  imul $0x1010101,%esi	/* esi = ch x 4 */

  mov %rdi,%rcx
  and $15,%ecx
  movd %esi,%xmm0
  lea (%rdi,%rdx),%rsi	/* rsi = max ptr */
  and $~15,%rdi		/* 16-align rdi, diff in cl */
  or $-1,%eax
  shl %cl,%eax

  pshufd $0,%xmm0,%xmm0	/* xmm0 = ch x 16 */
1:
  movdqa (%rdi),%xmm1
  pcmpeqb %xmm0,%xmm1
  pmovmskb %xmm1,%ecx
  and %eax,%ecx
  jnz .Lfound	/* found something */
  lea 16(%rdi),%rdi
  or $-1,%eax
  cmp %rsi,%rdi
  jb 1b
  jmp .Lnull
.Lfound:
  bsf %ecx,%eax
  add %rdi,%rax
  cmp %rsi,%rax
  ja .Lnull
  ret
.Lnull:
  xor %eax,%eax
  ret
.Lhere:
.size memchr,.Lhere-memchr
