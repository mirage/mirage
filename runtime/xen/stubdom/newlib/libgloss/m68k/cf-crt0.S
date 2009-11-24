/* Initial boot
 *
 * Copyright (c) 2006 CodeSourcery Inc
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

	#include "asm.h"	
	.text

	.extern __stack
	.extern __heap_end
	.weak __heap_end
	.extern __start1

	/* __reset should cause a HALT in a hosted executable and
	   fall into __start for an unhosted executable.  The user is
	   free to override this with their own declaration.  */
	.globl __reset
	.weak __reset
__reset:	
#if HOSTED
	HALT
#endif
	
	.globl __start
__start:
	/* Initialize stack */
	move.l IMM(__stack), sp
	move.l IMM(0), fp
	move.l IMM(__heap_end), d1
#if HOSTED
	/* INIT_SIM syscall.  Allows changing sp & d1.  */
	move.l IMM(1),d0

	/* The semihosting sequence is 'nop; halt;sentinel' aligned to
	   a 4 byte boundary.  The sentinel is an ill formed instruction
	   (movec %sp,0).  The debugger will adjust the pc, so it is never
	    executed.  */
	.balignw 4,0x4e71
	nop
	halt
	.long 0x4e7bf000
#endif
	move.l d1,sp@-
	move.l fp,sp@-  /* Dummy return address */
	jmp __start1

