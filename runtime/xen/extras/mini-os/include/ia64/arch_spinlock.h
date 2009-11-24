/*
 * Done by Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com
 * The file contains ia64 special spinlock stuff.
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

#ifndef _ARCH_SPINLOCK_H_
#define _ARCH_SPINLOCK_H_

#include "atomic.h"

#define ARCH_SPIN_LOCK_UNLOCKED { 0 }

#define SPIN_LOCK_UNUSED	0
#define SPIN_LOCK_USED		1


static inline void
_raw_spin_lock(spinlock_t* lck)
{
	uint32_t ret;
	do {
		ret = ia64_cmpxchg_acq_32(&(lck->slock),
					  SPIN_LOCK_UNUSED, SPIN_LOCK_USED);
	} while (ret == SPIN_LOCK_USED);
}

static inline void
_raw_spin_unlock(spinlock_t *lck)
{
	asm volatile ("st4.rel.nta [%0] = r0\n\t" :: "r"(&(lck->slock))
							: "memory" );
}

static inline uint32_t
_raw_spin_trylock(spinlock_t* lck)
{
	uint32_t ret;
	ret = ia64_cmpxchg_acq_32(&(lck->slock), SPIN_LOCK_USED, SPIN_LOCK_USED);
	return (ret == SPIN_LOCK_USED);
}

#endif /* _ARCH_SPINLOCK_H_ */
