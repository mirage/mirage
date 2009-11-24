/*
 * ====================================================
 * Copyright (C) 1998, 2002 by Red Hat Inc. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this
 * software is freely granted, provided that this notice
 * is preserved.
 * ====================================================
 */

	#include "i386mach.h"
	
	.global	SYM (memchr)
       SOTYPE_FUNCTION(memchr)

SYM (memchr):
	pushl	ebp
	movl	esp,ebp
	pushl 	edi
	movl 	12(ebp),eax
	movl 	16(ebp),ecx
	movl 	8(ebp),edi

	xorl	edx,edx
	testl	ecx,ecx
	jz	L1

	cld
	repnz
	scasb

	setnz	dl
	decl	edi
	decl	edx
	andl	edi,edx
L1:
	movl	edx,eax

	leal	-4(ebp),esp
	popl	edi
	leave
	ret
