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

	.global SYM (memcmp)
       SOTYPE_FUNCTION(memcmp)

SYM (memcmp):

	pushl ebp
	movl esp,ebp
	subl $16,esp
	pushl ebx
	pushl edi
	pushl esi
	movl 8(ebp),edi
	movl 12(ebp),esi
	movl 16(ebp),ecx
	cld

/* check if length is zero in which case just return 0 */

	xorl eax,eax
	testl ecx,ecx
	jz L4

#ifndef __OPTIMIZE_SIZE__

/* if aligned on long boundary, compare doublewords at a time first */

	movl edi,eax
	orl esi,eax
	testb $3,al
	jne BYTECMP
	movl ecx,ebx
	shrl $2,ecx		/* calculate number of long words to compare */
	repz
	cmpsl
	jz L5
	subl $4,esi
	subl $4,edi
	movl $4,ecx
	jmp BYTECMP
L5:
	andl $3,ebx		/* calculate number of remaining bytes */
	movl ebx,ecx

#endif /* not __OPTIMIZE_SIZE__ */

BYTECMP: /* compare any unaligned bytes or remainder bytes */
	repz
	cmpsb

/* set output to be < 0 if less than, 0 if equal, or > 0 if greater than */
L3:
	xorl edx,edx
	movb -1(esi),dl
	xorl eax,eax
	movb -1(edi),al
	subl edx,eax

L4:
	leal -28(ebp),esp
	popl esi
	popl edi
	popl ebx
	leave
	ret
