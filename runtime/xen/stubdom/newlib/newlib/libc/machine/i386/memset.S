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

	.global SYM (memset)
       SOTYPE_FUNCTION(memset)

SYM (memset):

	pushl ebp
	movl esp,ebp
	pushl edi
	pushl ebx
	movl 8(ebp),edi
	movl 12(ebp),eax
	movl 16(ebp),ecx
	cld

#ifndef __OPTIMIZE_SIZE__
	andl $255,eax
	movl ecx,ebx
	testl $3,edi
	jne .L19
	cmpl $16,ecx
	jbe .L19

	movl eax,edx
	sall $8,eax
	orl edx,eax

	movl eax,edx
	sall $16,edx
	orl edx,eax

	shrl $2,ecx
	andl $3,ebx
	rep
	stosl
	movl ebx,ecx
#endif /* not __OPTIMIZE_SIZE__ */
	
.L19:
	rep
	stosb

	movl 8(ebp),eax

	leal -8(ebp),esp
	popl ebx
	popl edi
	leave
	ret
