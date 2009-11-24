/*
 * strlen.c -- strlen function.  On at least some MIPS chips, a simple
 * strlen is faster than the 'optimized' C version.
 *
 * Copyright (c) 2001, 2002 Red Hat, Inc.
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

#include <stddef.h>
#include <string.h>

/* MIPS16 needs to come first.  */

#if defined(__mips16)
size_t
strlen (const char *str)
{
  const char *start = str;

  while (*str++ != '\0')
    ;

  return str - start - 1;
}
#elif defined(__mips64)
__asm__(""			/* 64-bit MIPS targets */
	"	.set	noreorder\n"
	"	.set	nomacro\n"
	"	.globl	strlen\n"
	"	.ent	strlen\n"
	"strlen:\n"
	"	daddiu	$2,$4,1\n"
	"\n"
	"1:	lbu	$3,0($4)\n"
	"	bnez	$3,1b\n"
	"	daddiu	$4,$4,1\n"
	"\n"
	"	jr	$31\n"
	"	dsubu	$2,$4,$2\n"
	"	.end	strlen\n"
	"	.set	macro\n"
	"	.set	reorder\n");

#else
__asm__(""			/* 32-bit MIPS targets */
	"	.set	noreorder\n"
	"	.set	nomacro\n"
	"	.globl	strlen\n"
	"	.ent	strlen\n"
	"strlen:\n"
	"	addiu	$2,$4,1\n"
	"\n"
	"1:	lbu	$3,0($4)\n"
	"	bnez	$3,1b\n"
	"	addiu	$4,$4,1\n"
	"\n"
	"	jr	$31\n"
	"	subu	$2,$4,$2\n"
	"	.end	strlen\n"
	"	.set	macro\n"
	"	.set	reorder\n");
#endif
