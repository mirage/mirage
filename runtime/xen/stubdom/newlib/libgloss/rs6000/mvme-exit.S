/*
 * mvme-exit.S -- _exit function for targets using the ppcbug monitor
 *
 * Copyright (c) 1995 Cygnus Support
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

	.file	"mvme-exit.S"
	.text
FUNC_START(_exit)
	li	r10,0x63
	sc

/*
 * Insure that the debugger tells the client that the PC is in _exit,
 * not whatever function happens to follow this function.
 */

0:	trap
	b	0b			/* we never should return, but... */
FUNC_END(_exit)
