/*
 * simulator.S -- m68k simulator system calls.
 *
 * Copyright (c) 1995, 2001 Cygnus Support
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

#include "asm.h"

#define SYSCALL(x) .word 0x4afc, x

#define FUNC_START(x) .globl x; x:
#define FUNC_END(x)
#define FUNC_NAME(x) SYM(x)

FUNC_START(_exit)
	SYSCALL(1)

/*
 * Insure that the debugger tells the client that the PC is in _exit,
 * not whatever function happens to follow this function.
 */

0:	nop
	jmp	0b			/* we never should return, but... */

FUNC_END(_exit)

FUNC_START(read)
	SYSCALL(3)
	bcs	FUNC_NAME(_cerror)
	rts
FUNC_END(read)

FUNC_START(write)
	SYSCALL(4)
	bcs	FUNC_NAME(_cerror)
	rts
FUNC_END(write)

FUNC_START(open)
	SYSCALL(5)
	bcs	FUNC_NAME(_cerror)
	rts
FUNC_END(open)

FUNC_START(close)
	SYSCALL(6)
	bcs	FUNC_NAME(_cerror)
	rts
FUNC_END(close)

FUNC_START(brk)
	SYSCALL(17)
	bcs	FUNC_NAME(_cerror)
	rts
FUNC_END(brk)

FUNC_START(lseek)
	SYSCALL(199)
	bcs	FUNC_NAME(_cerror)
	rts
FUNC_END(lseek)

FUNC_START(fstat)
	SYSCALL(28)
	bcs	FUNC_NAME(_cerror)
	rts
FUNC_END(lseek)

FUNC_START(isatty)
	SYSCALL(29)
	bcs	FUNC_NAME(_cerror)
	rts
FUNC_END(isatty)
