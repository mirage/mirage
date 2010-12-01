.text
.global strlen
.type strlen,@function
strlen:
        mov %rdi,%rax
        mov %edi,%ecx
        pxor %xmm0,%xmm0
        and $15,%ecx
        and $-16,%rax
        movdqa (%rax),%xmm1
        pcmpeqb %xmm0,%xmm1
        pmovmskb %xmm1,%edx
        shr %cl,%edx
        shl %cl,%edx
        test %edx,%edx
        jnz .L2
.L1:
        lea 16(%rax),%rax
        movdqa (%rax),%xmm1
        pcmpeqb %xmm0,%xmm1
        pmovmskb %xmm1,%edx
        test %edx,%edx
        jz .L1
.L2:
        sub %rax,%rdi
        bsf %edx,%eax
        sub %rdi,%rax
        ret

.Lhere:
        .size    strlen,.Lhere-strlen

