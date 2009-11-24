#ifndef _X86_DELAY_H
#define _X86_DELAY_H

/*
 * Copyright (C) 1993 Linus Torvalds
 *
 * Delay routines calling functions in arch/i386/lib/delay.c
 */

extern void __udelay(unsigned long usecs);
#define udelay(n) __udelay(n)

#endif /* defined(_X86_DELAY_H) */
