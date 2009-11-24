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

	.global SYM (strlen)
       SOTYPE_FUNCTION(strlen)

SYM (strlen):

	pushl ebp
	movl esp,ebp
	pushl edi
	movl 8(ebp),edx

	cld
	movl edx,edi
	movl $4294967295,ecx
	xor eax,eax
	repnz
	scasb
	subl edx,edi
	leal -1(edi),eax

	leal -4(ebp),esp
	popl edi
	leave
	ret
