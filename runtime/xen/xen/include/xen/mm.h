/******************************************************************************
 * include/xen/mm.h
 * 
 * Definitions for memory pages, frame numbers, addresses, allocations, etc.
 * 
 * Note that Xen must handle several different physical 'address spaces' and
 * there is a consistent terminology for these:
 * 
 * 1. gpfn/gpaddr: A guest-specific pseudo-physical frame number or address.
 * 2. gmfn/gmaddr: A machine address from the p.o.v. of a particular guest.
 * 3. mfn/maddr:   A real machine frame number or address.
 * 4. pfn/paddr:   Used in 'polymorphic' functions that work across all
 *                 address spaces, depending on context. See the pagetable
 *                 conversion macros in asm-x86/page.h for examples.
 *                 Also 'paddr_t' is big enough to store any physical address.
 * 
 * This scheme provides consistent function and variable names even when
 * different guests are running in different memory-management modes.
 * 1. A guest running in auto-translated mode (e.g., shadow_mode_translate())
 *    will have gpfn == gmfn and gmfn != mfn.
 * 2. A paravirtualised x86 guest will have gpfn != gmfn and gmfn == mfn.
 * 3. A paravirtualised guest with no pseudophysical overlay will have
 *    gpfn == gpmfn == mfn.
 * 
 * Copyright (c) 2002-2006, K A Fraser <keir@xensource.com>
 */

#ifndef __XEN_MM_H__
#define __XEN_MM_H__

#include <xen/config.h>
#include <xen/types.h>
#include <xen/list.h>
#include <xen/spinlock.h>

struct domain;
struct page_info;

/* Boot-time allocator. Turns into generic allocator after bootstrap. */
void init_boot_pages(paddr_t ps, paddr_t pe);
unsigned long alloc_boot_pages(
    unsigned long nr_pfns, unsigned long pfn_align);
void end_boot_allocator(void);

/* Xen suballocator. These functions are interrupt-safe. */
void init_xenheap_pages(paddr_t ps, paddr_t pe);
void *alloc_xenheap_pages(unsigned int order, unsigned int memflags);
void free_xenheap_pages(void *v, unsigned int order);
#define alloc_xenheap_page() (alloc_xenheap_pages(0,0))
#define free_xenheap_page(v) (free_xenheap_pages(v,0))

/* Domain suballocator. These functions are *not* interrupt-safe.*/
void init_domheap_pages(paddr_t ps, paddr_t pe);
struct page_info *alloc_domheap_pages(
    struct domain *d, unsigned int order, unsigned int memflags);
void free_domheap_pages(struct page_info *pg, unsigned int order);
unsigned long avail_domheap_pages_region(
    unsigned int node, unsigned int min_width, unsigned int max_width);
unsigned long avail_domheap_pages(void);
#define alloc_domheap_page(d,f) (alloc_domheap_pages(d,0,f))
#define free_domheap_page(p)  (free_domheap_pages(p,0))
unsigned int online_page(unsigned long mfn, uint32_t *status);
int offline_page(unsigned long mfn, int broken, uint32_t *status);
int query_page_offline(unsigned long mfn, uint32_t *status);

void scrub_heap_pages(void);

int assign_pages(
    struct domain *d,
    struct page_info *pg,
    unsigned int order,
    unsigned int memflags);

/* memflags: */
#define _MEMF_no_refcount 0
#define  MEMF_no_refcount (1U<<_MEMF_no_refcount)
#define _MEMF_populate_on_demand 1
#define  MEMF_populate_on_demand (1U<<_MEMF_populate_on_demand)
#define _MEMF_tmem        2
#define  MEMF_tmem        (1U<<_MEMF_tmem)
#define _MEMF_node        8
#define  MEMF_node(n)     ((((n)+1)&0xff)<<_MEMF_node)
#define _MEMF_bits        24
#define  MEMF_bits(n)     ((n)<<_MEMF_bits)

#ifdef CONFIG_PAGEALLOC_MAX_ORDER
#define MAX_ORDER CONFIG_PAGEALLOC_MAX_ORDER
#else
#define MAX_ORDER 20 /* 2^20 contiguous pages */
#endif

#define page_list_entry list_head

#include <asm/mm.h>

#ifndef page_list_entry
struct page_list_head
{
    struct page_info *next, *tail;
};
/* These must only have instances in struct page_info. */
# define page_list_entry

#define PAGE_LIST_NULL (~0)

# if !defined(pdx_to_page) && !defined(page_to_pdx)
#  if defined(__page_to_mfn) || defined(__mfn_to_page)
#   define page_to_pdx __page_to_mfn
#   define pdx_to_page __mfn_to_page
#  else
#   define page_to_pdx page_to_mfn
#   define pdx_to_page mfn_to_page
#  endif
# endif

# define PAGE_LIST_HEAD_INIT(name) { NULL, NULL }
# define PAGE_LIST_HEAD(name) \
    struct page_list_head name = PAGE_LIST_HEAD_INIT(name)
# define INIT_PAGE_LIST_HEAD(head) ((head)->tail = (head)->next = NULL)
# define INIT_PAGE_LIST_ENTRY(ent) ((ent)->prev = (ent)->next = PAGE_LIST_NULL)

static inline int
page_list_empty(const struct page_list_head *head)
{
    return !head->next;
}
static inline struct page_info *
page_list_first(const struct page_list_head *head)
{
    return head->next;
}
static inline struct page_info *
page_list_next(const struct page_info *page,
               const struct page_list_head *head)
{
    return page != head->tail ? pdx_to_page(page->list.next) : NULL;
}
static inline struct page_info *
page_list_prev(const struct page_info *page,
               const struct page_list_head *head)
{
    return page != head->next ? pdx_to_page(page->list.prev) : NULL;
}
static inline void
page_list_add(struct page_info *page, struct page_list_head *head)
{
    if ( head->next )
    {
        page->list.next = page_to_pdx(head->next);
        head->next->list.prev = page_to_pdx(page);
    }
    else
    {
        head->tail = page;
        page->list.next = PAGE_LIST_NULL;
    }
    page->list.prev = PAGE_LIST_NULL;
    head->next = page;
}
static inline void
page_list_add_tail(struct page_info *page, struct page_list_head *head)
{
    page->list.next = PAGE_LIST_NULL;
    if ( head->next )
    {
        page->list.prev = page_to_pdx(head->tail);
        head->tail->list.next = page_to_pdx(page);
    }
    else
    {
        page->list.prev = PAGE_LIST_NULL;
        head->next = page;
    }
    head->tail = page;
}
static inline bool_t
__page_list_del_head(struct page_info *page, struct page_list_head *head,
                     struct page_info *next, struct page_info *prev)
{
    if ( head->next == page )
    {
        if ( head->tail != page )
        {
            next->list.prev = PAGE_LIST_NULL;
            head->next = next;
        }
        else
            head->tail = head->next = NULL;
        return 1;
    }

    if ( head->tail == page )
    {
        prev->list.next = PAGE_LIST_NULL;
        head->tail = prev;
        return 1;
    }

    return 0;
}
static inline void
page_list_del(struct page_info *page, struct page_list_head *head)
{
    struct page_info *next = pdx_to_page(page->list.next);
    struct page_info *prev = pdx_to_page(page->list.prev);

    if ( !__page_list_del_head(page, head, next, prev) )
    {
        next->list.prev = page->list.prev;
        prev->list.next = page->list.next;
    }
}
static inline void
page_list_del2(struct page_info *page, struct page_list_head *head1,
               struct page_list_head *head2)
{
    struct page_info *next = pdx_to_page(page->list.next);
    struct page_info *prev = pdx_to_page(page->list.prev);

    if ( !__page_list_del_head(page, head1, next, prev) &&
         !__page_list_del_head(page, head2, next, prev) )
    {
        next->list.prev = page->list.prev;
        prev->list.next = page->list.next;
    }
}
static inline struct page_info *
page_list_remove_head(struct page_list_head *head)
{
    struct page_info *page = head->next;

    if ( page )
        page_list_del(page, head);

    return page;
}
static inline void
page_list_move(struct page_list_head *dst, struct page_list_head *src)
{
    if ( !page_list_empty(src) )
    {
        *dst = *src;
        INIT_PAGE_LIST_HEAD(src);
    }
}
static inline void
page_list_splice(struct page_list_head *list, struct page_list_head *head)
{
    struct page_info *first, *last, *at;

    if ( page_list_empty(list) )
        return;

    if ( page_list_empty(head) )
    {
        head->next = list->next;
        head->tail = list->tail;
        return;
    }

    first = list->next;
    last = list->tail;
    at = head->next;

    first->list.prev = page_to_pdx(head->next);
    head->next = first;

    last->list.next = page_to_pdx(at);
    at->list.prev = page_to_pdx(last);
}

#define page_list_for_each(pos, head) \
    for ( pos = (head)->next; pos; pos = page_list_next(pos, head) )
#define page_list_for_each_safe(pos, tmp, head) \
    for ( pos = (head)->next; \
          pos ? (tmp = page_list_next(pos, head), 1) : 0; \
          pos = tmp )
#define page_list_for_each_safe_reverse(pos, tmp, head) \
    for ( pos = (head)->tail; \
          pos ? (tmp = page_list_prev(pos, head), 1) : 0; \
          pos = tmp )
#else
# define page_list_head                  list_head
# define PAGE_LIST_HEAD_INIT             LIST_HEAD_INIT
# define PAGE_LIST_HEAD                  LIST_HEAD
# define INIT_PAGE_LIST_HEAD             INIT_LIST_HEAD
# define INIT_PAGE_LIST_ENTRY            INIT_LIST_HEAD
# define page_list_empty                 list_empty
# define page_list_first(hd)             list_entry((hd)->next, \
                                                    struct page_info, list)
# define page_list_next(pg, hd)          list_entry((pg)->list.next, \
                                                    struct page_info, list)
# define page_list_add(pg, hd)           list_add(&(pg)->list, hd)
# define page_list_add_tail(pg, hd)      list_add_tail(&(pg)->list, hd)
# define page_list_del(pg, hd)           list_del(&(pg)->list)
# define page_list_del2(pg, hd1, hd2)    list_del(&(pg)->list)
# define page_list_remove_head(hd)       (!page_list_empty(hd) ? \
    ({ \
        struct page_info *__pg = page_list_first(hd); \
        list_del(&__pg->list); \
        __pg; \
    }) : NULL)
# define page_list_move(dst, src)        (!list_empty(src) ? \
    list_replace_init(src, dst) : (void)0)
# define page_list_for_each(pos, head)   list_for_each_entry(pos, head, list)
# define page_list_for_each_safe(pos, tmp, head) \
    list_for_each_entry_safe(pos, tmp, head, list)
# define page_list_for_each_safe_reverse(pos, tmp, head) \
    list_for_each_entry_safe_reverse(pos, tmp, head, list)
# define page_list_splice(list, hd)        list_splice(list, hd)
#endif

void scrub_one_page(struct page_info *);

int guest_remove_page(struct domain *d, unsigned long gmfn);

#define RAM_TYPE_CONVENTIONAL 0x00000001
#define RAM_TYPE_RESERVED     0x00000002
#define RAM_TYPE_UNUSABLE     0x00000004
#define RAM_TYPE_ACPI         0x00000008
/* TRUE if the whole page at @mfn is of the requested RAM type(s) above. */
int page_is_ram_type(unsigned long mfn, unsigned long mem_type);

#endif /* __XEN_MM_H__ */
