/*
 * mcount.S -- dummy module for profiling.
 *
 * Copyright (c) 1997 Cygnus Support
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

	.file	"mcount-dummy.S"
	.text
FUNC_START(_mcount)
	mflr	r11
	lwz	r0,4(sp)
	mtctr	r11
	mtlr	r0
	bctr
FUNC_END(_mcount)
