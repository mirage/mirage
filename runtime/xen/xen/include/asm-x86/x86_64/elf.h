#ifndef __X86_64_ELF_H__
#define __X86_64_ELF_H__

typedef struct {
    unsigned long r15;
    unsigned long r14;
    unsigned long r13;
    unsigned long r12;
    unsigned long rbp;
    unsigned long rbx;
    unsigned long r11;
    unsigned long r10;
    unsigned long r9;
    unsigned long r8;
    unsigned long rax;
    unsigned long rcx;
    unsigned long rdx;
    unsigned long rsi;
    unsigned long rdi;
    unsigned long orig_rax;
    unsigned long rip;
    unsigned long cs;
    unsigned long eflags;
    unsigned long rsp;
    unsigned long ss;
    unsigned long thread_fs;
    unsigned long thread_gs;
    unsigned long ds;
    unsigned long es;
    unsigned long fs;
    unsigned long gs;
} ELF_Gregset;

static inline void elf_core_save_regs(ELF_Gregset *core_regs, 
                                      crash_xen_core_t *xen_core_regs)
{
    unsigned long tmp;

    asm volatile("movq %%r15,%0" : "=m"(core_regs->r15));
    asm volatile("movq %%r14,%0" : "=m"(core_regs->r14));
    asm volatile("movq %%r13,%0" : "=m"(core_regs->r13));
    asm volatile("movq %%r12,%0" : "=m"(core_regs->r12));
    asm volatile("movq %%rbp,%0" : "=m"(core_regs->rbp));
    asm volatile("movq %%rbx,%0" : "=m"(core_regs->rbx));
    asm volatile("movq %%r11,%0" : "=m"(core_regs->r11));
    asm volatile("movq %%r10,%0" : "=m"(core_regs->r10));
    asm volatile("movq %%r9,%0" : "=m"(core_regs->r9));
    asm volatile("movq %%r8,%0" : "=m"(core_regs->r8));
    asm volatile("movq %%rax,%0" : "=m"(core_regs->rax));
    asm volatile("movq %%rcx,%0" : "=m"(core_regs->rcx));
    asm volatile("movq %%rdx,%0" : "=m"(core_regs->rdx));
    asm volatile("movq %%rsi,%0" : "=m"(core_regs->rsi));
    asm volatile("movq %%rdi,%0" : "=m"(core_regs->rdi));
    /* orig_rax not filled in for now */
    core_regs->rip = (unsigned long)elf_core_save_regs;
    asm volatile("movl %%cs, %%eax;" :"=a"(core_regs->cs));
    asm volatile("pushfq; popq %0" :"=m"(core_regs->eflags));
    asm volatile("movq %%rsp,%0" : "=m"(core_regs->rsp));
    asm volatile("movl %%ss, %%eax;" :"=a"(core_regs->ss));
    /* thread_fs not filled in for now */
    /* thread_gs not filled in for now */
    asm volatile("movl %%ds, %%eax;" :"=a"(core_regs->ds));
    asm volatile("movl %%es, %%eax;" :"=a"(core_regs->es));
    asm volatile("movl %%fs, %%eax;" :"=a"(core_regs->fs));
    asm volatile("movl %%gs, %%eax;" :"=a"(core_regs->gs));

    asm volatile("mov %%cr0, %0" : "=r" (tmp) : );
    xen_core_regs->cr0 = tmp;

    asm volatile("mov %%cr2, %0" : "=r" (tmp) : );
    xen_core_regs->cr2 = tmp;

    asm volatile("mov %%cr3, %0" : "=r" (tmp) : );
    xen_core_regs->cr3 = tmp;

    asm volatile("mov %%cr4, %0" : "=r" (tmp) : );
    xen_core_regs->cr4 = tmp;
}

#endif /* __X86_64_ELF_H__ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */
