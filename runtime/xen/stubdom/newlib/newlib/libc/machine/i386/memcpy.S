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
	
	.global SYM (memcpy)
       SOTYPE_FUNCTION(memcpy)

SYM (memcpy):

	pushl ebp
	movl esp,ebp
	pushl esi
	pushl edi
	pushl ebx
	movl 8(ebp),edi
	movl 16(ebp),ecx
	movl 12(ebp),esi
	cld
		
#ifndef __OPTIMIZE_SIZE__
		
	cmpl $8,ecx
	jbe .L3

/* move any preceding bytes until destination address is long word aligned */
		
	movl edi,edx	
	movl ecx,ebx
	andl $3,edx
	jz .L11
	movl $4,ecx
	subl edx,ecx
	andl $3,ecx
	subl ecx,ebx
	rep
	movsb
	
	mov ebx,ecx

/* move bytes a long word at a time */
		
.L11:
	shrl $2,ecx
	.p2align 2
	rep
	movsl
	
	movl ebx,ecx
	andl $3,ecx
	
#endif /* !__OPTIMIZE_SIZE__ */

/* handle any remaining bytes */
		
.L3:		
	rep
	movsb
.L5:		
	movl 8(ebp),eax

	leal -12(ebp),esp
	popl ebx
	popl edi
	popl esi
	leave
	ret
