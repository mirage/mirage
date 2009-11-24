/*

Copyright (c) 2005 Red Hat Incorporated.
All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met: 

    Redistributions of source code must retain the above copyright 
    notice, this list of conditions and the following disclaimer.

    Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

    The name of Red Hat Incorporated may not be used to endorse 
    or promote products derived from this software without specific 
    prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED.  IN NO EVENT SHALL RED HAT INCORPORATED BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND 
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 

*/

#if defined(__r8c_cpu__) || defined(__m16c_cpu__)
#define A16 1
#endif

/* We implement setjmp/longjmp much like the way gcc implements
   exceptions - we create new stack frames, then switch to them and
   return.  Thus, the two setjmp's below each push all the relevent
   registers, then copy the whole frame into the buffer (first $sp is
   moved, then smovf copies the frame itself), and the two longjmps
   restore $sp, copy the frame back into place, and issue the same
   return as the setjmp would have used.

   Since the sizes of registers differs between the 16 and 24 bit
   models, we provide separate implementations for each rather than
   trying to parameterize them.

   Jump buffer sizes: 21 bytes for 16 bit, 34 bytes for 24 bit.
*/

	.text

#ifdef A16	/* 16 bit versions */

	.global	_setjmp
_setjmp:
	enter	#0
	pushm	r1,r2,r3,a0,a1,sb,fb

; At this point, the stack looks like this:
; ... [pc:3] [oldfb:2] <fb> [r1:2] [r2:2] [r3:2] [a0:2] [a1:2] [sb:2] [fb:2] <sp> */

	mov.w	r1,a1		;  a1 is the destination of smovf
	mov.b	#0,r1h
	stc	sp,a0		;  r1h:a0 is the source of smovf
	mov.w	a0,[a1]
	add.w	#2,a1
	mov.w	#19,r3		;  plus two for sp later
	smovf.b

	; Return 0 to caller.
	mov.w	#0,r0
	popm	r1,r2,r3,a0,a1,sb,fb
	exitd

	.global	_longjmp
_longjmp:
	enter	#0
	mov.w	r1,a0		;  pointer to jump buf
	mov.w	r2,r0		;  setjmp's "new" return value

	mov.b	#0,r1h		;  r1h:	a0 is the source, now jmpbuf
	mov.w	[a0],a1		;  dest is new stack
	ldc	a1,sp
	add.w	#2,a0
	mov.w	#19,r3
	smovf.b

	;; now return to our caller with this newly restored frame
	popm	r1,r2,r3,a0,a1,sb,fb
	exitd

#else	/* 24 bit versions */

	.global	_setjmp
_setjmp:
	enter	#0
	pushm	r1,r2,r3,a0,a1,sb,fb

; At this point, the stack looks like this:
; ... [jbuf:4] [pc:4] [oldfb:4] <fb> [r1:2] [r2:2] [r3:2] [a0:4] [a1:4] [sb:4] [fb:4] <sp> */

	mov.l	8[fb],a1	;  a1 is the destination of smovf
	stc	sp,a0		;  r1h:a0 is the source of smovf
	mov.l	a0,[a1]
	add.l	#4,a1
	mov.w	#30,r3		;  plus two for sp later
	smovf.b

	; Return 0 to caller.
	mov.w	#0,r0
	popm	r1,r2,r3,a0,a1,sb,fb
	exitd

	.global	_longjmp
_longjmp:
	enter	#0
; ... [rv:2] [jbuf:4] [pc:4] [oldfb:4] <fb>
	mov.l	8[fb],a0	;  pointer to jump buf
	mov.w	12[fb],r0	;  setjmp's "new" return value

	mov.l	[a0],a1		;  dest is new stack
	ldc	a1,sp
	add.l	#4,a0
	mov.w	#30,r3
	smovf.b

	;; now return to our caller with this newly restored frame
	popm	r1,r2,r3,a0,a1,sb,fb
	exitd
#endif

