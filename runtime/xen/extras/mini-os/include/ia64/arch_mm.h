/*
 * Copyright (C) 2007 - Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com>
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

#ifndef __ARCH_MM_H__
#define __ARCH_MM_H__

#include "page.h"
#include "ia64_cpu.h"

#define PFN_PHYS(x)	(pfn_to_page(x))
#define PHYS_PFN(x)	(page_to_pfn(x))
#define to_virt(x)	__va(x)
#define to_phys(x)	__pa(x)

#define virt_to_mfn(x)	virt_to_pfn(x)
#define virtual_to_mfn(x)      (ia64_tpa((uint64_t)(x)) >> PAGE_SHIFT)

#define map_frames(f, n) map_frames_ex(f, n, 1, 0, 1, DOMID_SELF, 0, 0)
/* TODO */
#define map_zero(n, a) map_frames_ex(NULL, n, 0, 0, a, DOMID_SELF, 0, 0)
#define do_map_zero(start, n) ASSERT(n == 0)

#endif /* __ARCH_MM_H__ */
