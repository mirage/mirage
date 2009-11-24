/*
 * vr4300.S -- CPU specific support routines
 *
 * Copyright (c) 1995,1996 Cygnus Support
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

#ifndef __mips64
	.set mips3
#endif
#ifdef __mips16
/* This file contains 32 bit assembly code.  */
	.set nomips16
#endif

#include "regs.S"

	.text
	.align	2

	# Taken from "R4300 Preliminary RISC Processor Specification
	# Revision 2.0 January 1995" page 39: "The Count
	# register... increments at a constant rate... at one-half the
	# PClock speed."
	# We can use this fact to provide small polled delays.
	.globl	__cpu_timer_poll
	.ent	__cpu_timer_poll
__cpu_timer_poll:
	.set	noreorder
	# in:	a0 = (unsigned int) number of PClock ticks to wait for
	# out:	void

	# The Vr4300 counter updates at half PClock, so divide by 2 to
	# get counter delta:
	bnezl	a0, 1f		# continue if delta non-zero
	srl	a0, a0, 1	# divide ticks by 2		{DELAY SLOT}
	# perform a quick return to the caller:
	j	ra
	nop			#				{DELAY SLOT}
1:
	mfc0	v0, C0_COUNT	# get current counter value
	nop
	nop
	# We cannot just do the simple test, of adding our delta onto
	# the current value (ignoring overflow) and then checking for
	# equality. The counter is incrementing every two PClocks,
	# which means the counter value can change between
	# instructions, making it hard to sample at the exact value
	# desired.

	# However, we do know that our entry delta value is less than
	# half the number space (since we divide by 2 on entry). This
	# means we can use a difference in signs to indicate timer
	# overflow.
	addu	a0, v0, a0	# unsigned add (ignore overflow)
	# We know have our end value (which will have been
	# sign-extended to fill the 64bit register value).
2:
	# get current counter value:
	mfc0	v0, C0_COUNT
	nop
	nop
	# This is an unsigned 32bit subtraction:
	subu	v0, a0, v0	# delta = (end - now)		{DELAY SLOT}
	bgtzl	v0, 2b		# looping back is most likely
	nop
	# We have now been delayed (in the foreground) for AT LEAST
	# the required number of counter ticks.
	j	ra		# return to caller
	nop			#				{DELAY SLOT}
	.set	reorder
	.end	__cpu_timer_poll

	# Flush the processor caches to memory:

	.globl	__cpu_flush
	.ent	__cpu_flush
__cpu_flush:
	.set	noreorder
	# NOTE: The Vr4300 *CANNOT* have any secondary cache (bit 17
	# of the CONFIG registered is hard-wired to 1). We just
	# provide code to flush the Data and Instruction caches.

	# Even though the Vr4300 has hard-wired cache and cache line
	# sizes, we still interpret the relevant Config register
	# bits. This allows this code to be used for other conforming
	# MIPS architectures if desired.

	# Get the config register
	mfc0	a0, C0_CONFIG
	nop
	nop
	li	a1, 1		# a useful constant
	#
	srl	a2, a0, 9	# bits 11..9 for instruction cache size
	andi	a2, a2, 0x7	# 3bits of information
	add	a2, a2, 12	# get full power-of-2 value
	sllv	a2, a1, a2	# instruction cache size
	#
	srl	a3, a0, 6	# bits 8..6 for data cache size
	andi	a3, a3, 0x7	# 3bits of information
	add	a3, a3, 12	# get full power-of-2 value
	sllv	a3, a1, a3	# data cache size
	#
	li	a1, (1 << 5)	# check IB (instruction cache line size)
	and	a1, a0, a1	# mask against the CONFIG register value
	beqz	a1, 1f		# branch on result of delay slot operation
	nop
	li	a1, 32		# non-zero, then 32bytes
	j	2f		# continue
	nop
1:
	li	a1, 16		# 16bytes
2:
	#
	li	t0, (1 << 4)	# check DB (data cache line size)
	and	a0, a0, t0	# mask against the CONFIG register value
	beqz	a0, 3f		# branch on result of delay slot operation
	nop
	li	a0, 32		# non-zero, then 32bytes
	j	4f		# continue
	nop
3:
	li	a0, 16		# 16bytes
4:
	#
	# a0 = data cache line size
	# a1 = instruction cache line size
	# a2 = instruction cache size
	# a3 = data cache size
	#
	lui	t0, ((K0BASE >> 16) & 0xFFFF)
	ori	t0, t0, (K0BASE & 0xFFFF)
	addu	t1, t0, a2	# end cache address
	subu	t2, a1, 1	# line size mask
	not	t2		# invert the mask
	and	t3, t0, t2	# get start address
	addu	t1, -1
	and	t1, t2		# get end address
5:
	cache	INDEX_INVALIDATE_I,0(t3)
	bne	t3, t1, 5b
	addu	t3, a1
	#
	addu	t1, t0, a3	# end cache address
	subu	t2, a0, 1	# line size mask
	not	t2		# invert the mask
	and	t3, t0, t2	# get start address
	addu	t1, -1
	and	t1, t2		# get end address
6:
	cache	INDEX_WRITEBACK_INVALIDATE_D,0(t3)
	bne	t3, t1, 6b
	addu	t3, a0
	#
	j	ra	# return to the caller
	nop
	.set	reorder
	.end	__cpu_flush

	# NOTE: This variable should *NOT* be addressed relative to
	# the $gp register since this code is executed before $gp is
	# initialised... hence we leave it in the text area. This will
	# cause problems if this routine is ever ROMmed:

	.globl	__buserr_cnt
__buserr_cnt:
	.word	0
	.align	3
__k1_save:
	.word	0
	.word	0
	.align	2

        .ent __buserr
        .globl __buserr
__buserr:
        .set noat
	.set noreorder
	# k0 and k1 available for use:
	mfc0	k0,C0_CAUSE
	nop
	nop
	andi	k0,k0,0x7c
	sub	k0,k0,7 << 2
	beq	k0,$0,__buserr_do
	nop
	# call the previous handler
	la	k0,__previous
	jr	k0
	nop
	#
__buserr_do:
	# TODO: check that the cause is indeed a bus error
	# - if not then just jump to the previous handler
	la	k0,__k1_save
	sd	k1,0(k0)
	#
        la      k1,__buserr_cnt
        lw      k0,0(k1)        # increment counter
        addu    k0,1
        sw      k0,0(k1)
	#
	la	k0,__k1_save
	ld	k1,0(k0)
	#
        mfc0    k0,C0_EPC
	nop
	nop
        addu    k0,k0,4		# skip offending instruction
	mtc0	k0,C0_EPC	# update EPC
	nop
	nop
	eret
#        j       k0
#        rfe
        .set reorder
        .set at
        .end __buserr

__exception_code:
	.set noreorder
	lui	k0,%hi(__buserr)
	daddiu	k0,k0,%lo(__buserr)
	jr	k0
	nop
	.set reorder
__exception_code_end:

	.data
__previous:
	.space	(__exception_code_end - __exception_code)
	# This subtracting two addresses is working
	# but is not garenteed to continue working.
	# The assemble reserves the right to put these
	# two labels into different frags, and then
	# cant take their difference.

	.text

	.ent	__default_buserr_handler
	.globl	__default_buserr_handler
__default_buserr_handler:
        .set noreorder
	# attach our simple bus error handler:
	# in:  void
	# out: void
	mfc0	a0,C0_SR
	nop
	li	a1,SR_BEV
	and	a1,a1,a0
	beq	a1,$0,baseaddr
	lui	a0,0x8000	# delay slot
	lui	a0,0xbfc0
	daddiu	a0,a0,0x0200
baseaddr:
	daddiu	a0,a0,0x0180
	# a0 = base vector table address
	la	a1,__exception_code_end
	la	a2,__exception_code
	subu	a1,a1,a2
	la	a3,__previous
	# there must be a better way of doing this????
copyloop:
	lw	v0,0(a0)
	sw	v0,0(a3)
	lw	v0,0(a2)
	sw	v0,0(a0)
	daddiu	a0,a0,4
	daddiu	a2,a2,4
	daddiu	a3,a3,4
	subu	a1,a1,4
	bne	a1,$0,copyloop
	nop
        la      a0,__buserr_cnt
	sw	$0,0(a0)
	j	ra
	nop
        .set reorder
	.end	__default_buserr_handler

	.ent	__restore_buserr_handler
	.globl	__restore_buserr_handler
__restore_buserr_handler:
        .set noreorder
	# restore original (monitor) bus error handler
	# in:  void
	# out: void
	mfc0	a0,C0_SR
	nop
	li	a1,SR_BEV
	and	a1,a1,a0
	beq	a1,$0,res_baseaddr
	lui	a0,0x8000	# delay slot
	lui	a0,0xbfc0
	daddiu	a0,a0,0x0200
res_baseaddr:
	daddiu	a0,a0,0x0180
	# a0 = base vector table address
	la	a1,__exception_code_end
	la	a3,__exception_code
	subu	a1,a1,a3
	la	a3,__previous
	# there must be a better way of doing this????
res_copyloop:
	lw	v0,0(a3)
	sw	v0,0(a0)
	daddiu	a0,a0,4
	daddiu	a3,a3,4
	subu	a1,a1,4
	bne	a1,$0,res_copyloop
	nop
	j	ra
	nop
        .set reorder
	.end	__restore_buserr_handler

	.ent	__buserr_count
	.globl	__buserr_count
__buserr_count:
        .set noreorder
	# restore original (monitor) bus error handler
	# in:  void
	# out: unsigned int __buserr_cnt
        la      v0,__buserr_cnt
	lw	v0,0(v0)
	j	ra
	nop
        .set reorder
	.end	__buserr_count

/* EOF vr4300.S */
