/*
 * Done by Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com>
 * Common stuff for memory and page handling.
 * Parts are taken from FreeBSD.
 *
 ****************************************************************************
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


#if !defined(_PAGE_H_)
#define _PAGE_H_

#include "os.h"
#include "ia64_cpu.h"

#define PTE_KERNEL_ATTR ((PTE_P<<PTE_P_SHIFT)		|\
			(PTE_MA_WB<<PTE_MA_SHIFT)	|\
			(PTE_D<<PTE_D_SHIFT)		|\
			(PTE_A<<PTE_A_SHIFT)		|\
			(PTE_PL_KERN<<PTE_PL_SHIFT)	|\
			(PTE_AR_RWX<<PTE_AR_SHIFT))


/* The kernel tr page size for text and data. */
#define KERNEL_TR_PAGE_SIZE	PTE_PS_1M
/* The efi-pal page size for text and data. */
#define PAL_TR_PAGE_SIZE	PTE_PS_1M

#include "arch_limits.h"
#define PAGE_SHIFT	__PAGE_SHIFT
#define PAGE_SIZE	__PAGE_SIZE
#define PAGE_MASK	(~(PAGE_SIZE-1))

#define KSTACK_PAGES	4	/* 4 pages for the kernel stack + bsp */

#define IA64_TR_KERNEL	0       /* itr0, dtr0: maps kernel image (code) */
#define IA64_TR_PAL	1       /* itr1: maps pal code */

/*
 * Manipulating region bits of an address.
 */
#define IA64_RR_BASE(n)		((UL_TYPE(n)) << 61)
#define IA64_RR_MASK(x)		((UL_TYPE(x)) & ((1L << 61) - 1))
#define IA64_RR_EXTR(x)		((x) >> 61)

#define IA64_PHYS_TO_RR5(x)	((x) | IA64_RR_BASE(5))
#define IA64_PHYS_TO_RR7(x)	((x) | IA64_RR_BASE(7))

#define __pa(x)	IA64_RR_MASK(x)
#define __va(x)	IA64_PHYS_TO_RR7(x)

#define roundup_page(x)	((((unsigned long)(x)) + PAGE_SIZE -1) & PAGE_MASK)
#define trunc_page(x)	((unsigned long)(x) & PAGE_MASK)


#if !defined(__ASSEMBLY__)

/* Contains the parts of the physically memory. */
extern paddr_t phys_avail[];

#define page_to_pfn(page)	((uint64_t)(page) >> PAGE_SHIFT)
#define pfn_to_page(pfn)	((uint64_t)pfn << PAGE_SHIFT)
/* Get phyiscal address of page of virtual address. */
#define virt_to_page(addr)	((uint64_t)__pa(addr) & PAGE_MASK)
#define virt_to_pfn(addr)	(page_to_pfn(virt_to_page(addr)))


#endif /* __ASSEMBLY__ */


/* For both see minios-ia64.lds. */
/* This is where the kernel virtually starts. */
#define KERNEL_START	IA64_PHYS_TO_RR5(0x100000000)
/* !!!!!
 * For physical start of kernel
 * Currently used in arch/ia64/fw.S.
 * !!!!!
 */
#define KERNEL_PHYS_START_SHIFT	20

/* A region 5 address to physical address */
#define KERN_VIRT_2_PHYS(x) (((x) - KERNEL_START) + \
				(1 << KERNEL_PHYS_START_SHIFT))

/* Some protection keys for region 5 and 7 addresses. */
#define IA64_KEY_REG7	0x234	/* Region 7 - identity mapped addresses */
#define IA64_KEY_REG5	0x89a	/* Region 5 - kernel addresses */

// This is xen specific !
#define PAGE_SHIFT_XEN_16K	14	// For 16KB page size
#define mfn_to_virt(mfn)	((void*)__va((mfn) << PAGE_SHIFT_XEN_16K))

#endif /* !defined(_PAGE_H_) */
