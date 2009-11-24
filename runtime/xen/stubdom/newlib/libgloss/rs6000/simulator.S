/*
 * simulator.S -- PowerPC simulator system calls.
 *
 * Copyright (c) 1995, 2000, 2001 Cygnus Support
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */

#include "ppc-asm.h"

FUNC_START(_exit)
	li	r0, 1
	sc

/*
 * Insure that the debugger tells the client that the PC is in _exit,
 * not whatever function happens to follow this function.
 */

0:	trap
	b	0b			/* we never should return, but... */

FUNC_END(_exit)

FUNC_START(read)
	li	r0,3
	sc
	bnslr+
	b	FUNC_NAME(_cerror)
FUNC_END(read)

FUNC_START(write)
	li	r0,4
	sc
	bnslr+
	b	FUNC_NAME(_cerror)
FUNC_END(write)

FUNC_START(open)
	li	r0,5
	sc
	bnslr+
	b	FUNC_NAME(_cerror)
FUNC_END(open)

FUNC_START(close)
	li	r0,6
	sc
	bnslr+
	b	FUNC_NAME(_cerror)
FUNC_END(close)

FUNC_START(brk)
	li	r0,17
	sc
	bnslr+
	b	FUNC_NAME(_cerror)
FUNC_END(brk)

FUNC_START(access)
	li	r0,33
	sc
	bnslr+
	b	FUNC_NAME(_cerror)
FUNC_END(access)

FUNC_START(dup)
	li	r0,41
	sc
	bnslr+
	b	FUNC_NAME(_cerror)
FUNC_END(dup)

FUNC_START(gettimeofday)
	li	r0,116
	sc
	bns+	0f
	b	FUNC_NAME(_cerror)
0:	blr
FUNC_END(gettimeofday)

FUNC_START(lseek)
	li	r0,199
	sc
	bnslr+
	b	FUNC_NAME(_cerror)
FUNC_END(lseek)
