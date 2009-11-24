/*
 * Copyright (c) 2003-2005, K A Fraser
 *
 * This file may be distributed separately from the Linux kernel, or
 * incorporated into other software packages, subject to the following license:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this source file (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */

/*
 * Copyright 2006 Sun Microsystems, Inc.  All rights reserved.
 * Use is subject to license terms.
 */

#ifndef	_XEN_SYS_PRIVCMD_H
#define	_XEN_SYS_PRIVCMD_H

/*
 * WARNING:
 *	These numbers and structure are built into the ON privcmd
 *	driver, as well as the low-level tools and libraries in
 *	the Xen consolidation.
 */

#include <sys/types.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * ioctl numbers and corresponding data structures
 */

#define	__PRIVCMD_IOC			(('p'<<24)|('r'<<16)|('v'<<8))

#define	IOCTL_PRIVCMD_HYPERCALL		(__PRIVCMD_IOC|0)
#define	IOCTL_PRIVCMD_MMAP		(__PRIVCMD_IOC|1)
#define	IOCTL_PRIVCMD_MMAPBATCH		(__PRIVCMD_IOC|2)

typedef struct __privcmd_hypercall {
	unsigned long op;
	unsigned long arg[5];
} privcmd_hypercall_t;

typedef struct __privcmd_mmap_entry {
	unsigned long va;
	unsigned long mfn;
	unsigned long npages;
} privcmd_mmap_entry_t;

typedef struct __privcmd_mmap {
	int num;
	domid_t dom;	/* target domain */
	privcmd_mmap_entry_t *entry;
} privcmd_mmap_t;

typedef struct __privcmd_mmapbatch {
	int num;	/* number of pages to populate */
	domid_t dom;	/* target domain */
	unsigned long addr;	  /* virtual address */
	unsigned long *arr;	  /* array of mfns - top nibble set on err */
} privcmd_mmapbatch_t;

#ifdef __cplusplus
}
#endif

#endif /* _XEN_SYS_PRIVCMD_H */
