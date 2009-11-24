#ifndef __X86_ELF_H__
#define __X86_ELF_H__

typedef struct {
    unsigned long cr0, cr2, cr3, cr4;
} crash_xen_core_t;

#ifdef __x86_64__
#include <asm/x86_64/elf.h>
#else
#include <asm/x86_32/elf.h>
#endif

#endif /* __X86_ELF_H__ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */
