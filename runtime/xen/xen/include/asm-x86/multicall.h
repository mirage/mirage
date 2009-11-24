/******************************************************************************
 * asm-x86/multicall.h
 */

#ifndef __ASM_X86_MULTICALL_H__
#define __ASM_X86_MULTICALL_H__

#include <xen/errno.h>

#ifdef __x86_64__

#define do_multicall_call(_call)                             \
    do {                                                     \
        __asm__ __volatile__ (                               \
            "    movq  %c1(%0),%%rax; "                      \
            "    leaq  hypercall_table(%%rip),%%rdi; "       \
            "    cmpq  $("STR(NR_hypercalls)"),%%rax; "      \
            "    jae   2f; "                                 \
            "    movq  (%%rdi,%%rax,8),%%rax; "              \
            "    movq  %c2+0*%c3(%0),%%rdi; "                \
            "    movq  %c2+1*%c3(%0),%%rsi; "                \
            "    movq  %c2+2*%c3(%0),%%rdx; "                \
            "    movq  %c2+3*%c3(%0),%%rcx; "                \
            "    movq  %c2+4*%c3(%0),%%r8; "                 \
            "    callq *%%rax; "                             \
            "1:  movq  %%rax,%c4(%0)\n"                      \
            ".section .fixup,\"ax\"\n"                       \
            "2:  movq  $-"STR(ENOSYS)",%%rax\n"              \
            "    jmp   1b\n"                                 \
            ".previous\n"                                    \
            :                                                \
            : "b" (_call),                                   \
              "i" (offsetof(__typeof__(*_call), op)),        \
              "i" (offsetof(__typeof__(*_call), args)),      \
              "i" (sizeof(*(_call)->args)),                  \
              "i" (offsetof(__typeof__(*_call), result))     \
              /* all the caller-saves registers */           \
            : "rax", "rcx", "rdx", "rsi", "rdi",             \
              "r8",  "r9",  "r10", "r11" );                  \
    } while ( 0 )

#define compat_multicall_call(_call)                         \
        __asm__ __volatile__ (                               \
            "    movl  %c1(%0),%%eax; "                      \
            "    leaq  compat_hypercall_table(%%rip),%%rdi; "\
            "    cmpl  $("STR(NR_hypercalls)"),%%eax; "      \
            "    jae   2f; "                                 \
            "    movq  (%%rdi,%%rax,8),%%rax; "              \
            "    movl  %c2+0*%c3(%0),%%edi; "                \
            "    movl  %c2+1*%c3(%0),%%esi; "                \
            "    movl  %c2+2*%c3(%0),%%edx; "                \
            "    movl  %c2+3*%c3(%0),%%ecx; "                \
            "    movl  %c2+4*%c3(%0),%%r8d; "                \
            "    callq *%%rax; "                             \
            "1:  movl  %%eax,%c4(%0)\n"                      \
            ".section .fixup,\"ax\"\n"                       \
            "2:  movl  $-"STR(ENOSYS)",%%eax\n"              \
            "    jmp   1b\n"                                 \
            ".previous\n"                                    \
            :                                                \
            : "b" (_call),                                   \
              "i" (offsetof(__typeof__(*_call), op)),        \
              "i" (offsetof(__typeof__(*_call), args)),      \
              "i" (sizeof(*(_call)->args)),                  \
              "i" (offsetof(__typeof__(*_call), result))     \
              /* all the caller-saves registers */           \
            : "rax", "rcx", "rdx", "rsi", "rdi",             \
              "r8",  "r9",  "r10", "r11" )                   \

#else

#define do_multicall_call(_call)                             \
        __asm__ __volatile__ (                               \
            "    movl  %c1(%0),%%eax; "                      \
            "    pushl %c2+4*%c3(%0); "                      \
            "    pushl %c2+3*%c3(%0); "                      \
            "    pushl %c2+2*%c3(%0); "                      \
            "    pushl %c2+1*%c3(%0); "                      \
            "    pushl %c2+0*%c3(%0); "                      \
            "    cmpl  $("STR(NR_hypercalls)"),%%eax; "      \
            "    jae   2f; "                                 \
            "    call  *hypercall_table(,%%eax,4); "         \
            "1:  movl  %%eax,%c4(%0); "                      \
            "    addl  $20,%%esp\n"                          \
            ".section .fixup,\"ax\"\n"                       \
            "2:  movl  $-"STR(ENOSYS)",%%eax\n"              \
            "    jmp   1b\n"                                 \
            ".previous\n"                                    \
            :                                                \
            : "bSD" (_call),                                 \
              "i" (offsetof(__typeof__(*_call), op)),        \
              "i" (offsetof(__typeof__(*_call), args)),      \
              "i" (sizeof(*(_call)->args)),                  \
              "i" (offsetof(__typeof__(*_call), result))     \
              /* all the caller-saves registers */           \
            : "eax", "ecx", "edx" )                          \

#endif

#endif /* __ASM_X86_MULTICALL_H__ */
