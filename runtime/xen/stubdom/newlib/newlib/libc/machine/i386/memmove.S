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
	
	.global SYM (memmove)
       SOTYPE_FUNCTION(memmove)

SYM (memmove):

	pushl ebp
	movl esp,ebp
	pushl esi
	pushl edi
	pushl ebx
	movl 8(ebp),edi
	movl 16(ebp),ecx
	movl 12(ebp),esi

/*  check for destructive overlap (src < dst && dst < src + length) */

	cld
	cmpl edi,esi
	jae  .L2
	leal -1(ecx,esi),ebx
	cmpl ebx,edi
	ja   .L2

/* IF:	 destructive overlap, must copy backwards */

	addl ecx,esi
	addl ecx,edi
	std

#ifndef __OPTIMIZE_SIZE__
	
	cmpl $8,ecx
	jbe .L13
.L18:

/* move trailing bytes in reverse until destination address is long word aligned */
		
	movl edi,edx
	movl ecx,ebx
	andl $3,edx
	jz .L21
	
	movl edx,ecx
	decl esi
	decl edi
	subl ecx,ebx
	rep
	movsb
	
	mov ebx,ecx
	incl esi
	incl edi

.L21:
	
/* move bytes in reverse, a long word at a time */
		
	shrl $2,ecx
	subl $4,esi
	subl $4,edi
	rep
	movsl
	
	addl $4,esi
	addl $4,edi
	movl ebx,ecx
	andl $3,ecx
	
#endif /* !__OPTIMIZE_SIZE__ */

/* handle any remaining bytes not on a long word boundary */			
	
.L13: 
	decl esi
	decl edi

.L15:
	rep
	movsb
	jmp .L5
	.p2align 4,,7

/* ELSE:   no destructive overlap so we copy forwards */
		
.L2:

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
	cld

	leal -12(ebp),esp
	popl ebx
	popl edi
	popl esi
	leave
	ret
