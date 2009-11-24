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
	
	.global SYM (strchr)
       SOTYPE_FUNCTION(strchr)

SYM (strchr):

	pushl ebp
	movl esp,ebp
	pushl edi
	pushl ebx
	xorl ebx,ebx
	movl 8(ebp),edi
	movb 12(ebp),bl

#ifndef __OPTIMIZE_SIZE__	
/* check if string is aligned, if not do check one byte at a time */
	test $3,edi
	jne L9

/* create 4 byte mask which is just the desired byte repeated 4 times */
	movl ebx,ecx
	sall $8,ebx
	subl $4,edi
	orl ecx,ebx
	movl ebx,edx
	sall $16,ebx
	orl edx,ebx

/* loop performing 4 byte mask checking for 0 byte or desired byte */
	.p2align 4,,7
L10:
	addl $4,edi
	movl (edi),ecx
	leal -16843009(ecx),edx
	movl ecx,eax
	notl eax
	andl eax,edx
	testl $-2139062144,edx
	jne L9

	movl ebx,eax
	xorl ecx,eax
	leal -16843009(eax),edx
	notl eax
	andl eax,edx
	testl $-2139062144,edx
	je L10
#endif /* not __OPTIMIZE_SIZE__ */
		
/* loop while (*s && *s++ != c) */
L9:
	leal -1(edi),eax
	.p2align 4,,7
L15:
	incl eax
	movb (eax),dl
	testb dl,dl
	je L14
	cmpb bl,dl
	jne L15
	
L14:
/*  if (*s == c) return address otherwise return NULL */
	cmpb bl,(eax)
	je L19
	xorl eax,eax

L19:
	leal -8(ebp),esp
	popl ebx
	popl edi
	leave
	ret

