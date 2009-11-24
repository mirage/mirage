/*
 * vr5xxx.S -- CPU specific support routines
 *
 * Copyright (c) 1999 Cygnus Solutions
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

/* This file cloned from vr4300.S by dlindsay@cygnus.com
 * and recoded to suit Vr5432 and Vr5000.
 * Should be no worse for Vr43{00,05,10}.
 * Specifically, __cpu_flush() has been changed (a) to allow for the hardware
 * difference (in set associativity) between the Vr5432 and Vr5000,
 * and (b) to flush the optional secondary cache of the Vr5000.
 */

/* Processor Revision Identifier (PRID) Register: Implementation Numbers */
#define IMPL_VR5432	0x54

/* Cache Constants not determinable dynamically */
#define VR5000_2NDLINE 32	/* secondary cache line size */
#define VR5432_LINE 32		/* I,Dcache line sizes */
#define VR5432_SIZE (16*1024)	/* I,Dcache half-size */


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
	# NOTE: The Vr4300 and Vr5432 *CANNOT* have any secondary cache.
	# On those, SC (bit 17 of CONFIG register) is hard-wired to 1,
	# except that email from Dennis_Han@el.nec.com says that old
	# versions of the Vr5432 incorrectly hard-wired this bit to 0.
	# The Vr5000 has an optional direct-mapped secondary cache,
	# and the SC bit correctly indicates this.

	# So, for the 4300 and 5432 we want to just
	# flush the primary Data and Instruction caches.
	# For the 5000 it is desired to flush the secondary cache too.
	# There is an operation difference worth noting.
	# The 4300 and 5000 primary caches use VA bit 14 to choose cache set,
	# whereas 5432 primary caches use VA bit 0.

	# This code interprets the relevant Config register bits as
	# much as possible, except for the 5432.
	# The code therefore has some portability.
	# However, the associativity issues mean you should not just assume
	# that this code works anywhere. Also, the secondary cache set
	# size is hardwired, since the 5000 series does not define codes
	# for variant sizes.

	# Note: this version of the code flushes D$ before I$.
	#   It is difficult to construct a case where that matters, 
	#   but it cant hurt.

	mfc0	a0, C0_PRID	# a0 = Processor Revision register
	nop			# dlindsay: unclear why the nops, but
	nop			# vr4300.S had such so I do too.
	srl	a2, a0, PR_IMP	# want bits 8..15
	andi	a2, a2, 0x255	# mask: now a2 = Implementation # field
	li	a1, IMPL_VR5432
	beq	a1, a2, 8f	# use Vr5432-specific flush algorithm
	nop
	
	# Non-Vr5432 version of the code.
	# (The distinctions being: CONFIG is truthful about secondary cache, 
	# and we act as if the primary Icache and Dcache are direct mapped.)

	mfc0	t0, C0_CONFIG	# t0 = CONFIG register
	nop
	nop
	li	a1, 1		# a1=1, a useful constant

	srl	a2, t0, CR_IC	# want IC field of CONFIG
	andi	a2, a2, 0x7	# mask: now a2= code for Icache size
	add	a2, a2, 12	# +12
	sllv	a2, a1, a2	# a2=primary instruction cache size in bytes

	srl	a3, t0, CR_DC	# DC field of CONFIG
	andi	a3, a3, 0x7	# mask: now a3= code for Dcache size
	add	a3, a3, 12	# +12
	sllv	a3, a1, a3	# a3=primary data cache size in bytes

	li	t2, (1 << CR_IB) # t2=mask over IB boolean
	and	t2, t2, t0	# test IB field of CONFIG register value
	beqz	t2, 1f		# 
	li	a1, 16		# 16 bytes (branch shadow: always loaded.)
	li	a1, 32		# non-zero, then 32bytes
1:

	li	t2, (1 << CR_DB) # t2=mask over DB boolean
	and	t2, t2, t0	# test BD field of CONFIG register value
	beqz	t2, 2f		# 
	li	a0, 16		# 16bytes (branch shadow: always loaded.)
	li	a0, 32		# non-zero, then 32bytes
2:
	lui	t1, ((K0BASE >> 16) & 0xFFFF)
	ori	t1, t1, (K0BASE & 0xFFFF)

	# At this point,
	# a0 = primary Dcache line size in bytes
	# a1 = primary Icache line size in bytes
	# a2 = primary Icache size in bytes
	# a3 = primary Dcache size in bytes
	# t0 = CONFIG value
	# t1 = a round unmapped cached base address (we are in kernel mode)
	# t2,t3 scratch

	addi	t3, t1, 0	# t3=t1=start address for any cache
	add	t2, t3, a3	# t2=end adress+1 of Dcache
	sub	t2, t2, a0	# t2=address of last line in Dcache
3:
	cache	INDEX_WRITEBACK_INVALIDATE_D,0(t3)
	bne	t3, t2, 3b	# 
	addu	t3, a0		# (delay slot) increment by Dcache line size


	# Now check CONFIG to see if there is a secondary cache
	lui	t2, (1 << (CR_SC-16)) # t2=mask over SC boolean
	and	t2, t2, t0	# test SC in CONFIG
	bnez	t2, 6f
	
	# There is a secondary cache. Find out its sizes.
	
	srl	t3, t0, CR_SS	# want SS field of CONFIG
	andi	t3, t3, 0x3	# mask: now t3= code for cache size.
	beqz	t3, 4f
	lui	a3, ((512*1024)>>16)	# a3= 512K, code was 0
	addu	t3, -1			# decrement code
	beqz	t3, 4f
	lui	a3, ((1024*1024)>>16)	# a3= 1 M, code  1
	addu	t3, -1			# decrement code
	beqz	t3, 4f
	lui	a3, ((2*1024*1024)>>16)	# a3= 2 M, code 2
	j	6f			# no secondary cache, code 3

4:	# a3 = secondary cache size in bytes
	li	a0, VR5000_2NDLINE	# no codes assigned for other than 32

	# At this point,
	# a0 = secondary cache line size in bytes
	# a1 = primary Icache line size in bytes
	# a2 = primary Icache size in bytes
	# a3 = secondary cache size in bytes
	# t1 = a round unmapped cached base address (we are in kernel mode)
	# t2,t3 scratch
	
	addi	t3, t1, 0	# t3=t1=start address for any cache
	add	t2, t3, a3	# t2=end address+1 of secondary cache
	sub	t2, t2, a0	# t2=address of last line in secondary cache
5:
	cache	INDEX_WRITEBACK_INVALIDATE_SD,0(t3)
	bne	t3, t2, 5b
	addu	t3, a0		# (delay slot) increment by line size

	
6:	# Any optional secondary cache done.  Now do I-cache and return.

	# At this point,
	# a1 = primary Icache line size in bytes
	# a2 = primary Icache size in bytes
	# t1 = a round unmapped cached base address (we are in kernel mode)
	# t2,t3 scratch

	add	t2, t1, a2	# t2=end adress+1 of Icache
	sub	t2, t2, a1	# t2=address of last line in Icache
7:
	cache	INDEX_INVALIDATE_I,0(t1)
	bne	t1, t2, 7b
	addu	t1, a1		# (delay slot) increment by Icache line size

	j	ra	# return to the caller
	nop

8:

# Vr5432 version of the cpu_flush code.
# (The distinctions being: CONFIG can not be trusted about secondary
# cache (which does not exist). The primary caches use Virtual Address Bit 0
# to control set selection.

# Code does not consult CONFIG about cache sizes: knows the hardwired sizes.
# Since both I and D have the same size and line size, uses a merged loop.

	li	a0, VR5432_LINE
	li	a1, VR5432_SIZE
	lui	t1, ((K0BASE >> 16) & 0xFFFF)
	ori	t1, t1, (K0BASE & 0xFFFF)

	# a0 = cache line size in bytes
	# a1 = 1/2 cache size in bytes
	# t1 = a round unmapped cached base address (we are in kernel mode)

	add	t2, t1,	a1	# t2=end address+1
	sub	t2, t2, a0	# t2=address of last line in Icache

9:
	cache	INDEX_WRITEBACK_INVALIDATE_D,0(t1)	# set 0
	cache	INDEX_WRITEBACK_INVALIDATE_D,1(t1)	# set 1
	cache	INDEX_INVALIDATE_I,0(t1)	# set 0
	cache	INDEX_INVALIDATE_I,1(t1)	# set 1
	bne	t1, t2, 9b
	addu	t1, a0

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

/* EOF vr5xxx.S */
