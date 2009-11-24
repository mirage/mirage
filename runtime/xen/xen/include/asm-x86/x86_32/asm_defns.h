#ifndef __X86_32_ASM_DEFNS_H__
#define __X86_32_ASM_DEFNS_H__

#include <asm/percpu.h>

#ifdef CONFIG_FRAME_POINTER
/* Indicate special exception stack frame by inverting the frame pointer. */
#define SETUP_EXCEPTION_FRAME_POINTER           \
        movl  %esp,%ebp;                        \
        notl  %ebp
#else
#define SETUP_EXCEPTION_FRAME_POINTER
#endif

#ifndef NDEBUG
#define ASSERT_INTERRUPT_STATUS(x)              \
        pushf;                                  \
        testb $X86_EFLAGS_IF>>8,1(%esp);        \
        j##x  1f;                               \
        ud2a;                                   \
1:      addl  $4,%esp;
#else
#define ASSERT_INTERRUPT_STATUS(x)
#endif

#define ASSERT_INTERRUPTS_ENABLED  ASSERT_INTERRUPT_STATUS(nz)
#define ASSERT_INTERRUPTS_DISABLED ASSERT_INTERRUPT_STATUS(z)

#define SAVE_ALL_GPRS                                   \
        cld;                                            \
        pushl %eax;                                     \
        pushl %ebp;                                     \
        SETUP_EXCEPTION_FRAME_POINTER;                  \
        pushl %edi;                                     \
        pushl %esi;                                     \
        pushl %edx;                                     \
        pushl %ecx;                                     \
        pushl %ebx

/*
 * Saves all register state into an exception/interrupt stack frame.
 * Returns to the caller at <xen_lbl> if the interrupted context is within
 * Xen; at <vm86_lbl> if the interrupted context is vm86; or falls through
 * if the interrupted context is an ordinary guest protected-mode context.
 * In all cases %ecx contains __HYPERVISOR_DS. %ds/%es are guaranteed to
 * contain __HYPERVISOR_DS unless control passes to <xen_lbl>, in which case
 * the caller is reponsible for validity of %ds/%es.
 */
#define SAVE_ALL(xen_lbl, vm86_lbl)                     \
        SAVE_ALL_GPRS;                                  \
        testl $(X86_EFLAGS_VM),UREGS_eflags(%esp);      \
        mov   %ds,%edi;                                 \
        mov   %es,%esi;                                 \
        mov   $(__HYPERVISOR_DS),%ecx;                  \
        jnz   86f;                                      \
        .text 1;                                        \
        86:   call setup_vm86_frame;                    \
        jmp   vm86_lbl;                                 \
        .previous;                                      \
        testb $3,UREGS_cs(%esp);                        \
        jz    xen_lbl;                                  \
        /*                                              \
         * We are the outermost Xen context, but our    \
         * life is complicated by NMIs and MCEs. These  \
         * could occur in our critical section and      \
         * pollute %ds and %es. We have to detect that  \
         * this has occurred and avoid saving Xen DS/ES \
         * values to the guest stack frame.             \
         */                                             \
        cmpw  %cx,%di;                                  \
        mov   %ecx,%ds;                                 \
        mov   %fs,UREGS_fs(%esp);                       \
        cmove UREGS_ds(%esp),%edi;                      \
        cmpw  %cx,%si;                                  \
        mov   %edi,UREGS_ds(%esp);                      \
        cmove UREGS_es(%esp),%esi;                      \
        mov   %ecx,%es;                                 \
        mov   %gs,UREGS_gs(%esp);                       \
        mov   %esi,UREGS_es(%esp)

#ifdef PERF_COUNTERS
#define PERFC_INCR(_name,_idx,_cur)                     \
        pushl _cur;                                     \
        movl VCPU_processor(_cur),_cur;                 \
        shll $PERCPU_SHIFT,_cur;                        \
        incl per_cpu__perfcounters+_name*4(_cur,_idx,4);\
        popl _cur
#else
#define PERFC_INCR(_name,_idx,_cur)
#endif

#ifdef CONFIG_X86_SUPERVISOR_MODE_KERNEL
#define FIXUP_RING0_GUEST_STACK                         \
        testl $2,8(%esp);                               \
        jnz 1f; /* rings 2 & 3 permitted */             \
        testl $1,8(%esp);                               \
        jz 2f;                                          \
        ud2; /* ring 1 should not be used */            \
        2:cmpl $(__HYPERVISOR_VIRT_START),%esp;         \
        jge 1f;                                         \
        call fixup_ring0_guest_stack;                   \
        1:
#else
#define FIXUP_RING0_GUEST_STACK
#endif

#define BUILD_SMP_INTERRUPT(x,v) XBUILD_SMP_INTERRUPT(x,v)
#define XBUILD_SMP_INTERRUPT(x,v)               \
__asm__(                                        \
    "\n"__ALIGN_STR"\n"                         \
    ".globl " STR(x) "\n\t"                     \
    STR(x) ":\n\t"                              \
    "pushl $"#v"<<16\n\t"                       \
    STR(FIXUP_RING0_GUEST_STACK)                \
    STR(SAVE_ALL(1f,1f)) "\n\t"                 \
    "1:movl %esp,%eax\n\t"                      \
    "pushl %eax\n\t"                            \
    "call "STR(smp_##x)"\n\t"                   \
    "addl $4,%esp\n\t"                          \
    "jmp ret_from_intr\n");

#define BUILD_COMMON_IRQ()                      \
__asm__(                                        \
    "\n" __ALIGN_STR"\n"                        \
    "common_interrupt:\n\t"                     \
    STR(FIXUP_RING0_GUEST_STACK)                \
    STR(SAVE_ALL(1f,1f)) "\n\t"                 \
    "1:movl %esp,%eax\n\t"                      \
    "pushl %eax\n\t"                            \
    "call " STR(do_IRQ) "\n\t"                  \
    "addl $4,%esp\n\t"                          \
    "jmp ret_from_intr\n");

#define IRQ_NAME2(nr) nr##_interrupt(void)
#define IRQ_NAME(nr) IRQ_NAME2(IRQ##nr)

#define BUILD_IRQ(nr)                           \
asmlinkage void IRQ_NAME(nr);                   \
__asm__(                                        \
"\n"__ALIGN_STR"\n"                             \
STR(IRQ) #nr "_interrupt:\n\t"                  \
    "pushl $"#nr"<<16\n\t"                      \
    "jmp common_interrupt");

#endif /* __X86_32_ASM_DEFNS_H__ */
