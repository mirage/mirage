#ifndef _ASM_IA64_PGALLOC_H
#define _ASM_IA64_PGALLOC_H

/*
 * This file contains the functions and defines necessary to allocate
 * page tables.
 *
 * This hopefully works with any (fixed) ia-64 page-size, as defined
 * in <asm/page.h> (currently 8192).
 *
 * Copyright (C) 1998-2001 Hewlett-Packard Co
 *	David Mosberger-Tang <davidm@hpl.hp.com>
 * Copyright (C) 2000, Goutham Rao <goutham.rao@intel.com>
 */

#include <linux/config.h>

#include <linux/compiler.h>
#include <linux/mm.h>
#include <linux/page-flags.h>
#include <linux/threads.h>

#include <asm/mmu_context.h>

#ifndef XEN
DECLARE_PER_CPU(unsigned long *, __pgtable_quicklist);
#define pgtable_quicklist __ia64_per_cpu_var(__pgtable_quicklist)
DECLARE_PER_CPU(long, __pgtable_quicklist_size);
#define pgtable_quicklist_size __ia64_per_cpu_var(__pgtable_quicklist_size)

static inline long pgtable_quicklist_total_size(void)
{
	long ql_size = 0;
	int cpuid;

	for_each_online_cpu(cpuid) {
		ql_size += per_cpu(__pgtable_quicklist_size, cpuid);
	}
	return ql_size;
}

static inline void *pgtable_quicklist_alloc(void)
{
	unsigned long *ret = NULL;

	preempt_disable();

	ret = pgtable_quicklist;
	if (likely(ret != NULL)) {
		pgtable_quicklist = (unsigned long *)(*ret);
		ret[0] = 0;
		--pgtable_quicklist_size;
		preempt_enable();
	} else {
		preempt_enable();
		ret = (unsigned long *)__get_free_page(GFP_KERNEL | __GFP_ZERO);
	}

	return ret;
}

static inline void pgtable_quicklist_free(void *pgtable_entry)
{
#ifdef CONFIG_NUMA
	unsigned long nid = page_to_nid(virt_to_page(pgtable_entry));

	if (unlikely(nid != numa_node_id())) {
		free_page((unsigned long)pgtable_entry);
		return;
	}
#endif

	preempt_disable();
	*(unsigned long *)pgtable_entry = (unsigned long)pgtable_quicklist;
	pgtable_quicklist = (unsigned long *)pgtable_entry;
	++pgtable_quicklist_size;
	preempt_enable();
}
#endif

#ifdef XEN
#include <asm/pgtable.h>
#ifdef __PAGETABLE_PUD_FOLDED
# define pgd_cmpxchg_rel(mm, pgd, old_pud, new_pud)	({(void)old_pud;1;})
#else
# error "implement pgd_cmpxchg_rel()!"
#endif
#endif

static inline pgd_t *pgd_alloc(struct mm_struct *mm)
{
	return pgtable_quicklist_alloc();
}

#ifndef XEN
static inline void pgd_free(pgd_t * pgd)
{
	pgtable_quicklist_free(pgd);
}
#else
static inline void pgd_free(volatile pgd_t * pgd)
{
	pgtable_quicklist_free((void*)pgd);
}
#endif

static inline void
pud_populate(struct mm_struct *mm, pud_t * pud_entry, pmd_t * pmd)
{
	pud_val(*pud_entry) = __pa(pmd);
}

#ifdef XEN
static inline int
pud_cmpxchg_rel(struct mm_struct *mm, volatile pud_t * pud_entry,
                pmd_t * old_pmd, volatile pmd_t * new_pmd)
{
#ifdef CONFIG_SMP
	unsigned long r;
	r = cmpxchg_rel(&pud_val(*pud_entry), __pa(old_pmd), __pa(new_pmd));
	return (r == __pa(old_pmd));
#else
	if (pud_val(*pud_entry) == __pa(old_pmd)) {
		pud_val(*pud_entry) = __pa(new_pmd);
		return 1;
	}
	return 0;
#endif
}
#endif

static inline pmd_t *pmd_alloc_one(struct mm_struct *mm, unsigned long addr)
{
	return pgtable_quicklist_alloc();
}

#ifndef XEN
static inline void pmd_free(pmd_t * pmd)
{
	pgtable_quicklist_free(pmd);
}
#else
static inline void pmd_free(volatile pmd_t * pmd)
{
	pgtable_quicklist_free((void*)pmd);
}
#endif

#define __pmd_free_tlb(tlb, pmd)	pmd_free(pmd)

#ifndef XEN
static inline void
pmd_populate(struct mm_struct *mm, pmd_t * pmd_entry, struct page *pte)
{
	pmd_val(*pmd_entry) = page_to_maddr(pte);
}
#endif

static inline void
pmd_populate_kernel(struct mm_struct *mm, pmd_t * pmd_entry, pte_t * pte)
{
	pmd_val(*pmd_entry) = __pa(pte);
}

#ifdef XEN
static inline int
pmd_cmpxchg_kernel_rel(struct mm_struct *mm, volatile pmd_t * pmd_entry,
		       pte_t * old_pte, pte_t * new_pte)
{
#ifdef CONFIG_SMP
	unsigned long r;
	r = cmpxchg_rel(&pmd_val(*pmd_entry), __pa(old_pte), __pa(new_pte));
	return (r == __pa(old_pte));
#else
	if (pmd_val(*pmd_entry) == __pa(old_pte)) {
		pmd_val(*pmd_entry) = __pa(new_pte);
		return 1;
	}
	return 0;
#endif
}
#endif

#ifndef XEN
static inline struct page *pte_alloc_one(struct mm_struct *mm,
					 unsigned long addr)
{
	return virt_to_page(pgtable_quicklist_alloc());
}
#endif

static inline pte_t *pte_alloc_one_kernel(struct mm_struct *mm,
					  unsigned long addr)
{
	return pgtable_quicklist_alloc();
}

#ifndef XEN
static inline void pte_free(struct page *pte)
{
	pgtable_quicklist_free(page_address(pte));
}

static inline void pte_free_kernel(pte_t * pte)
{
	pgtable_quicklist_free(pte);
}
#else
static inline void pte_free_kernel(volatile pte_t * pte)
{
	pgtable_quicklist_free((void*)pte);
}
#endif

#ifndef XEN
#define __pte_free_tlb(tlb, pte)	pte_free(pte)
#endif

extern void check_pgt_cache(void);

#endif				/* _ASM_IA64_PGALLOC_H */
