/*
 * sim-read.S -- read interface for frv simulator
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
 * gr8	  -- File descriptor.
 * gr9	  -- Buffer to be read into.
 * gr10	  -- Length of the buffer.
 *
 * Output:
 * gr8	  -- Length read or -1.
 * errno  -- Set if an error
 */

	.globl	EXT(_read)
	.type	EXT(_read),@function
	.weak	EXT(read)
	.text
EXT(_read):
EXT(read):
	setlos	#SYS_read,gr7
	tira	gr0,#0
	ret
.Lend:
	.size	EXT(_read),.Lend-EXT(_read)
