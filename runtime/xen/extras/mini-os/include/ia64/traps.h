/*
 * Done by Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com>
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

#if !defined(_TRAPS_H_)
#define _TRAPS_H_

#if !defined(__ASSEMBLY__)

/* See ia64_cpu.h */
struct trap_frame;

#define pt_regs trap_frame

/*
 * A dummy function, which is currently not supported.
 */
inline static void trap_init(void)
{
	//printk("trap_init() until now not needed!\n");
}
inline static void trap_fini(void)
{
	//printk("trap_fini() until now not needed!\n");
}


#endif /* !defined(__ASSEMBLY__) */

#include "ia64_cpu.h"

void stack_walk(void);

#endif /* !defined(_TRAPS_H_) */

