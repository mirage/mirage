/*
 * idtmon.S -- lo-level entry points into IDT monitor.
 *
 * Copyright (c) 1996 Cygnus Support
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

#ifdef __mips16
/* This file contains 32 bit assembly code.  */
	.set nomips16
#endif

#include "regs.S"

	.text
	.align	2

/* Provide named functions for entry into the IDT monitor: */
#define INDIRECT(name,index)			\
	.globl	name;				\
	.ent	name;				\
name:	la	$2,+(0xbfc00000+((index)*8));	\
	j	$2;				\
	.end name

/* The following magic numbers are for the slots into the IDT monitor: */
INDIRECT(open,6)
INDIRECT(read,7)
INDIRECT(write,8)
INDIRECT(close,10)
INDIRECT(inbyte,11)
INDIRECT(outbyte,12)
INDIRECT(mon_printf,16)
INDIRECT(_flush_cache,28)
INDIRECT(get_mem_info,55)	/* expects pointer to three word vector */

/* EOF idtmon.S */
