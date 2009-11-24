/******************************************************************************
 * include/asm-ia64/grant_table.h
 */

#ifndef __ASM_GRANT_TABLE_H__
#define __ASM_GRANT_TABLE_H__

#define INITIAL_NR_GRANT_FRAMES 1

// for grant map/unmap
int create_grant_host_mapping(unsigned long gpaddr, unsigned long mfn, 
			      unsigned int flags, unsigned int cache_flags);
int replace_grant_host_mapping(unsigned long gpaddr, unsigned long mfn, unsigned long new_gpaddr, unsigned int flags);

// for grant transfer
int guest_physmap_add_page(struct domain *d, unsigned long gpfn, unsigned long mfn, unsigned int page_order);

/* XXX
 * somewhere appropriate
 * those constand shouldn't be pre-defined and
 * those area should be reserved by EFI MD.
 */
/* Guest phsyical address of shared_info */
#define IA64_SHARED_INFO_PADDR	(1UL << 40)
/* Guest phsyical address of mapped_regs */
#define IA64_XMAPPEDREGS_BASE_PADDR     (IA64_SHARED_INFO_PADDR + XSI_SIZE)
#define IA64_XMAPPEDREGS_PADDR(vcpu_id)             \
    (IA64_XMAPPEDREGS_BASE_PADDR +                  \
     (vcpu_id) * max_t(unsigned long, PAGE_SIZE, XMAPPEDREGS_SIZE))

/* Guest physical address of the grant table.  */
#define IA64_GRANT_TABLE_PADDR  IA64_XMAPPEDREGS_PADDR(NR_CPUS)

#define gnttab_shared_maddr(t, i)       (virt_to_maddr((t)->shared_raw[(i)]))
#define gnttab_shared_page(t, i)        (virt_to_page((t)->shared_raw[(i)]))

#define gnttab_status_maddr(t, i)       (virt_to_maddr((t)->status[(i)]))
#define gnttab_status_mfn(t, i)       (virt_to_maddr((t)->status[(i)]) >> PAGE_SHIFT)
#define gnttab_status_page(t, i)        (virt_to_page((t)->status[(i)]))

#define ia64_gnttab_create_shared_page(d, t, i)                         \
    do {                                                                \
        BUG_ON((d)->arch.mm.pgd == NULL);                               \
        assign_domain_page((d),                                         \
                           IA64_GRANT_TABLE_PADDR + ((i) << PAGE_SHIFT), \
                           gnttab_shared_maddr((t), (i)));              \
    } while (0)

/*
 * for grant table shared page
 * grant_table_create() might call this macro before allocating the p2m table.
 * In such case, arch_domain_create() completes the initialization.
 */
#define gnttab_create_shared_page(d, t, i)                      \
    do {                                                        \
        share_xen_page_with_guest(gnttab_shared_page((t), (i)), \
                                  (d), XENSHARE_writable);      \
        if ((d)->arch.mm.pgd)                                   \
            ia64_gnttab_create_shared_page((d), (t), (i));      \
    } while (0)

#define ia64_gnttab_create_status_page(d, t, i)                         \
    do {                                                                \
        BUG_ON((d)->arch.mm.pgd == NULL);                               \
        assign_domain_page((d),                                         \
                           IA64_GRANT_TABLE_PADDR + ((i) << PAGE_SHIFT), \
                           gnttab_status_maddr((t), (i)));              \
    } while (0)

#define gnttab_create_status_page(d, t, i)                      \
    do {                                                        \
        share_xen_page_with_guest(gnttab_status_page((t), (i)), \
                                  (d), XENSHARE_writable);      \
        if ((d)->arch.mm.pgd)                                   \
            ia64_gnttab_create_status_page((d), (t), (i));      \
    } while (0)

#define gnttab_shared_gmfn(d, t, i)                 \
    ((IA64_GRANT_TABLE_PADDR >> PAGE_SHIFT) + (i))
#define gnttab_status_gmfn(d, t, i)                     \
    (mfn_to_gmfn(d, gnttab_status_mfn(t, i)))

#define gnttab_mark_dirty(d, f) ((void)f)

static inline void gnttab_clear_flag(unsigned long nr, uint16_t *addr)
{
	clear_bit(nr, addr);
}

#define gnttab_host_mapping_get_page_type(op, ld, rd)   \
    (!((op)->flags & GNTMAP_readonly))

#define gnttab_release_host_mappings(domain) 1

static inline int replace_grant_supported(void)
{
    return 1;
}

#endif /* __ASM_GRANT_TABLE_H__ */
