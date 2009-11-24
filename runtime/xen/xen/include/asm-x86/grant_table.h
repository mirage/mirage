/******************************************************************************
 * include/asm-x86/grant_table.h
 * 
 * Copyright (c) 2004-2005 K A Fraser
 */

#ifndef __ASM_GRANT_TABLE_H__
#define __ASM_GRANT_TABLE_H__

#define INITIAL_NR_GRANT_FRAMES 4

/*
 * Caller must own caller's BIGLOCK, is responsible for flushing the TLB, and
 * must hold a reference to the page.
 */
int create_grant_host_mapping(uint64_t addr, unsigned long frame,
			      unsigned int flags, unsigned int cache_flags);
int replace_grant_host_mapping(
    uint64_t addr, unsigned long frame, uint64_t new_addr, unsigned int flags);

#define gnttab_create_shared_page(d, t, i)                               \
    do {                                                                 \
        share_xen_page_with_guest(                                       \
            virt_to_page((char *)(t)->shared_raw[i]),                    \
            (d), XENSHARE_writable);                                     \
    } while ( 0 )

#define gnttab_create_status_page(d, t, i)                               \
    do {                                                                 \
        share_xen_page_with_guest(                                       \
           virt_to_page((char *)(t)->status[i]),                         \
            (d), XENSHARE_writable);                                     \
    } while ( 0 )


#define gnttab_shared_mfn(d, t, i)                      \
    ((virt_to_maddr((t)->shared_raw[i]) >> PAGE_SHIFT))

#define gnttab_shared_gmfn(d, t, i)                     \
    (mfn_to_gmfn(d, gnttab_shared_mfn(d, t, i)))


#define gnttab_status_mfn(t, i)                         \
    ((virt_to_maddr((t)->status[i]) >> PAGE_SHIFT))

#define gnttab_status_gmfn(d, t, i)                     \
    (mfn_to_gmfn(d, gnttab_status_mfn(t, i)))

#define gnttab_mark_dirty(d, f) paging_mark_dirty((d), (f))

static inline void gnttab_clear_flag(unsigned long nr, uint16_t *addr)
{
    clear_bit(nr, (unsigned long *)addr);
}

/* Foreign mappings of HHVM-guest pages do not modify the type count. */
#define gnttab_host_mapping_get_page_type(op, ld, rd)   \
    (!((op)->flags & GNTMAP_readonly) &&                \
     (((ld) == (rd)) || !paging_mode_external(rd)))

/* Done implicitly when page tables are destroyed. */
#define gnttab_release_host_mappings(domain) ( paging_mode_external(domain) )

static inline int replace_grant_supported(void)
{
    return 1;
}

#endif /* __ASM_GRANT_TABLE_H__ */
