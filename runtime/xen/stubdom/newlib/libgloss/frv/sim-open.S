/*
 * sim-open.S -- open interface for frv simulator
 * 
 * Copyright (c) 2002 Red Hat, Inc
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

#include <frv-asm.h>

#include "syscall.h"

/*
 * Input:
 * gr8	  -- File name to open.
 * gr9	  -- open mode.
 * gr10	  -- optionally, the permission bits to set the file to.
 *
 * Output:
 * gr8	  -- file descriptor or -1.
 * errno  -- Set if an error
 */

	.globl	EXT(_open)
	.type	EXT(_open),@function
	.weak	EXT(open)
	.text
EXT(_open):
EXT(open):
	setlos	#SYS_open,gr7
	tira	gr0,#0
	ret
.Lend:
	.size	EXT(_open),.Lend-EXT(_open)
