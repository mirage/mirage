/*
 * Copyright (C) 2009,  Netronome Systems, Inc.
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


#include <mini-os/types.h>
#include <mini-os/lib.h>
#include <mini-os/xmalloc.h>
#include <mini-os/mm.h>
#include <mini-os/ioremap.h>

/* Map a physical address range into virtual address space with provided
 * flags. Return a virtual address range it is mapped to. */
static void *__do_ioremap(unsigned long phys_addr, unsigned long size, 
                          unsigned long prot)
{
    unsigned long va;
    unsigned long mfns, mfn;
    unsigned long num_pages, offset;
    int i;

    /* allow non page aligned addresses but for mapping we need to align them */
    offset = (phys_addr & ~PAGE_MASK);
    num_pages = (offset + size + PAGE_SIZE - 1) / PAGE_SIZE;
    phys_addr &= PAGE_MASK;
    mfns = mfn = phys_addr >> PAGE_SHIFT;
    
    /* sanity checks on list of MFNs */
    for ( i = 0; i < num_pages; i++, mfn++ )
    {
        if ( mfn_is_ram(mfn) )
        {
            printk("ioremap: mfn 0x%ulx is RAM\n", mfn);
            goto mfn_invalid;
        }
    }   
    va = (unsigned long)map_frames_ex(&mfns, num_pages, 0, 1, 1,
                                      DOMID_IO, 0, prot);
    return (void *)(va + offset);
    
mfn_invalid:
    return NULL;
}

void *ioremap(unsigned long phys_addr, unsigned long size)
{
    return __do_ioremap(phys_addr, size, IO_PROT);
}

void *ioremap_nocache(unsigned long phys_addr, unsigned long size)
{
    return __do_ioremap(phys_addr, size, IO_PROT_NOCACHE);
}

/* Un-map the io-remapped region. Currently no list of existing mappings is
 * maintained, so the caller has to supply the size */
void iounmap(void *virt_addr, unsigned long size)
{   
    unsigned long num_pages;
    unsigned long va = (unsigned long)virt_addr;

    /* work out number of frames to unmap */
    num_pages = ((va & ~PAGE_MASK) + size + PAGE_SIZE - 1) / PAGE_SIZE;

    unmap_frames(va & PAGE_MASK, num_pages);
}



/* -*-  Mode:C; c-basic-offset:4; tab-width:4 indent-tabs-mode:nil -*- */
