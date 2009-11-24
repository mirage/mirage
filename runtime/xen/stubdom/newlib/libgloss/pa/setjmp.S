/* 
 * Copyright (c) 1990,1994 The University of Utah and
 * the Computer Systems Laboratory (CSL).  All rights reserved.
 *
 * Permission to use, copy, modify and distribute this software is hereby
 * granted provided that (1) source code retains these copyright, permission,
 * and disclaimer notices, and (2) redistributions including binaries
 * reproduce the notices in supporting documentation, and (3) all advertising
 * materials mentioning features or use of this software display the following
 * acknowledgement: ``This product includes software developed by the
 * Computer Systems Laboratory at the University of Utah.''
 *
 * THE UNIVERSITY OF UTAH AND CSL ALLOW FREE USE OF THIS SOFTWARE IN ITS "AS
 * IS" CONDITION.  THE UNIVERSITY OF UTAH AND CSL DISCLAIM ANY LIABILITY OF
 * ANY KIND FOR ANY DAMAGES WHATSOEVER RESULTING FROM THE USE OF THIS SOFTWARE.
 *
 * CSL requests users of this software to return to csl-dist@cs.utah.edu any
 * improvements that they make and grant CSL redistribution rights.
 *
 * 	Utah $Hdr: _setjmp.s 1.9 94/12/16$
 */

	.space	$TEXT$
	.subspa $CODE$

/*
 * The PA jmp_buf is 48 words arranged as follows:
 *
 *	 0- 9:	sigcontext
 *	10-26:	callee save GRs (r3-r18) and DP (r27)
 *	   27:	callee save SRs (sr3)
 *	28-47:	callee save FRs (fr12-fr21)
 */

/*
 * int
 * setjmp(env)
 *	jmp_buf env;
 * 
 * This routine does not restore signal state.
 */

	.export	setjmp,entry
	.export	_setjmp,entry
	.proc
	.callinfo
setjmp
_setjmp
	.entry

	/*
	 * save sp and rp in sigcontext, skip the rest
	 */
	stw	%r30,8(%r26)
	stw	%r2,24(%r26)
	ldo	40(%r26),%r26

	/*
	 * save dp and the callee saves registers
	 */
	stwm	%r3,4(%r26)
	stwm	%r4,4(%r26)
	stwm	%r5,4(%r26)
	stwm	%r6,4(%r26)
	stwm	%r7,4(%r26)
	stwm	%r8,4(%r26)
	stwm	%r9,4(%r26)
	stwm	%r10,4(%r26)
	stwm	%r11,4(%r26)
	stwm	%r12,4(%r26)
	stwm	%r13,4(%r26)
	stwm	%r14,4(%r26)
	stwm	%r15,4(%r26)
	stwm	%r16,4(%r26)
	stwm	%r17,4(%r26)
	stwm	%r18,4(%r26)
	stwm	%r27,4(%r26)

	mfsp	%sr3,%r9
	stwm	%r9,4(%r26)

	bv	0(%r2)
	copy	%r0,%r28
	.exit
	.procend

/*
 * void 
 * longjmp(env, val)
 *	jmp_buf env;
 *	int val;
 * 
 * This routine does not retore signal state.
 * This routine does not override a zero val.
 */

	.export	longjmp,entry
	.export	_longjmp,entry
	.proc
	.callinfo
longjmp
_longjmp

	.entry

	/*
	 * restore sp and rp
	 */
	ldw	8(%r26),%r30
	ldw	24(%r26),%r2
	ldo	40(%r26),%r26

	/*
	 * restore callee saves registers
	 */
	ldwm	4(%r26),%r3
	ldwm	4(%r26),%r4
	ldwm	4(%r26),%r5
	ldwm	4(%r26),%r6
	ldwm	4(%r26),%r7
	ldwm	4(%r26),%r8
	ldwm	4(%r26),%r9
	ldwm	4(%r26),%r10
	ldwm	4(%r26),%r11
	ldwm	4(%r26),%r12
	ldwm	4(%r26),%r13
	ldwm	4(%r26),%r14
	ldwm	4(%r26),%r15
	ldwm	4(%r26),%r16
	ldwm	4(%r26),%r17
	ldwm	4(%r26),%r18
	ldwm	4(%r26),%r27

	ldwm	4(%r26),%r9
	mtsp	%r9,%sr3

	bv	0(%r2)
	copy	%r25,%r28
	.exit
	.procend
