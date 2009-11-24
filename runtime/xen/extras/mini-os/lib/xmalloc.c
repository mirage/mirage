/* 
 ****************************************************************************
 * (C) 2005 - Grzegorz Milos - Intel Research Cambridge
 ****************************************************************************
 *
 *        File: xmaloc.c
 *      Author: Grzegorz Milos (gm281@cam.ac.uk)
 *              Samuel Thibault (samuel.thibault@eu.citrix.com)
 *     Changes: 
 *              
 *        Date: Aug 2005
 *              Jan 2008
 * 
 * Environment: Xen Minimal OS
 * Description: simple memory allocator
 *
 ****************************************************************************
 * Simple allocator for Mini-os.  If larger than a page, simply use the
 * page-order allocator.
 *
 * Copy of the allocator for Xen by Rusty Russell:
 * Copyright (C) 2005 Rusty Russell IBM Corporation
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include <mini-os/os.h>
#include <mini-os/mm.h>
#include <mini-os/types.h>
#include <mini-os/lib.h>
#include <mini-os/list.h>
#include <mini-os/xmalloc.h>

#ifndef HAVE_LIBC
static MINIOS_LIST_HEAD(freelist);
/* static spinlock_t freelist_lock = SPIN_LOCK_UNLOCKED; */

struct xmalloc_hdr
{
    /* Total including this hdr, unused padding and second hdr. */
    size_t size;
    struct minios_list_head freelist;
} __cacheline_aligned;

/* Unused padding data between the two hdrs. */

struct xmalloc_pad
{
    /* Size including both hdrs. */
    size_t hdr_size;
};

/* Return size, increased to alignment with align. */
static inline size_t align_up(size_t size, size_t align)
{
    return (size + align - 1) & ~(align - 1);
}

static void maybe_split(struct xmalloc_hdr *hdr, size_t size, size_t block)
{
    struct xmalloc_hdr *extra;
    size_t leftover;
    size = align_up(size, __alignof__(struct xmalloc_hdr));
    size = align_up(size, __alignof__(struct xmalloc_pad));
    leftover = block - size;

    /* If enough is left to make a block, put it on free list. */
    if ( leftover >= (2 * (sizeof(struct xmalloc_hdr) + sizeof(struct xmalloc_pad))) )
    {
        extra = (struct xmalloc_hdr *)((unsigned long)hdr + size);
        extra->size = leftover;
        /* spin_lock_irqsave(&freelist_lock, flags); */
        minios_list_add(&extra->freelist, &freelist);
        /* spin_unlock_irqrestore(&freelist_lock, flags); */
    }
    else
    {
        size = block;
    }

    hdr->size = size;
    /* Debugging aid. */
    hdr->freelist.next = hdr->freelist.prev = NULL;
}

static struct xmalloc_hdr *xmalloc_new_page(size_t size)
{
    struct xmalloc_hdr *hdr;
    /* unsigned long flags; */

    hdr = (struct xmalloc_hdr *)alloc_page();
    if ( hdr == NULL )
        return NULL;

    maybe_split(hdr, size, PAGE_SIZE);

    return hdr;
}

/* Big object?  Just use the page allocator. */
static void *xmalloc_whole_pages(size_t size, size_t align)
{
    struct xmalloc_hdr *hdr;
    struct xmalloc_pad *pad;
    unsigned int pageorder;
    void *ret;
    /* Room for headers */
    size_t hdr_size = sizeof(struct xmalloc_hdr) + sizeof(struct xmalloc_pad);
    /* Align for actual beginning of data */
    hdr_size = align_up(hdr_size, align);

    pageorder = get_order(hdr_size + size);

    hdr = (struct xmalloc_hdr *)alloc_pages(pageorder);
    if ( hdr == NULL )
        return NULL;

    hdr->size = (1UL << (pageorder + PAGE_SHIFT));
    /* Debugging aid. */
    hdr->freelist.next = hdr->freelist.prev = NULL;

    ret = (char*)hdr + hdr_size;
    pad = (struct xmalloc_pad *) ret - 1;
    pad->hdr_size = hdr_size;
    return ret;
}

void *_xmalloc(size_t size, size_t align)
{
    struct xmalloc_hdr *i, *tmp, *hdr = NULL;
    uintptr_t data_begin;
    size_t hdr_size;
    /* unsigned long flags; */

    hdr_size = sizeof(struct xmalloc_hdr) + sizeof(struct xmalloc_pad);
    /* Align on headers requirements. */
    align = align_up(align, __alignof__(struct xmalloc_hdr));
    align = align_up(align, __alignof__(struct xmalloc_pad));

    /* For big allocs, give them whole pages. */
    if ( size + align_up(hdr_size, align) >= PAGE_SIZE )
        return xmalloc_whole_pages(size, align);

    /* Search free list. */
    /* spin_lock_irqsave(&freelist_lock, flags); */
    minios_list_for_each_entry_safe( i, tmp, &freelist, freelist )
    {
        data_begin = align_up((uintptr_t)i + hdr_size, align);

        if ( data_begin + size > (uintptr_t)i + i->size )
            continue;

        minios_list_del(&i->freelist);
        /* spin_unlock_irqrestore(&freelist_lock, flags); */

        uintptr_t size_before = (data_begin - hdr_size) - (uintptr_t)i;

        if (size_before >= 2 * hdr_size) {
            /* Worth splitting the beginning */
            struct xmalloc_hdr *new_i = (void*)(data_begin - hdr_size);
            new_i->size = i->size - size_before;
            i->size = size_before;
            /* spin_lock_irqsave(&freelist_lock, flags); */
            minios_list_add(&i->freelist, &freelist);
            /* spin_unlock_irqrestore(&freelist_lock, flags); */
            i = new_i;
        }
        maybe_split(i, (data_begin + size) - (uintptr_t)i, i->size);
        hdr = i;
        break;
    }

    if (!hdr) {
        /* spin_unlock_irqrestore(&freelist_lock, flags); */

        /* Alloc a new page and return from that. */
        hdr = xmalloc_new_page(align_up(hdr_size, align) + size);
        if ( hdr == NULL )
            return NULL;
        data_begin = (uintptr_t)hdr + align_up(hdr_size, align);
    }

    struct xmalloc_pad *pad = (struct xmalloc_pad *) data_begin - 1;
    pad->hdr_size = data_begin - (uintptr_t)hdr;
    BUG_ON(data_begin % align);
    return (void*)data_begin;
}

void xfree(const void *p)
{
    /* unsigned long flags; */
    struct xmalloc_hdr *i, *tmp, *hdr;
    struct xmalloc_pad *pad;

    if ( p == NULL )
        return;

    pad = (struct xmalloc_pad *)p - 1;
    hdr = (struct xmalloc_hdr *)((char *)p - pad->hdr_size);

    /* Big allocs free directly. */
    if ( hdr->size >= PAGE_SIZE )
    {
        free_pages(hdr, get_order(hdr->size));
        return;
    }

    /* We know hdr will be on same page. */
    if(((long)p & PAGE_MASK) != ((long)hdr & PAGE_MASK))
    {
        printk("Header should be on the same page\n");
        *(int*)0=0;
    }

    /* Not previously freed. */
    if(hdr->freelist.next || hdr->freelist.prev)
    {
        printk("Should not be previously freed\n");
        *(int*)0=0;
    }

    /* Merge with other free block, or put in list. */
    /* spin_lock_irqsave(&freelist_lock, flags); */
    minios_list_for_each_entry_safe( i, tmp, &freelist, freelist )
    {
        unsigned long _i   = (unsigned long)i;
        unsigned long _hdr = (unsigned long)hdr;

        /* Do not merge across page boundaries. */
        if ( ((_i ^ _hdr) & PAGE_MASK) != 0 )
            continue;

        /* We follow this block?  Swallow it. */
        if ( (_i + i->size) == _hdr )
        {
            minios_list_del(&i->freelist);
            i->size += hdr->size;
            hdr = i;
        }

        /* We precede this block? Swallow it. */
        if ( (_hdr + hdr->size) == _i )
        {
            minios_list_del(&i->freelist);
            hdr->size += i->size;
        }
    }

    /* Did we merge an entire page? */
    if ( hdr->size == PAGE_SIZE )
    {
        if((((unsigned long)hdr) & (PAGE_SIZE-1)) != 0)
        {
            printk("Bug\n");
            *(int*)0=0;
        }
        free_page(hdr);
    }
    else
    {
        minios_list_add(&hdr->freelist, &freelist);
    }

    /* spin_unlock_irqrestore(&freelist_lock, flags); */
}

void *_realloc(void *ptr, size_t size)
{
    void *new;
    struct xmalloc_hdr *hdr;
    struct xmalloc_pad *pad;
    size_t old_data_size;

    if (ptr == NULL)
        return _xmalloc(size, DEFAULT_ALIGN);

    pad = (struct xmalloc_pad *)ptr - 1;
    hdr = (struct xmalloc_hdr *)((char*)ptr - pad->hdr_size);

    old_data_size = hdr->size - pad->hdr_size;
    if ( old_data_size >= size )
    {
	maybe_split(hdr, pad->hdr_size + size, hdr->size);
        return ptr;
    }
    
    new = _xmalloc(size, DEFAULT_ALIGN);
    if (new == NULL) 
        return NULL;

    memcpy(new, ptr, old_data_size);
    xfree(ptr);

    return new;
}
#endif
