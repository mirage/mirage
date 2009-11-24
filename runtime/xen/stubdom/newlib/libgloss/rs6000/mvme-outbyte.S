/*
 * mvme-outbyte.S -- outbyte function for targets using the ppcbug monitor
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

	.file	"mvme-outbyte.S"
	.text
FUNC_START(outbyte)
	li	r10,0x20
	sc
	blr
FUNC_END(outbyte)

FUNC_START(__outstr)
	li	r10,0x21
	sc
	blr
FUNC_END(__outstr)

FUNC_START(__outln)
	li	r10,0x22
	sc
	blr
FUNC_END(__outln)

FUNC_START(__pcrlf)
	li	r10,0x26
	sc
	blr
FUNC_END(__pcrlf)
