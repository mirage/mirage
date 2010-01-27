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

#ifndef _MM_H_
#define _MM_H_

#include <xen/arch-x86_64.h>

#include <mini-os/lib.h>

#include <mini-os/arch_limits.h>
#include <mini-os/arch_mm.h>

#define STACK_SIZE_PAGE_ORDER __STACK_SIZE_PAGE_ORDER
#define STACK_SIZE __STACK_SIZE


void init_mm(void);
unsigned long alloc_pages(int order);
#define alloc_page()    alloc_pages(0)
void free_pages(void *pointer, int order);
#define free_page(p)    free_pages(p, 0)

static __inline__ int get_order(unsigned long size)
{
    int order;
    size = (size-1) >> PAGE_SHIFT;
    for ( order = 0; size; order++ )
        size >>= 1;
    return order;
}

void arch_init_demand_mapping_area(unsigned long max_pfn);
void arch_init_mm(unsigned long* start_pfn_p, unsigned long* max_pfn_p);
void arch_init_p2m(unsigned long max_pfn_p);

unsigned long allocate_ondemand(unsigned long n, unsigned long alignment);
/* map f[i*stride]+i*increment for i in 0..n-1, aligned on alignment pages */
void *map_frames_ex(unsigned long *f, unsigned long n, unsigned long stride,
	unsigned long increment, unsigned long alignment, domid_t id,
	int may_fail, unsigned long prot);
void do_map_frames(unsigned long addr,
        unsigned long *f, unsigned long n, unsigned long stride,
	unsigned long increment, domid_t id, int may_fail, unsigned long prot);
int unmap_frames(unsigned long va, unsigned long num_frames);
unsigned long alloc_contig_pages(int order, unsigned int addr_bits);
extern unsigned long heap, brk, heap_mapped, heap_end;

int free_physical_pages(xen_pfn_t *mfns, int n);
void fini_mm(void);
int allocate_va_mapping(unsigned long va, unsigned long nr_pages);
#endif /* _MM_H_ */
