/* 
 ****************************************************************************
 * (C) 2003 - Rolf Neugebauer - Intel Research Cambridge
 * (C) 2005 - Grzegorz Milos - Intel Research Cambridge
 ****************************************************************************
 *
 *        File: mm.c
 *      Author: Rolf Neugebauer (neugebar@dcs.gla.ac.uk)
 *     Changes: Grzegorz Milos
 *              
 *        Date: Aug 2003, chages Aug 2005
 * 
 * Environment: Xen Minimal OS
 * Description: memory management related functions
 *              contains buddy page allocator from Xen.
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

#include <mini-os/os.h>
#include <mini-os/hypervisor.h>
#include <xen/memory.h>
#include <mini-os/mm.h>
#include <mini-os/types.h>
#include <mini-os/lib.h>
#include <mini-os/xmalloc.h>

#ifdef MM_DEBUG
#define DEBUG(_f, _a...) \
    printk("MINI_OS(file=mm.c, line=%d) " _f "\n", __LINE__, ## _a)
#else
#define DEBUG(_f, _a...)    ((void)0)
#endif

/*********************
 * ALLOCATION BITMAP
 *  One bit per page of memory. Bit set => page is allocated.
 */

static unsigned long *alloc_bitmap;
#define PAGES_PER_MAPWORD (sizeof(unsigned long) * 8)

#define allocated_in_map(_pn) \
(alloc_bitmap[(_pn)/PAGES_PER_MAPWORD] & (1UL<<((_pn)&(PAGES_PER_MAPWORD-1))))

/*
 * Hint regarding bitwise arithmetic in map_{alloc,free}:
 *  -(1<<n)  sets all bits >= n. 
 *  (1<<n)-1 sets all bits <  n.
 * Variable names in map_{alloc,free}:
 *  *_idx == Index into `alloc_bitmap' array.
 *  *_off == Bit offset within an element of the `alloc_bitmap' array.
 */

static void map_alloc(unsigned long first_page, unsigned long nr_pages)
{
    unsigned long start_off, end_off, curr_idx, end_idx;

    curr_idx  = first_page / PAGES_PER_MAPWORD;
    start_off = first_page & (PAGES_PER_MAPWORD-1);
    end_idx   = (first_page + nr_pages) / PAGES_PER_MAPWORD;
    end_off   = (first_page + nr_pages) & (PAGES_PER_MAPWORD-1);

    if ( curr_idx == end_idx )
    {
        alloc_bitmap[curr_idx] |= ((1UL<<end_off)-1) & -(1UL<<start_off);
    }
    else 
    {
        alloc_bitmap[curr_idx] |= -(1UL<<start_off);
        while ( ++curr_idx < end_idx ) alloc_bitmap[curr_idx] = ~0UL;
        alloc_bitmap[curr_idx] |= (1UL<<end_off)-1;
    }
}


static void map_free(unsigned long first_page, unsigned long nr_pages)
{
    unsigned long start_off, end_off, curr_idx, end_idx;

    curr_idx = first_page / PAGES_PER_MAPWORD;
    start_off = first_page & (PAGES_PER_MAPWORD-1);
    end_idx   = (first_page + nr_pages) / PAGES_PER_MAPWORD;
    end_off   = (first_page + nr_pages) & (PAGES_PER_MAPWORD-1);

    if ( curr_idx == end_idx )
    {
        alloc_bitmap[curr_idx] &= -(1UL<<end_off) | ((1UL<<start_off)-1);
    }
    else 
    {
        alloc_bitmap[curr_idx] &= (1UL<<start_off)-1;
        while ( ++curr_idx != end_idx ) alloc_bitmap[curr_idx] = 0;
        alloc_bitmap[curr_idx] &= -(1UL<<end_off);
    }
}



/*************************
 * BINARY BUDDY ALLOCATOR
 */

typedef struct chunk_head_st chunk_head_t;
typedef struct chunk_tail_st chunk_tail_t;

struct chunk_head_st {
    chunk_head_t  *next;
    chunk_head_t **pprev;
    int            level;
};

struct chunk_tail_st {
    int level;
};

/* Linked lists of free chunks of different powers-of-two in size. */
#define FREELIST_SIZE ((sizeof(void*)<<3)-PAGE_SHIFT)
static chunk_head_t *free_head[FREELIST_SIZE];
static chunk_head_t  free_tail[FREELIST_SIZE];
#define FREELIST_EMPTY(_l) ((_l)->next == NULL)

#define round_pgdown(_p)  ((_p)&PAGE_MASK)
#define round_pgup(_p)    (((_p)+(PAGE_SIZE-1))&PAGE_MASK)

#ifdef MM_DEBUG
/*
 * Prints allocation[0/1] for @nr_pages, starting at @start
 * address (virtual).
 */
USED static void print_allocation(void *start, int nr_pages)
{
    unsigned long pfn_start = virt_to_pfn(start);
    int count;
    for(count = 0; count < nr_pages; count++)
        if(allocated_in_map(pfn_start + count)) printk("1");
        else printk("0");
        
    printk("\n");        
}

/*
 * Prints chunks (making them with letters) for @nr_pages starting
 * at @start (virtual).
 */
USED static void print_chunks(void *start, int nr_pages)
{
    char chunks[1001], current='A';
    int order, count;
    chunk_head_t *head;
    unsigned long pfn_start = virt_to_pfn(start);
   
    memset(chunks, (int)'_', 1000);
    if(nr_pages > 1000) 
    {
        DEBUG("Can only pring 1000 pages. Increase buffer size.");
    }
    
    for(order=0; order < FREELIST_SIZE; order++)
    {
        head = free_head[order];
        while(!FREELIST_EMPTY(head))
        {
            for(count = 0; count < 1UL<< head->level; count++)
            {
                if(count + virt_to_pfn(head) - pfn_start < 1000)
                    chunks[count + virt_to_pfn(head) - pfn_start] = current;
            }
            head = head->next;
            current++;
        }
    }
    chunks[nr_pages] = '\0';
    printk("%s\n", chunks);
}
#endif


/*
 * Initialise allocator, placing addresses [@min,@max] in free pool.
 * @min and @max are PHYSICAL addresses.
 */
static void init_page_allocator(unsigned long min, unsigned long max)
{
    int i;
    unsigned long range, bitmap_size;
    chunk_head_t *ch;
    chunk_tail_t *ct;
    for ( i = 0; i < FREELIST_SIZE; i++ )
    {
        free_head[i]       = &free_tail[i];
        free_tail[i].pprev = &free_head[i];
        free_tail[i].next  = NULL;
    }

    min = round_pgup  (min);
    max = round_pgdown(max);

    /* Allocate space for the allocation bitmap. */
    bitmap_size  = (max+1) >> (PAGE_SHIFT+3);
    bitmap_size  = round_pgup(bitmap_size);
    alloc_bitmap = (unsigned long *)to_virt(min);
    min         += bitmap_size;
    range        = max - min;

    /* All allocated by default. */
    memset(alloc_bitmap, ~0, bitmap_size);
    /* Free up the memory we've been given to play with. */
    map_free(PHYS_PFN(min), range>>PAGE_SHIFT);

    /* The buddy lists are addressed in high memory. */
    min = (unsigned long) to_virt(min);
    max = (unsigned long) to_virt(max);

    while ( range != 0 )
    {
        /*
         * Next chunk is limited by alignment of min, but also
         * must not be bigger than remaining range.
         */
        for ( i = PAGE_SHIFT; (1UL<<(i+1)) <= range; i++ )
            if ( min & (1UL<<i) ) break;


        ch = (chunk_head_t *)min;
        min   += (1UL<<i);
        range -= (1UL<<i);
        ct = (chunk_tail_t *)min-1;
        i -= PAGE_SHIFT;
        ch->level       = i;
        ch->next        = free_head[i];
        ch->pprev       = &free_head[i];
        ch->next->pprev = &ch->next;
        free_head[i]    = ch;
        ct->level       = i;
    }
}


/* Allocate 2^@order contiguous pages. Returns a VIRTUAL address. */
unsigned long alloc_pages(int order)
{
    int i;
    chunk_head_t *alloc_ch, *spare_ch;
    chunk_tail_t            *spare_ct;


    /* Find smallest order which can satisfy the request. */
    for ( i = order; i < FREELIST_SIZE; i++ ) {
	if ( !FREELIST_EMPTY(free_head[i]) ) 
	    break;
    }

    if ( i == FREELIST_SIZE ) goto no_memory;
 
    /* Unlink a chunk. */
    alloc_ch = free_head[i];
    free_head[i] = alloc_ch->next;
    alloc_ch->next->pprev = alloc_ch->pprev;

    /* We may have to break the chunk a number of times. */
    while ( i != order )
    {
        /* Split into two equal parts. */
        i--;
        spare_ch = (chunk_head_t *)((char *)alloc_ch + (1UL<<(i+PAGE_SHIFT)));
        spare_ct = (chunk_tail_t *)((char *)spare_ch + (1UL<<(i+PAGE_SHIFT)))-1;

        /* Create new header for spare chunk. */
        spare_ch->level = i;
        spare_ch->next  = free_head[i];
        spare_ch->pprev = &free_head[i];
        spare_ct->level = i;

        /* Link in the spare chunk. */
        spare_ch->next->pprev = &spare_ch->next;
        free_head[i] = spare_ch;
    }
    
    map_alloc(PHYS_PFN(to_phys(alloc_ch)), 1UL<<order);

    return((unsigned long)alloc_ch);

 no_memory:

    printk("Cannot handle page request order %d!\n", order);

    return 0;
}

void free_pages(void *pointer, int order)
{
    chunk_head_t *freed_ch, *to_merge_ch;
    chunk_tail_t *freed_ct;
    unsigned long mask;
    
    /* First free the chunk */
    map_free(virt_to_pfn(pointer), 1UL << order);
    
    /* Create free chunk */
    freed_ch = (chunk_head_t *)pointer;
    freed_ct = (chunk_tail_t *)((char *)pointer + (1UL<<(order + PAGE_SHIFT)))-1;
    
    /* Now, possibly we can conseal chunks together */
    while(order < FREELIST_SIZE)
    {
        mask = 1UL << (order + PAGE_SHIFT);
        if((unsigned long)freed_ch & mask) 
        {
            to_merge_ch = (chunk_head_t *)((char *)freed_ch - mask);
            if(allocated_in_map(virt_to_pfn(to_merge_ch)) ||
                    to_merge_ch->level != order)
                break;
            
            /* Merge with predecessor */
            freed_ch = to_merge_ch;   
        }
        else 
        {
            to_merge_ch = (chunk_head_t *)((char *)freed_ch + mask);
            if(allocated_in_map(virt_to_pfn(to_merge_ch)) ||
                    to_merge_ch->level != order)
                break;
            
            /* Merge with successor */
            freed_ct = (chunk_tail_t *)((char *)to_merge_ch + mask) - 1;
        }
        
        /* We are commited to merging, unlink the chunk */
        *(to_merge_ch->pprev) = to_merge_ch->next;
        to_merge_ch->next->pprev = to_merge_ch->pprev;
        
        order++;
    }

    /* Link the new chunk */
    freed_ch->level = order;
    freed_ch->next  = free_head[order];
    freed_ch->pprev = &free_head[order];
    freed_ct->level = order;
    
    freed_ch->next->pprev = &freed_ch->next;
    free_head[order] = freed_ch;   
   
}

#ifndef __ia64__
int free_physical_pages(xen_pfn_t *mfns, int n)
{
    struct xen_memory_reservation reservation;

    set_xen_guest_handle(reservation.extent_start, mfns);
    reservation.nr_extents = n;
    reservation.extent_order = 0;
    reservation.domid = DOMID_SELF;
    return HYPERVISOR_memory_op(XENMEM_decrease_reservation, &reservation);
}
#endif

#ifdef HAVE_LIBC
void *sbrk(ptrdiff_t increment)
{
    unsigned long old_brk = brk;
    unsigned long new_brk = old_brk + increment;

    if (new_brk > heap_end) {
	printk("Heap exhausted: %p + %lx = %p > %p\n", old_brk, increment, new_brk, heap_end);
	return NULL;
    }
    
    if (new_brk > heap_mapped) {
        unsigned long n = (new_brk - heap_mapped + PAGE_SIZE - 1) / PAGE_SIZE;
        do_map_zero(heap_mapped, n);
        heap_mapped += n * PAGE_SIZE;
    }

    brk = new_brk;

    return (void *) old_brk;
}
#endif



void init_mm(void)
{

    unsigned long start_pfn, max_pfn;

    printk("MM: Init\n");

    arch_init_mm(&start_pfn, &max_pfn);
    /*
     * now we can initialise the page allocator
     */
    printk("MM: Initialise page allocator for %lx(%lx)-%lx(%lx)\n",
           (u_long)to_virt(PFN_PHYS(start_pfn)), PFN_PHYS(start_pfn), 
           (u_long)to_virt(PFN_PHYS(max_pfn)), PFN_PHYS(max_pfn));
    init_page_allocator(PFN_PHYS(start_pfn), PFN_PHYS(max_pfn));
    printk("MM: done\n");

    arch_init_p2m(max_pfn);
    
    arch_init_demand_mapping_area(max_pfn);
}

void fini_mm(void)
{
}

void sanity_check(void)
{
    int x;
    chunk_head_t *head;

    for (x = 0; x < FREELIST_SIZE; x++) {
        for (head = free_head[x]; !FREELIST_EMPTY(head); head = head->next) {
            ASSERT(!allocated_in_map(virt_to_pfn(head)));
            if (head->next)
                ASSERT(head->next->pprev == &head->next);
        }
        if (free_head[x]) {
            ASSERT(free_head[x]->pprev == &free_head[x]);
        }
    }
}
