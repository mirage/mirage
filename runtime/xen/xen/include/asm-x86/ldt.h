
#ifndef __ARCH_LDT_H
#define __ARCH_LDT_H

#ifndef __ASSEMBLY__

static inline void load_LDT(struct vcpu *v)
{
    struct desc_struct *desc;
    unsigned long ents;

    if ( (ents = v->arch.guest_context.ldt_ents) == 0 )
    {
        __asm__ __volatile__ ( "lldt %%ax" : : "a" (0) );
    }
    else
    {
        desc = (!is_pv_32on64_vcpu(v)
                ? this_cpu(gdt_table) : this_cpu(compat_gdt_table))
               + LDT_ENTRY - FIRST_RESERVED_GDT_ENTRY;
        _set_tssldt_desc(desc, LDT_VIRT_START(v), ents*8-1, 2);
        __asm__ __volatile__ ( "lldt %%ax" : : "a" (LDT_ENTRY << 3) );
    }
}

#endif /* !__ASSEMBLY__ */

#endif

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */
