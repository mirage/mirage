/* a-memset.s -- memset, optimised for fido asm
 *
 * Copyright (c) 2007 mocom software GmbH & Co KG)
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

	.text
	.align	4

	.globl	memset
	.type	memset, @function

|   memset, optimised
|
|   strategy:
|       - no argument testing (the original memcpy from the GNU lib does
|         no checking either)
|       - make sure the destination pointer (the write pointer) is long word
|         aligned. This is the best you can do, because writing to unaligned
|         addresses can be the most costfull thing one could do.
|       - we fill long word wise if possible
|
|   VG, 2006
|
|	bugfixes:
|		- distribution of byte value improved - in cases someone gives
|         non-byte value
|		- residue byte transfer was not working
|
|	VG, April 2007
|
memset:
	move.l	4(%sp),%a0	| dest ptr
	move.l	8(%sp),%d0	| value
	move.l	12(%sp),%d1	| len
	cmp.l	#16,%d1
	blo	.Lbset		| below, byte fills
	|
	move.l	%d2,-(%sp)	| need a register
	move.b	%d0,%d2		| distribute low byte to all byte in word
	lsl.l	#8,%d0
	move.b	%d2,%d0
	move.w	%d0,%d2
	swap	%d0		| rotate 16
	move.w	%d2,%d0
	|
	move.l	%a0,%d2		| copy of src
	neg.l	%d2		| 1 2 3 ==> 3 2 1
	and.l	#3,%d2
	beq	2f		| is aligned
	|
	sub.l	%d2,%d1		| fix length
	lsr.l	#1,%d2		| word align needed?
	bcc	1f
	move.b	%d0,(%a0)+	| fill byte
1:
	lsr.l	#1,%d2		| long align needed?
	bcc	2f
	move.w	%d0,(%a0)+	| fill word
2:
	move.l	%d1,%d2		| number of long transfers (at least 3)
	lsr.l	#2,%d2
	subq.l	#1,%d2

1:
	move.l	%d0,(%a0)+	| fill long words
.Llset:
#if !defined (__mcoldfire__)
	dbra	%d2,1b		| loop until done
	sub.l	#0x10000,%d2
#else
	subq.l	#1,%d2
#endif
	bpl	1b
	and.l	#3,%d1		| residue byte transfers, fixed
	move.l	(%sp)+,%d2	| restore d2
	bra	.Lbset

1:
	move.b	%d0,(%a0)+	| fill residue bytes
.Lbset:
#if !defined (__mcoldfire__)
	dbra	%d1,1b		| loop until done
#else
	subq.l	#1,%d1
	bpl	1b
#endif
	move.l	4(%sp),%d0	| return value
	rts
