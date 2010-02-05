/* -*-  Mode:C; c-basic-offset:4; tab-width:4 -*-
 *
 * (C) 2003 - Rolf Neugebauer - Intel Research Cambridge
 * Copyright (c) 2005, Keir A Fraser
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
 * DEALINGS IN THE SOFTWARE.
 */

#ifndef _ARCH_MM_H_
#define _ARCH_MM_H_

#ifndef __ASSEMBLY__
#include <xen/xen.h>
#include <xen/arch-x86_64.h>
#endif

#define L1_FRAME                1
#define L2_FRAME                2
#define L3_FRAME                3

#define L1_PAGETABLE_SHIFT      12
#define L2_PAGETABLE_SHIFT      21
#define L3_PAGETABLE_SHIFT      30
#define L4_PAGETABLE_SHIFT      39

#define L1_PAGETABLE_ENTRIES    512
#define L2_PAGETABLE_ENTRIES    512
#define L3_PAGETABLE_ENTRIES    512
#define L4_PAGETABLE_ENTRIES    512

/* These are page-table limitations. Current CPUs support only 40-bit phys. */
#define PADDR_BITS              52
#define VADDR_BITS              48
#define PADDR_MASK              ((1UL << PADDR_BITS)-1)
#define VADDR_MASK              ((1UL << VADDR_BITS)-1)

#define L2_MASK  ((1UL << L3_PAGETABLE_SHIFT) - 1)
#define L3_MASK  ((1UL << L4_PAGETABLE_SHIFT) - 1)

#define NOT_L1_FRAMES           3
#define PRIpte "016lx"
#ifndef __ASSEMBLY__
typedef unsigned long pgentry_t;
#endif

#define L1_MASK  ((1UL << L2_PAGETABLE_SHIFT) - 1)

/* Given a virtual address, get an entry offset into a page table. */
#define l1_table_offset(_a) \
  (((_a) >> L1_PAGETABLE_SHIFT) & (L1_PAGETABLE_ENTRIES - 1))
#define l2_table_offset(_a) \
  (((_a) >> L2_PAGETABLE_SHIFT) & (L2_PAGETABLE_ENTRIES - 1))
#define l3_table_offset(_a) \
  (((_a) >> L3_PAGETABLE_SHIFT) & (L3_PAGETABLE_ENTRIES - 1))
#define l4_table_offset(_a) \
  (((_a) >> L4_PAGETABLE_SHIFT) & (L4_PAGETABLE_ENTRIES - 1))

#define _PAGE_PRESENT  0x001ULL
#define _PAGE_RW       0x002ULL
#define _PAGE_USER     0x004ULL
#define _PAGE_PWT      0x008ULL
#define _PAGE_PCD      0x010ULL
#define _PAGE_ACCESSED 0x020ULL
#define _PAGE_DIRTY    0x040ULL
#define _PAGE_PAT      0x080ULL
#define _PAGE_PSE      0x080ULL
#define _PAGE_GLOBAL   0x100ULL

#define L1_PROT (_PAGE_PRESENT|_PAGE_RW|_PAGE_ACCESSED|_PAGE_USER)
#define L1_PROT_RO (_PAGE_PRESENT|_PAGE_ACCESSED|_PAGE_USER)
#define L2_PROT (_PAGE_PRESENT|_PAGE_RW|_PAGE_ACCESSED|_PAGE_DIRTY|_PAGE_USER)
#define L3_PROT (_PAGE_PRESENT|_PAGE_RW|_PAGE_ACCESSED|_PAGE_DIRTY|_PAGE_USER)
#define L4_PROT (_PAGE_PRESENT|_PAGE_RW|_PAGE_ACCESSED|_PAGE_DIRTY|_PAGE_USER)

/* flags for ioremap */
#define IO_PROT (L1_PROT)
#define IO_PROT_NOCACHE (L1_PROT | _PAGE_PCD)

/* for P2M */
#define INVALID_P2M_ENTRY (~0UL)

#include "arch_limits.h"
#define PAGE_SIZE       __PAGE_SIZE
#define PAGE_SHIFT      __PAGE_SHIFT
#define PAGE_MASK       (~(PAGE_SIZE-1))

#define PFN_UP(x)	(((x) + PAGE_SIZE-1) >> L1_PAGETABLE_SHIFT)
#define PFN_DOWN(x)	((x) >> L1_PAGETABLE_SHIFT)
#define PFN_PHYS(x)	((uint64_t)(x) << L1_PAGETABLE_SHIFT)
#define PHYS_PFN(x)	((x) >> L1_PAGETABLE_SHIFT)

/* to align the pointer to the (next) page boundary */
#define PAGE_ALIGN(addr)        (((addr)+PAGE_SIZE-1)&PAGE_MASK)

#ifndef __ASSEMBLY__
/* Definitions for machine and pseudophysical addresses. */
typedef unsigned long paddr_t;
typedef unsigned long maddr_t;

extern unsigned long *phys_to_machine_mapping;
extern char _text, _etext, _erodata, _edata, _end;
extern unsigned long mfn_zero;
#define pfn_to_mfn(_pfn) (phys_to_machine_mapping[(_pfn)])
static __inline__ maddr_t phys_to_machine(paddr_t phys)
{
	maddr_t machine = pfn_to_mfn(phys >> PAGE_SHIFT);
	machine = (machine << PAGE_SHIFT) | (phys & ~PAGE_MASK);
	return machine;
}

#define mfn_to_pfn(_mfn) (machine_to_phys_mapping[(_mfn)])
static __inline__ paddr_t machine_to_phys(maddr_t machine)
{
	paddr_t phys = mfn_to_pfn(machine >> PAGE_SHIFT);
	phys = (phys << PAGE_SHIFT) | (machine & ~PAGE_MASK);
	return phys;
}
#endif

#define VIRT_START                 ((unsigned long)&_text)

#define to_phys(x)                 ((unsigned long)(x)-VIRT_START)
#define to_virt(x)                 ((void *)((unsigned long)(x)+VIRT_START))

#define virt_to_pfn(_virt)         (PFN_DOWN(to_phys(_virt)))
#define virt_to_mfn(_virt)         (pfn_to_mfn(virt_to_pfn(_virt)))
#define mach_to_virt(_mach)        (to_virt(machine_to_phys(_mach)))
#define virt_to_mach(_virt)        (phys_to_machine(to_phys(_virt)))
#define mfn_to_virt(_mfn)          (to_virt(mfn_to_pfn(_mfn) << PAGE_SHIFT))
#define pfn_to_virt(_pfn)          (to_virt((_pfn) << PAGE_SHIFT))

/* Pagetable walking. */
#define pte_to_mfn(_pte)           (((_pte) & (PADDR_MASK&PAGE_MASK)) >> L1_PAGETABLE_SHIFT)
#define pte_to_virt(_pte)          to_virt(mfn_to_pfn(pte_to_mfn(_pte)) << PAGE_SHIFT)


#define PT_BASE			   ((pgentry_t *)start_info.pt_base)

#define virtual_to_l3(_virt)	   ((pgentry_t *)pte_to_virt(PT_BASE[l4_table_offset(_virt)]))

#define virtual_to_l2(_virt)	   ({ \
	unsigned long __virt2 = (_virt); \
	(pgentry_t *) pte_to_virt(virtual_to_l3(__virt2)[l3_table_offset(__virt2)]); \
})

#define virtual_to_l1(_virt)	   ({ \
	unsigned long __virt1 = (_virt); \
	(pgentry_t *) pte_to_virt(virtual_to_l2(__virt1)[l2_table_offset(__virt1)]); \
})

#define virtual_to_pte(_virt)	   ({ \
	unsigned long __virt0 = (unsigned long) (_virt); \
	virtual_to_l1(__virt0)[l1_table_offset(__virt0)]; \
})
#define virtual_to_mfn(_virt)	   pte_to_mfn(virtual_to_pte(_virt))

#define map_frames(f, n) map_frames_ex(f, n, 1, 0, 1, DOMID_SELF, 0, L1_PROT)
#define map_zero(n, a) map_frames_ex(&mfn_zero, n, 0, 0, a, DOMID_SELF, 0, L1_PROT_RO)
#define do_map_zero(start, n) do_map_frames(start, &mfn_zero, n, 0, 0, DOMID_SELF, 0, L1_PROT_RO)

pgentry_t *need_pgt(unsigned long addr, int superpage);
int mfn_is_ram(unsigned long mfn);

#endif /* _ARCH_MM_H_ */
