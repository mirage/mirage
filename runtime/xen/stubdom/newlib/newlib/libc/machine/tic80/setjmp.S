/* These are predefined by new versions of GNU cpp.  */

#ifndef __USER_LABEL_PREFIX__
#define __USER_LABEL_PREFIX__ _
#endif

/* ANSI concatenation macros.  */

#define CONCAT1(a, b) CONCAT2(a, b)
#define CONCAT2(a, b) a ## b

/* Use the right prefix for global labels.  */

#define SYM(x) CONCAT1 (__USER_LABEL_PREFIX__, x)

	.global SYM (setjmp)
	.global SYM (_setjmp)
	.global SYM (longjmp)

	.section  .text,"x"
	.align 4
SYM (_setjmp):	
SYM (setjmp):
	st.d	0(r2),r20
	st.d	8(r2),r22
	st.d	16(r2),r24
	st.d	24(r2),r26
	st.d	32(r2),r28
	st.d	40(r2),r30
	st	48(r2),r1
	jsr	r31(r0),r0
	 addu	0,r0,r2

	.section  .text,"x"
	.align 4
SYM (longjmp):
	ld.d	0(r2),r20
	ld.d	8(r2),r22
	ld.d	16(r2),r24
	ld.d	24(r2),r26
	ld.d	32(r2),r28
	ld.d	40(r2),r30
	bcnd	L1,r4,ne0.w
	 ld	48(r2),r1

	jsr	r31(r0),r0
	 addu	1,r0,r2
L1:
	jsr	r31(r0),r0
	 addu	r4,r0,r2
