/*
 * crt0 startup code for user programs running under Cygmon
 *
 * Copyright (c) 1998, 2000 Cygnus Support
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */

#define _S2(P,X) P ## X
#define _S1(P,X) _S2(P,X)
#define SYM(X) _S1(__USER_LABEL_PREFIX__,X)

.data
        .align  8
SYM(environ):
        .long   0

SYM(argc):
	.long	0

	.text
	.align 4

	.globl __start
__start:
	/* see if the stack is already setup. if not, then default
         *  to using the value of %sp as set by the ROM monitor
         */
	movl	$__stack, %eax
	testl	%eax, %eax
	jz	1f
	movl	%eax, %esp
1:
	mov $0, %ebp

	movl	$__bss_start, %edi
	movl	$__bss_end, %ecx
	subl	%edi, %ecx
	xorl	%eax, %eax
	rep; stosb

	pushl	$SYM(__sigtramp)
	pushl	$0
	call	SYM(__install_signal_handler)
	popl	%eax

	pushl	$SYM(__do_global_dtors)
	call	SYM(atexit)
	popl	%eax

	call	SYM(__do_global_ctors)

	pushl	$SYM(argc)
	call	SYM(__get_program_arguments)
	popl	%ecx

	movl	SYM(argc), %ecx
	pushl	%eax
	pushl	%ecx
	call	SYM(main)
	popl	%ecx
	popl	%edx

	/* call exit from the C library so atexit gets called, and the
	 * C++ destructors get run. This calls our exit routine below	 
	 * when it's done.
	 */
	pushl	%eax
	call	SYM(exit)
3:
	jmp	3b
