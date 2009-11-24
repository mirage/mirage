/******************************************************************************
 * domain_page.h
 * 
 * Allow temporary mapping of domain page frames into Xen space.
 * 
 * Copyright (c) 2003-2006, Keir Fraser <keir@xensource.com>
 */

#ifndef __XEN_DOMAIN_PAGE_H__
#define __XEN_DOMAIN_PAGE_H__

#include <xen/config.h>
#include <xen/mm.h>

#ifdef CONFIG_DOMAIN_PAGE

/*
 * Map a given page frame, returning the mapped virtual address. The page is
 * then accessible within the current VCPU until a corresponding unmap call.
 */
void *map_domain_page(unsigned long mfn);

/*
 * Pass a VA within a page previously mapped in the context of the
 * currently-executing VCPU via a call to map_domain_page().
 */
void unmap_domain_page(const void *va);

/*
 * Similar to the above calls, except the mapping is accessible in all
 * address spaces (not just within the VCPU that created the mapping). Global
 * mappings can also be unmapped from any context.
 */
void *map_domain_page_global(unsigned long mfn);
void unmap_domain_page_global(const void *va);

#define __map_domain_page(pg)        map_domain_page(__page_to_mfn(pg))
#define __map_domain_page_global(pg) map_domain_page_global(__page_to_mfn(pg))

#define DMCACHE_ENTRY_VALID 1U
#define DMCACHE_ENTRY_HELD  2U

struct domain_mmap_cache {
    unsigned long mfn;
    void         *va;
    unsigned int  flags;
};

static inline void
domain_mmap_cache_init(struct domain_mmap_cache *cache)
{
    ASSERT(cache != NULL);
    cache->flags = 0;
    cache->mfn = 0;
    cache->va = NULL;
}

static inline void *
map_domain_page_with_cache(unsigned long mfn, struct domain_mmap_cache *cache)
{
    ASSERT(cache != NULL);
    BUG_ON(cache->flags & DMCACHE_ENTRY_HELD);

    if ( likely(cache->flags & DMCACHE_ENTRY_VALID) )
    {
        cache->flags |= DMCACHE_ENTRY_HELD;
        if ( likely(mfn == cache->mfn) )
            goto done;
        unmap_domain_page(cache->va);
    }

    cache->mfn   = mfn;
    cache->va    = map_domain_page(mfn);
    cache->flags = DMCACHE_ENTRY_HELD | DMCACHE_ENTRY_VALID;

 done:
    return cache->va;
}

static inline void
unmap_domain_page_with_cache(const void *va, struct domain_mmap_cache *cache)
{
    ASSERT(cache != NULL);
    cache->flags &= ~DMCACHE_ENTRY_HELD;
}

static inline void
domain_mmap_cache_destroy(struct domain_mmap_cache *cache)
{
    ASSERT(cache != NULL);
    BUG_ON(cache->flags & DMCACHE_ENTRY_HELD);

    if ( likely(cache->flags & DMCACHE_ENTRY_VALID) )
    {
        unmap_domain_page(cache->va);
        cache->flags = 0;
    }
}

#else /* !CONFIG_DOMAIN_PAGE */

#define map_domain_page(mfn)                mfn_to_virt(mfn)
#define __map_domain_page(pg)               page_to_virt(pg)
#define unmap_domain_page(va)               ((void)(va))

#define map_domain_page_global(mfn)         mfn_to_virt(mfn)
#define __map_domain_page_global(pg)        page_to_virt(pg)
#define unmap_domain_page_global(va)        ((void)(va))

struct domain_mmap_cache { 
};

#define domain_mmap_cache_init(c)           ((void)(c))
#define map_domain_page_with_cache(mfn,c)   (map_domain_page(mfn))
#define unmap_domain_page_with_cache(va,c)  ((void)(va))
#define domain_mmap_cache_destroy(c)        ((void)(c))

#endif /* !CONFIG_DOMAIN_PAGE */

#endif /* __XEN_DOMAIN_PAGE_H__ */
