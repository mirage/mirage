/*
 * Done by Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com>
 *
 * Description: Special ia64 memory management.
 * Parts are taken from FreeBSD.
 *
 ****************************************************************************
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


#include <mini-os/os.h>
#include <mini-os/mm.h>


#define MAX_MEM_AREA	5
paddr_t phys_avail[MAX_MEM_AREA * 2];
int	phys_avail_cnt;
uint64_t physmem;

/*
 * These variables are defined in the linker script minios_ia64.lds
 * to get the size of the kernel.
 */
extern uint64_t _text[], _etext[], _end[], kstack[], phys_start[];

uint64_t kernstart, kernend, kernsize, kernpstart, kernpend;

#ifdef HAVE_LIBC
uint8_t _heap[512 * 1024];
unsigned long heap = (unsigned long)_heap,
              brk = (unsigned long)_heap,
              heap_mapped = (unsigned long)_heap + sizeof(_heap),
              heap_end = (unsigned long)_heap + sizeof(_heap);
#endif

/* Print the available memory chunks. */
static void
print_phys_avail(void)
{
	int i;

	printk("Physical memory chunk(s):\n");
	for (i = 0; phys_avail[i + 1] != 0; i += 2) {
		int size = phys_avail[i + 1] - phys_avail[i];
		printk("0x%08lx - 0x%08lx, %d bytes (%d pages)\n",
			phys_avail[i], phys_avail[i + 1] - 1,
			size, size / PAGE_SIZE);
	}
}

void
arch_init_mm(unsigned long* start_pfn_p, unsigned long* max_pfn_p)
{
	uint64_t ms, me;
	int i, j;
	uint64_t m, n;

	kernstart = trunc_page(_text);
	kernend  = roundup_page(_end);

	kernpstart = trunc_page(ia64_tpa(kernstart));
	kernpend = roundup_page(kernpstart + (kernend - kernstart));
	kernsize = kernpend - kernpstart;

	ms = roundup_page(machineFwG.mach_mem_start);
	me = trunc_page(machineFwG.mach_mem_start+machineFwG.mach_mem_size);
	memset((void*)phys_avail, 0, sizeof(phys_avail));
	/* 1. Check where the kernel lies in physical memory. */
	physmem = me - ms;
	if ((ms <= kernpend) && (kernpstart <= me)) {
		if (ms < kernpstart) {	/* There is a part before the kernel. */
			PRINT_BV("  Found chunk before kernel: 0x%lx - 0x%lx\n",
				 ms, kernpstart);
			phys_avail[phys_avail_cnt] = ms;
			phys_avail[phys_avail_cnt+1] = kernpstart;
			phys_avail_cnt += 2;
		}
		if (kernpend < me) {	/* There is a part behind the kernel. */
			PRINT_BV("  Found chunk behind kernel: 0x%lx - 0x%lx\n",
				 kernpend, me);
			phys_avail[phys_avail_cnt] = kernpend;
			phys_avail[phys_avail_cnt+1] = me;
			phys_avail_cnt += 2;
		}
	} else {	/* One big chunk */
		PRINT_BV("  Found big chunk: 0x%lx - 0x%lx\n", ms, me);
		phys_avail[phys_avail_cnt] = ms;
		phys_avail[phys_avail_cnt + 1] = me;
		phys_avail_cnt += 2;
	}
	phys_avail[phys_avail_cnt] = 0;

	print_phys_avail();
	/*
	 * In this first version I only look for the biggest mem area.
	 */
	for (i = j = m = n = 0; i < phys_avail_cnt; i += 2) {
		n = page_to_pfn(phys_avail[i + 1]) - page_to_pfn(phys_avail[i]);
		if (n > m) {
			m = n;
			j = i;
		}
	}
	*start_pfn_p = page_to_pfn(phys_avail[j]);
	*max_pfn_p   = page_to_pfn(phys_avail[j +1 ]);
}

/* Currently only a dummy function. */
void
arch_init_demand_mapping_area(unsigned long max_pfn)
{
	max_pfn = max_pfn;
}

unsigned long allocate_ondemand(unsigned long n, unsigned long alignment)
{
        return 0;
}

/* Helper function used in gnttab.c. */
void do_map_frames(unsigned long addr,
        unsigned long *f, unsigned long n, unsigned long stride,
	unsigned long increment, domid_t id, int may_fail, unsigned long prot)
{
	/* TODO */
	ASSERT(0);
}

void*
map_frames_ex(unsigned long* frames, unsigned long n, unsigned long stride,
	unsigned long increment, unsigned long alignment, domid_t id,
	int may_fail, unsigned long prot)
{
        /* TODO: incomplete! */
        ASSERT(n == 1 || (stride == 0 && increment == 1));
        ASSERT(id == DOMID_SELF);
        ASSERT(prot == 0);
	return (void*) __va(frames[0] << PAGE_SHIFT);
}

int unmap_frames(unsigned long virt_addr, unsigned long num_frames)
{  
    /* TODO */
    ASSERT(0);
}

unsigned long alloc_contig_pages(int order, unsigned int addr_bits)
{
    /* TODO */
    ASSERT(0);
}

void arch_init_p2m(unsigned long max_pfn)
{
    printk("Warn: p2m map not implemented.\n");
}
