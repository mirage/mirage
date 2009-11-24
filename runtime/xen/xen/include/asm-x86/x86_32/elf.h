#ifndef __X86_32_ELF_H__
#define __X86_32_ELF_H__

typedef struct {
    unsigned long ebx;
    unsigned long ecx;
    unsigned long edx;
    unsigned long esi;
    unsigned long edi;
    unsigned long ebp;
    unsigned long eax;
    unsigned long ds;
    unsigned long es;
    unsigned long fs;
    unsigned long gs;
    unsigned long orig_eax;
    unsigned long eip;
    unsigned long cs;
    unsigned long eflags;
    unsigned long esp;
    unsigned long ss;
} ELF_Gregset;

static inline void elf_core_save_regs(ELF_Gregset *core_regs, 
                                      crash_xen_core_t *xen_core_regs)
{
    unsigned long tmp;

    asm volatile("movl %%ebx,%0" : "=m"(core_regs->ebx));
    asm volatile("movl %%ecx,%0" : "=m"(core_regs->ecx));
    asm volatile("movl %%edx,%0" : "=m"(core_regs->edx));
    asm volatile("movl %%esi,%0" : "=m"(core_regs->esi));
    asm volatile("movl %%edi,%0" : "=m"(core_regs->edi));
    asm volatile("movl %%ebp,%0" : "=m"(core_regs->ebp));
    asm volatile("movl %%eax,%0" : "=m"(core_regs->eax));
    asm volatile("movw %%ds, %%ax;" :"=a"(core_regs->ds));
    asm volatile("movw %%es, %%ax;" :"=a"(core_regs->es));
    asm volatile("movw %%fs, %%ax;" :"=a"(core_regs->fs));
    asm volatile("movw %%gs, %%ax;" :"=a"(core_regs->gs));
    /* orig_eax not filled in for now */
    core_regs->eip = (unsigned long)elf_core_save_regs;
    asm volatile("movw %%cs, %%ax;" :"=a"(core_regs->cs));
    asm volatile("pushfl; popl %0" :"=m"(core_regs->eflags));
    asm volatile("movl %%esp,%0" : "=m"(core_regs->esp));
    asm volatile("movw %%ss, %%ax;" :"=a"(core_regs->ss));

    asm volatile("mov %%cr0, %0" : "=r" (tmp) : );
    xen_core_regs->cr0 = tmp;

    asm volatile("mov %%cr2, %0" : "=r" (tmp) : );
    xen_core_regs->cr2 = tmp;

    asm volatile("mov %%cr3, %0" : "=r" (tmp) : );
    xen_core_regs->cr3 = tmp;

    asm volatile("mov %%cr4, %0" : "=r" (tmp) : );
    xen_core_regs->cr4 = tmp;
}

#endif /* __X86_32_ELF_H__ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */
