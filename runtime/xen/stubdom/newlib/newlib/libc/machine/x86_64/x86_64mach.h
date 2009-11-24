/*
 ** This file is distributed WITHOUT ANY WARRANTY; without even the implied
 ** warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 */

#ifndef __USER_LABEL_PREFIX__
#define __USER_LABEL_PREFIX__ _
#endif

#define __REG_PREFIX__ %

/* ANSI concatenation macros.  */

#define CONCAT1(a, b) CONCAT2(a, b)
#define CONCAT2(a, b) a##b

/* Use the right prefix for global labels.  */

#define SYM(x) CONCAT1(__USER_LABEL_PREFIX__, x)

/* Use the right prefix for registers.  */

#define REG(x) CONCAT1(__REG_PREFIX__, x)

#define rax %rax
#define rbx %rbx
#define rcx %rcx
#define rdx %rdx
#define rsi %rsi
#define rdi %rdi
#define rbp %rbp
#define rsp %rsp

#define r8  %r8
#define r9  %r9
#define r10 %r10
#define r11 %r11
#define r12 %r12
#define r13 %r13
#define r14 %r14
#define r15 %r15

#define eax %eax
#define ebx %ebx
#define ecx %ecx
#define edx %edx
#define esi %esi
#define edi %edi
#define ebp %ebp
#define esp %esp

#define st0 %st
#define st1 %st(1)
#define st2 %st(2)
#define st3 %st(3)
#define st4 %st(4)
#define st5 %st(5)
#define st6 %st(6)
#define st7 %st(7)

#define ax %ax
#define bx %bx
#define cx %cx
#define dx %dx

#define ah %ah
#define bh %bh
#define ch %ch
#define dh %dh

#define al %al
#define bl %bl
#define cl %cl
#define dl %dl

#define sil %sil

#define mm1 %mm1
#define mm2 %mm2
#define mm3 %mm3
#define mm4 %mm4
#define mm5 %mm5
#define mm6 %mm6
#define mm7 %mm7

#define xmm0 %xmm0
#define xmm1 %xmm1
#define xmm2 %xmm2
#define xmm3 %xmm3
#define xmm4 %xmm4
#define xmm5 %xmm5
#define xmm6 %xmm6
#define xmm7 %xmm7

#define cr0 %cr0
#define cr1 %cr1
#define cr2 %cr2
#define cr3 %cr3
#define cr4 %cr4

#ifdef _I386MACH_NEED_SOTYPE_FUNCTION
#define SOTYPE_FUNCTION(sym) .type SYM(sym),@function
#else
#define SOTYPE_FUNCTION(sym)
#endif

#ifdef _I386MACH_ALLOW_HW_INTERRUPTS
#define        __CLI
#define        __STI
#else
#define __CLI  cli
#define __STI  sti
#endif
