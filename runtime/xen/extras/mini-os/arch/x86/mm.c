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
#include <mini-os/mm.h>
#include <mini-os/types.h>
#include <mini-os/lib.h>
#include <mini-os/xmalloc.h>
#include <xen/memory.h>

#ifdef MM_DEBUG
#define DEBUG(_f, _a...) \
    printk("MINI_OS(file=mm.c, line=%d) " _f "\n", __LINE__, ## _a)
#else
#define DEBUG(_f, _a...)    ((void)0)
#endif

unsigned long *phys_to_machine_mapping;
unsigned long mfn_zero;
extern char stack[];
extern void page_walk(unsigned long va);

/*
 * Make pt_pfn a new 'level' page table frame and hook it into the page
 * table at offset in previous level MFN (pref_l_mfn). pt_pfn is a guest
 * PFN.
 */
static void new_pt_frame(unsigned long *pt_pfn, unsigned long prev_l_mfn, 
                         unsigned long offset, unsigned long level)
{   
    pgentry_t *tab = (pgentry_t *)start_info.pt_base;
    unsigned long pt_page = (unsigned long)pfn_to_virt(*pt_pfn); 
    pgentry_t prot_e, prot_t;
    mmu_update_t mmu_updates[1];
    int rc;
    
    prot_e = prot_t = 0;
    DEBUG("Allocating new L%d pt frame for pfn=%lx, "
          "prev_l_mfn=%lx, offset=%lx", 
          level, *pt_pfn, prev_l_mfn, offset);

    /* We need to clear the page, otherwise we might fail to map it
       as a page table page */
    memset((void*) pt_page, 0, PAGE_SIZE);  
 
    switch ( level )
    {
    case L1_FRAME:
        prot_e = L1_PROT;
        prot_t = L2_PROT;
        break;
    case L2_FRAME:
        prot_e = L2_PROT;
        prot_t = L3_PROT;
        break;
#if defined(__x86_64__)
    case L3_FRAME:
        prot_e = L3_PROT;
        prot_t = L4_PROT;
        break;
#endif
    default:
        printk("new_pt_frame() called with invalid level number %d\n", level);
        do_exit();
        break;
    }

    /* Make PFN a page table page */
#if defined(__x86_64__)
    tab = pte_to_virt(tab[l4_table_offset(pt_page)]);
#endif
    tab = pte_to_virt(tab[l3_table_offset(pt_page)]);

    mmu_updates[0].ptr = (tab[l2_table_offset(pt_page)] & PAGE_MASK) + 
        sizeof(pgentry_t) * l1_table_offset(pt_page);
    mmu_updates[0].val = (pgentry_t)pfn_to_mfn(*pt_pfn) << PAGE_SHIFT | 
        (prot_e & ~_PAGE_RW);
    
    if ( (rc = HYPERVISOR_mmu_update(mmu_updates, 1, NULL, DOMID_SELF)) < 0 )
    {
        printk("ERROR: PTE for new page table page could not be updated\n");
        printk("       mmu_update failed with rc=%d\n", rc);
        do_exit();
    }

    /* Hook the new page table page into the hierarchy */
    mmu_updates[0].ptr =
        ((pgentry_t)prev_l_mfn << PAGE_SHIFT) + sizeof(pgentry_t) * offset;
    mmu_updates[0].val = (pgentry_t)pfn_to_mfn(*pt_pfn) << PAGE_SHIFT | prot_t;

    if ( (rc = HYPERVISOR_mmu_update(mmu_updates, 1, NULL, DOMID_SELF)) < 0 ) 
    {
        printk("ERROR: mmu_update failed with rc=%d\n", rc);
        do_exit();
    }

    *pt_pfn += 1;
}

/*
 * Checks if a pagetable frame is needed at 'level' to map a given
 * address. Note, this function is specific to the initial page table
 * building.
 */
static int need_pt_frame(unsigned long va, int level)
{
    unsigned long hyp_virt_start = HYPERVISOR_VIRT_START;
#if defined(__x86_64__)
    unsigned long hyp_virt_end = HYPERVISOR_VIRT_END;
#else
    unsigned long hyp_virt_end = 0xffffffff;
#endif

    /* In general frames will _not_ be needed if they were already
       allocated to map the hypervisor into our VA space */
#if defined(__x86_64__)
    if ( level == L3_FRAME )
    {
        if ( l4_table_offset(va) >= 
             l4_table_offset(hyp_virt_start) &&
             l4_table_offset(va) <= 
             l4_table_offset(hyp_virt_end))
            return 0;
        return 1;
    } 
    else
#endif

    if ( level == L2_FRAME )
    {
#if defined(__x86_64__)
        if ( l4_table_offset(va) >= 
             l4_table_offset(hyp_virt_start) &&
             l4_table_offset(va) <= 
             l4_table_offset(hyp_virt_end))
#endif
            if ( l3_table_offset(va) >= 
                 l3_table_offset(hyp_virt_start) &&
                 l3_table_offset(va) <= 
                 l3_table_offset(hyp_virt_end))
                return 0;

        return 1;
    } 
    else 
        /* Always need l1 frames */
        if ( level == L1_FRAME )
            return 1;

    printk("ERROR: Unknown frame level %d, hypervisor %llx,%llx\n", 
           level, hyp_virt_start, hyp_virt_end);
    return -1;
}

/*
 * Build the initial pagetable.
 */
static void build_pagetable(unsigned long *start_pfn, unsigned long *max_pfn)
{
    unsigned long start_address, end_address;
    unsigned long pfn_to_map, pt_pfn = *start_pfn;
    static mmu_update_t mmu_updates[L1_PAGETABLE_ENTRIES + 1];
    pgentry_t *tab = (pgentry_t *)start_info.pt_base, page;
    unsigned long pt_mfn = pfn_to_mfn(virt_to_pfn(start_info.pt_base));
    unsigned long offset;
    int count = 0;
    int rc;

    pfn_to_map = 
        (start_info.nr_pt_frames - NOT_L1_FRAMES) * L1_PAGETABLE_ENTRIES;

    if ( *max_pfn >= virt_to_pfn(HYPERVISOR_VIRT_START) )
    {
        printk("WARNING: Mini-OS trying to use Xen virtual space. "
               "Truncating memory from %dMB to ",
               ((unsigned long)pfn_to_virt(*max_pfn) -
                (unsigned long)&_text)>>20);
        *max_pfn = virt_to_pfn(HYPERVISOR_VIRT_START - PAGE_SIZE);
        printk("%dMB\n",
               ((unsigned long)pfn_to_virt(*max_pfn) - 
                (unsigned long)&_text)>>20);
    }

    start_address = (unsigned long)pfn_to_virt(pfn_to_map);
    end_address = (unsigned long)pfn_to_virt(*max_pfn);

    /* We worked out the virtual memory range to map, now mapping loop */
    printk("Mapping memory range 0x%lx - 0x%lx\n", start_address, end_address);

    while ( start_address < end_address )
    {
        tab = (pgentry_t *)start_info.pt_base;
        pt_mfn = pfn_to_mfn(virt_to_pfn(start_info.pt_base));

#if defined(__x86_64__)
        offset = l4_table_offset(start_address);
        /* Need new L3 pt frame */
        if ( !(start_address & L3_MASK) )
            if ( need_pt_frame(start_address, L3_FRAME) ) 
                new_pt_frame(&pt_pfn, pt_mfn, offset, L3_FRAME);

        page = tab[offset];
        pt_mfn = pte_to_mfn(page);
        tab = to_virt(mfn_to_pfn(pt_mfn) << PAGE_SHIFT);
#endif
        offset = l3_table_offset(start_address);
        /* Need new L2 pt frame */
        if ( !(start_address & L2_MASK) )
            if ( need_pt_frame(start_address, L2_FRAME) )
                new_pt_frame(&pt_pfn, pt_mfn, offset, L2_FRAME);

        page = tab[offset];
        pt_mfn = pte_to_mfn(page);
        tab = to_virt(mfn_to_pfn(pt_mfn) << PAGE_SHIFT);
        offset = l2_table_offset(start_address);        
        /* Need new L1 pt frame */
        if ( !(start_address & L1_MASK) )
            if ( need_pt_frame(start_address, L1_FRAME) )
                new_pt_frame(&pt_pfn, pt_mfn, offset, L1_FRAME);

        page = tab[offset];
        pt_mfn = pte_to_mfn(page);
        offset = l1_table_offset(start_address);

        mmu_updates[count].ptr =
            ((pgentry_t)pt_mfn << PAGE_SHIFT) + sizeof(pgentry_t) * offset;
        mmu_updates[count].val = 
            (pgentry_t)pfn_to_mfn(pfn_to_map++) << PAGE_SHIFT | L1_PROT;
        count++;
        if ( count == L1_PAGETABLE_ENTRIES || pfn_to_map == *max_pfn )
        {
            rc = HYPERVISOR_mmu_update(mmu_updates, count, NULL, DOMID_SELF);
            if ( rc < 0 )
            {
                printk("ERROR: build_pagetable(): PTE could not be updated\n");
                printk("       mmu_update failed with rc=%d\n", rc);
                do_exit();
            }
            count = 0;
        }
        start_address += PAGE_SIZE;
    }

    *start_pfn = pt_pfn;
}

/*
 * Mark portion of the address space read only.
 */
extern void shared_info;
static void set_readonly(void *text, void *etext)
{
    unsigned long start_address =
        ((unsigned long) text + PAGE_SIZE - 1) & PAGE_MASK;
    unsigned long end_address = (unsigned long) etext;
    static mmu_update_t mmu_updates[L1_PAGETABLE_ENTRIES + 1];
    pgentry_t *tab = (pgentry_t *)start_info.pt_base, page;
    unsigned long mfn = pfn_to_mfn(virt_to_pfn(start_info.pt_base));
    unsigned long offset;
    int count = 0;
    int rc;

    printk("setting %p-%p readonly\n", text, etext);

    while ( start_address + PAGE_SIZE <= end_address )
    {
        tab = (pgentry_t *)start_info.pt_base;
        mfn = pfn_to_mfn(virt_to_pfn(start_info.pt_base));

#if defined(__x86_64__)
        offset = l4_table_offset(start_address);
        page = tab[offset];
        mfn = pte_to_mfn(page);
        tab = to_virt(mfn_to_pfn(mfn) << PAGE_SHIFT);
#endif
        offset = l3_table_offset(start_address);
        page = tab[offset];
        mfn = pte_to_mfn(page);
        tab = to_virt(mfn_to_pfn(mfn) << PAGE_SHIFT);
        offset = l2_table_offset(start_address);        
        page = tab[offset];
        mfn = pte_to_mfn(page);
        tab = to_virt(mfn_to_pfn(mfn) << PAGE_SHIFT);

        offset = l1_table_offset(start_address);

        if ( start_address != (unsigned long)&shared_info )
        {
            mmu_updates[count].ptr = 
                ((pgentry_t)mfn << PAGE_SHIFT) + sizeof(pgentry_t) * offset;
            mmu_updates[count].val = tab[offset] & ~_PAGE_RW;
            count++;
        }
        else
            printk("skipped %p\n", start_address);

        start_address += PAGE_SIZE;

        if ( count == L1_PAGETABLE_ENTRIES || 
             start_address + PAGE_SIZE > end_address )
        {
            rc = HYPERVISOR_mmu_update(mmu_updates, count, NULL, DOMID_SELF);
            if ( rc < 0 )
            {
                printk("ERROR: set_readonly(): PTE could not be updated\n");
                do_exit();
            }
            count = 0;
        }
    }

    {
        mmuext_op_t op = {
            .cmd = MMUEXT_TLB_FLUSH_ALL,
        };
        int count;
        HYPERVISOR_mmuext_op(&op, 1, &count, DOMID_SELF);
    }
}

/*
 * A useful mem testing function. Write the address to every address in the
 * range provided and read back the value. If verbose, print page walk to
 * some VA
 * 
 * If we get MEM_TEST_MAX_ERRORS we might as well stop
 */
#define MEM_TEST_MAX_ERRORS 10 
int mem_test(unsigned long *start_va, unsigned long *end_va, int verbose)
{
    unsigned long mask = 0x10000;
    unsigned long *pointer;
    int error_count = 0;
 
    /* write values and print page walks */
    if ( verbose && (((unsigned long)start_va) & 0xfffff) )
    {
        printk("MemTest Start: 0x%lx\n", start_va);
        page_walk((unsigned long)start_va);
    }
    for ( pointer = start_va; pointer < end_va; pointer++ )
    {
        if ( verbose && !(((unsigned long)pointer) & 0xfffff) )
        {
            printk("Writing to %lx\n", pointer);
            page_walk((unsigned long)pointer);
        }
        *pointer = (unsigned long)pointer & ~mask;
    }
    if ( verbose && (((unsigned long)end_va) & 0xfffff) )
    {
        printk("MemTest End: %lx\n", end_va-1);
        page_walk((unsigned long)end_va-1);
    }
 
    /* verify values */
    for ( pointer = start_va; pointer < end_va; pointer++ )
    {
        if ( ((unsigned long)pointer & ~mask) != *pointer )
        {
            printk("Read error at 0x%lx. Read: 0x%lx, should read 0x%lx\n",
                   (unsigned long)pointer, *pointer, 
                   ((unsigned long)pointer & ~mask));
            error_count++;
            if ( error_count >= MEM_TEST_MAX_ERRORS )
            {
                printk("mem_test: too many errors\n");
                return -1;
            }
        }
    }
    return 0;
}


/*
 * get the PTE for virtual address va if it exists. Otherwise NULL.
 */
static pgentry_t *get_pgt(unsigned long va)
{
    unsigned long mfn;
    pgentry_t *tab;
    unsigned offset;

    tab = (pgentry_t *)start_info.pt_base;
    mfn = virt_to_mfn(start_info.pt_base);

#if defined(__x86_64__)
    offset = l4_table_offset(va);
    if ( !(tab[offset] & _PAGE_PRESENT) )
        return NULL;
    mfn = pte_to_mfn(tab[offset]);
    tab = mfn_to_virt(mfn);
#endif
    offset = l3_table_offset(va);
    if ( !(tab[offset] & _PAGE_PRESENT) )
        return NULL;
    mfn = pte_to_mfn(tab[offset]);
    tab = mfn_to_virt(mfn);
    offset = l2_table_offset(va);
    if ( !(tab[offset] & _PAGE_PRESENT) )
        return NULL;
    mfn = pte_to_mfn(tab[offset]);
    tab = mfn_to_virt(mfn);
    offset = l1_table_offset(va);
    return &tab[offset];
}


/*
 * return a valid PTE for a given virtual address. If PTE does not exist,
 * allocate page-table pages.
 */
pgentry_t *need_pgt(unsigned long va)
{
    unsigned long pt_mfn;
    pgentry_t *tab;
    unsigned long pt_pfn;
    unsigned offset;

    tab = (pgentry_t *)start_info.pt_base;
    pt_mfn = virt_to_mfn(start_info.pt_base);

#if defined(__x86_64__)
    offset = l4_table_offset(va);
    if ( !(tab[offset] & _PAGE_PRESENT) )
    {
        pt_pfn = virt_to_pfn(alloc_page());
        new_pt_frame(&pt_pfn, pt_mfn, offset, L3_FRAME);
    }
    ASSERT(tab[offset] & _PAGE_PRESENT);
    pt_mfn = pte_to_mfn(tab[offset]);
    tab = mfn_to_virt(pt_mfn);
#endif
    offset = l3_table_offset(va);
    if ( !(tab[offset] & _PAGE_PRESENT) ) 
    {
        pt_pfn = virt_to_pfn(alloc_page());
        new_pt_frame(&pt_pfn, pt_mfn, offset, L2_FRAME);
    }
    ASSERT(tab[offset] & _PAGE_PRESENT);
    pt_mfn = pte_to_mfn(tab[offset]);
    tab = mfn_to_virt(pt_mfn);
    offset = l2_table_offset(va);
    if ( !(tab[offset] & _PAGE_PRESENT) )
    {
        pt_pfn = virt_to_pfn(alloc_page());
        new_pt_frame(&pt_pfn, pt_mfn, offset, L1_FRAME);
    }
    ASSERT(tab[offset] & _PAGE_PRESENT);
    pt_mfn = pte_to_mfn(tab[offset]);
    tab = mfn_to_virt(pt_mfn);

    offset = l1_table_offset(va);
    return &tab[offset];
}

/*
 * Reserve an area of virtual address space for mappings and Heap
 */
static unsigned long demand_map_area_start;
#ifdef __x86_64__
#define DEMAND_MAP_PAGES ((128ULL << 30) / PAGE_SIZE)
#else
#define DEMAND_MAP_PAGES ((2ULL << 30) / PAGE_SIZE)
#endif

#ifndef HAVE_LIBC
#define HEAP_PAGES 0
#else
unsigned long heap, brk, heap_mapped, heap_end;
#ifdef __x86_64__
#define HEAP_PAGES ((128ULL << 30) / PAGE_SIZE)
#else
#define HEAP_PAGES ((1ULL << 30) / PAGE_SIZE)
#endif
#endif

void arch_init_demand_mapping_area(unsigned long cur_pfn)
{
    cur_pfn++;

    demand_map_area_start = (unsigned long) pfn_to_virt(cur_pfn);
    cur_pfn += DEMAND_MAP_PAGES;
    printk("Demand map pfns at %lx-%lx.\n", 
           demand_map_area_start, pfn_to_virt(cur_pfn));

#ifdef HAVE_LIBC
    cur_pfn++;
    heap_mapped = brk = heap = (unsigned long) pfn_to_virt(cur_pfn);
    cur_pfn += HEAP_PAGES;
    heap_end = (unsigned long) pfn_to_virt(cur_pfn);
    printk("Heap resides at %lx-%lx.\n", brk, heap_end);
#endif
}

unsigned long allocate_ondemand(unsigned long n, unsigned long alignment)
{
    unsigned long x;
    unsigned long y = 0;

    /* Find a properly aligned run of n contiguous frames */
    for ( x = 0;
          x <= DEMAND_MAP_PAGES - n; 
          x = (x + y + 1 + alignment - 1) & ~(alignment - 1) )
    {
        unsigned long addr = demand_map_area_start + x * PAGE_SIZE;
        pgentry_t *pgt = get_pgt(addr);
        for ( y = 0; y < n; y++, addr += PAGE_SIZE ) 
        {
            if ( !(addr & L1_MASK) )
                pgt = get_pgt(addr);
            if ( pgt )
            {
                if ( *pgt & _PAGE_PRESENT )
                    break;
                pgt++;
            }
        }
        if ( y == n )
            break;
    }
    if ( y != n )
    {
        printk("Failed to find %ld frames!\n", n);
        return 0;
    }
    return demand_map_area_start + x * PAGE_SIZE;
}

/*
 * Map an array of MFNs contiguously into virtual address space starting at
 * va. map f[i*stride]+i*increment for i in 0..n-1.
 */
#define MAP_BATCH ((STACK_SIZE / 2) / sizeof(mmu_update_t))
void do_map_frames(unsigned long va,
                   unsigned long *mfns, unsigned long n, 
                   unsigned long stride, unsigned long incr, 
                   domid_t id, int may_fail,
                   unsigned long prot)
{
    pgentry_t *pgt = NULL;
    unsigned long done = 0;
    unsigned long i;
    int rc;

    if ( !mfns ) 
    {
        printk("do_map_frames: no mfns supplied\n");
        return;
    }
    DEBUG("va=%p n=0x%lx, mfns[0]=0x%lx stride=0x%lx incr=0x%lx prot=0x%lx\n",
          va, n, mfns[0], stride, incr, prot);
 
    while ( done < n )
    {
        unsigned long todo;

        if ( may_fail )
            todo = 1;
        else
            todo = n - done;

        if ( todo > MAP_BATCH )
            todo = MAP_BATCH;

        {
            mmu_update_t mmu_updates[todo];

            for ( i = 0; i < todo; i++, va += PAGE_SIZE, pgt++) 
            {
                if ( !pgt || !(va & L1_MASK) )
                    pgt = need_pgt(va);
                
                mmu_updates[i].ptr = virt_to_mach(pgt) | MMU_NORMAL_PT_UPDATE;
                mmu_updates[i].val = ((pgentry_t)(mfns[(done + i) * stride] +
                                                  (done + i) * incr)
                                      << PAGE_SHIFT) | prot;
            }

            rc = HYPERVISOR_mmu_update(mmu_updates, todo, NULL, id);
            if ( rc < 0 )
            {
                if (may_fail)
                    mfns[done * stride] |= 0xF0000000;
                else {
                    printk("Map %ld (%lx, ...) at %p failed: %d.\n",
                           todo, mfns[done * stride] + done * incr, va, rc);
                    do_exit();
                }
            }
        }
        done += todo;
    }
}

/*
 * Map an array of MFNs contiguous into virtual address space. Virtual
 * addresses are allocated from the on demand area.
 */
void *map_frames_ex(unsigned long *mfns, unsigned long n, 
                    unsigned long stride, unsigned long incr,
                    unsigned long alignment,
                    domid_t id, int may_fail, unsigned long prot)
{
    unsigned long va = allocate_ondemand(n, alignment);

    if ( !va )
        return NULL;

    do_map_frames(va, mfns, n, stride, incr, id, may_fail, prot);

    return (void *)va;
}

/*
 * Unmap nun_frames frames mapped at virtual address va.
 */
#define UNMAP_BATCH ((STACK_SIZE / 2) / sizeof(multicall_entry_t))
int unmap_frames(unsigned long va, unsigned long num_frames)
{
    int n = UNMAP_BATCH;
    multicall_entry_t call[n];
    int ret;
    int i;

    ASSERT(!((unsigned long)va & ~PAGE_MASK));

    DEBUG("va=%p, num=0x%lx\n", va, num_frames);

    while ( num_frames ) {
        if ( n > num_frames )
            n = num_frames;

        for ( i = 0; i < n; i++ )
        {
            int arg = 0;
            /* simply update the PTE for the VA and invalidate TLB */
            call[i].op = __HYPERVISOR_update_va_mapping;
            call[i].args[arg++] = va;
            call[i].args[arg++] = 0;
#ifdef __i386__
            call[i].args[arg++] = 0;
#endif  
            call[i].args[arg++] = UVMF_INVLPG;

            va += PAGE_SIZE;
        }

        ret = HYPERVISOR_multicall(call, n);
        if ( ret )
        {
            printk("update_va_mapping hypercall failed with rc=%d.\n", ret);
            return -ret;
        }

        for ( i = 0; i < n; i++ )
        {
            if ( call[i].result ) 
            {
                printk("update_va_mapping failed for with rc=%d.\n", ret);
                return -(call[i].result);
            }
        }
        num_frames -= n;
    }
    return 0;
}

/*
 * Allocate pages which are contiguous in machine memory.
 * Returns a VA to where they are mapped or 0 on failure.
 * 
 * addr_bits indicates if the region has restrictions on where it is
 * located. Typical values are 32 (if for example PCI devices can't access
 * 64bit memory) or 0 for no restrictions.
 *
 * Allocated pages can be freed using the page allocators free_pages() 
 * function.
 *
 * based on Linux function xen_create_contiguous_region()
 */
#define MAX_CONTIG_ORDER 9 /* 2MB */
unsigned long alloc_contig_pages(int order, unsigned int addr_bits)
{
    unsigned long in_va, va;
    unsigned long in_frames[1UL << order], out_frames, mfn;
    multicall_entry_t call[1UL << order];
    unsigned int i, num_pages = 1UL << order;
    int ret, exch_success;

    /* pass in num_pages 'extends' of size 1 and
     * request 1 extend of size 'order */
    struct xen_memory_exchange exchange = {
        .in = {
            .nr_extents   = num_pages,
            .extent_order = 0,
            .domid        = DOMID_SELF
        },
        .out = {
            .nr_extents   = 1,
            .extent_order = order,
            .address_bits = addr_bits,
            .domid        = DOMID_SELF
        },
        .nr_exchanged = 0
    };

    if ( order > MAX_CONTIG_ORDER )
    {
        printk("alloc_contig_pages: order too large 0x%x > 0x%x\n",
               order, MAX_CONTIG_ORDER);
        return 0;
    }

    /* Allocate some potentially discontiguous pages */
    in_va = alloc_pages(order);
    if ( !in_va )
    {
        printk("alloc_contig_pages: could not get enough pages (order=0x%x\n",
               order);
        return 0;
    }

    /* set up arguments for exchange hyper call */
    set_xen_guest_handle(exchange.in.extent_start, in_frames);
    set_xen_guest_handle(exchange.out.extent_start, &out_frames);

    /* unmap current frames, keep a list of MFNs */
    for ( i = 0; i < num_pages; i++ )
    {
        int arg = 0;

        va = in_va + (PAGE_SIZE * i);
        in_frames[i] = virt_to_mfn(va);

        /* update P2M mapping */
        phys_to_machine_mapping[virt_to_pfn(va)] = INVALID_P2M_ENTRY;

        /* build multi call */
        call[i].op = __HYPERVISOR_update_va_mapping;
        call[i].args[arg++] = va;
        call[i].args[arg++] = 0;
#ifdef __i386__
        call[i].args[arg++] = 0;
#endif  
        call[i].args[arg++] = UVMF_INVLPG;
    }

    ret = HYPERVISOR_multicall(call, i);
    if ( ret )
    {
        printk("Odd, update_va_mapping hypercall failed with rc=%d.\n", ret);
        return 0;
    }

    /* try getting a contig range of MFNs */
    out_frames = virt_to_pfn(in_va); /* PFNs to populate */
    ret = HYPERVISOR_memory_op(XENMEM_exchange, &exchange);
    if ( ret ) {
        printk("mem exchanged order=0x%x failed with rc=%d, nr_exchanged=%d\n", 
               order, ret, exchange.nr_exchanged);
        /* we still need to return the allocated pages above to the pool
         * ie. map them back into the 1:1 mapping etc. so we continue but 
         * in the end return the pages to the page allocator and return 0. */
        exch_success = 0;
    }
    else
        exch_success = 1;

    /* map frames into 1:1 and update p2m */
    for ( i = 0; i < num_pages; i++ )
    {
        int arg = 0;
        pte_t pte;

        va = in_va + (PAGE_SIZE * i);
        mfn = i < exchange.nr_exchanged ? (out_frames + i) : in_frames[i];
        pte = __pte(mfn << PAGE_SHIFT | L1_PROT);

        /* update P2M mapping */
        phys_to_machine_mapping[virt_to_pfn(va)] = mfn;

        /* build multi call */
        call[i].op = __HYPERVISOR_update_va_mapping;
        call[i].args[arg++] = va;
#ifdef __x86_64__
        call[i].args[arg++] = (pgentry_t)pte.pte;
#else
        call[i].args[arg++] = pte.pte_low;
        call[i].args[arg++] = pte.pte_high;
#endif  
        call[i].args[arg++] = UVMF_INVLPG;
    }
    ret = HYPERVISOR_multicall(call, i);
    if ( ret )
    {
        printk("update_va_mapping hypercall no. 2 failed with rc=%d.\n", ret);
        return 0;
    }

    if ( !exch_success )
    {
        /* since the exchanged failed we just free the pages as well */
        free_pages((void *) in_va, order);
        return 0;
    }
    
    return in_va;
}

/*
 * Check if a given MFN refers to real memory
 */
static long system_ram_end_mfn;
int mfn_is_ram(unsigned long mfn)
{
    /* very crude check if a given MFN is memory or not. Probably should
     * make this a little more sophisticated ;) */
    return (mfn <= system_ram_end_mfn) ? 1 : 0;
}


/*
 * Clear some of the bootstrap memory
 */
static void clear_bootstrap(void)
{
    pte_t nullpte = { };
    int rc;

    /* Use first page as the CoW zero page */
    memset(&_text, 0, PAGE_SIZE);
    mfn_zero = virt_to_mfn((unsigned long) &_text);
    if ( (rc = HYPERVISOR_update_va_mapping(0, nullpte, UVMF_INVLPG)) )
        printk("Unable to unmap NULL page. rc=%d\n", rc);
}

void arch_init_p2m(unsigned long max_pfn)
{
#ifdef __x86_64__
#define L1_P2M_SHIFT    9
#define L2_P2M_SHIFT    18    
#define L3_P2M_SHIFT    27    
#else
#define L1_P2M_SHIFT    10
#define L2_P2M_SHIFT    20    
#define L3_P2M_SHIFT    30    
#endif
#define L1_P2M_ENTRIES  (1 << L1_P2M_SHIFT)    
#define L2_P2M_ENTRIES  (1 << (L2_P2M_SHIFT - L1_P2M_SHIFT))    
#define L3_P2M_ENTRIES  (1 << (L3_P2M_SHIFT - L2_P2M_SHIFT))    
#define L1_P2M_MASK     (L1_P2M_ENTRIES - 1)    
#define L2_P2M_MASK     (L2_P2M_ENTRIES - 1)    
#define L3_P2M_MASK     (L3_P2M_ENTRIES - 1)    
    
    unsigned long *l1_list = NULL, *l2_list = NULL, *l3_list;
    unsigned long pfn;
    
    l3_list = (unsigned long *)alloc_page(); 
    for ( pfn=0; pfn<max_pfn; pfn++ )
    {
        if ( !(pfn % (L1_P2M_ENTRIES * L2_P2M_ENTRIES)) )
        {
            l2_list = (unsigned long*)alloc_page();
            if ( (pfn >> L3_P2M_SHIFT) > 0 )
            {
                printk("Error: Too many pfns.\n");
                do_exit();
            }
            l3_list[(pfn >> L2_P2M_SHIFT)] = virt_to_mfn(l2_list);  
        }
        if ( !(pfn % (L1_P2M_ENTRIES)) )
        {
            l1_list = (unsigned long*)alloc_page();
            l2_list[(pfn >> L1_P2M_SHIFT) & L2_P2M_MASK] = 
                virt_to_mfn(l1_list); 
        }

        l1_list[pfn & L1_P2M_MASK] = pfn_to_mfn(pfn); 
    }
    HYPERVISOR_shared_info->arch.pfn_to_mfn_frame_list_list = 
        virt_to_mfn(l3_list);
    HYPERVISOR_shared_info->arch.max_pfn = max_pfn;
}

void arch_init_mm(unsigned long* start_pfn_p, unsigned long* max_pfn_p)
{
    unsigned long start_pfn, max_pfn;

    printk("      _text: %p(VA)\n", &_text);
    printk("     _etext: %p(VA)\n", &_etext);
    printk("   _erodata: %p(VA)\n", &_erodata);
    printk("     _edata: %p(VA)\n", &_edata);
    printk("stack start: %p(VA)\n", stack);
    printk("       _end: %p(VA)\n", &_end);

    /* First page follows page table pages and 3 more pages (store page etc) */
    start_pfn = PFN_UP(to_phys(start_info.pt_base)) + 
        start_info.nr_pt_frames + 3;
    max_pfn = start_info.nr_pages;

    /* We need room for demand mapping and heap, clip available memory */
#if defined(__i386__)
    {
        unsigned long virt_pfns = 1 + DEMAND_MAP_PAGES + 1 + HEAP_PAGES;
        if (max_pfn + virt_pfns >= 0x100000)
            max_pfn = 0x100000 - virt_pfns - 1;
    }
#endif

    printk("  start_pfn: %lx\n", start_pfn);
    printk("    max_pfn: %lx\n", max_pfn);

    build_pagetable(&start_pfn, &max_pfn);
    clear_bootstrap();
    set_readonly(&_text, &_erodata);

    /* get the number of physical pages the system has. Used to check for
     * system memory. */
    system_ram_end_mfn = HYPERVISOR_memory_op(XENMEM_maximum_ram_page, NULL);

    *start_pfn_p = start_pfn;
    *max_pfn_p = max_pfn;
}
