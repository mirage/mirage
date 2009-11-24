#
#  Setjmp/longjmp for MeP
#
#  DJ Delorie, Red Hat Inc.
#
#  19 32-bit words in the jmpbuf:
#    $0
#    $1
#    ...
#    $15
#    $pc
#    $hi
#    $lo
#
#  Note that $0 is saved but not restored.  It can't be restored
#  as it's the return value of setjmp, but we save it in case
#  some application wants to see it in the jmp_buf.  Ideally,
#  we should not need to save anything that is call-clobbered,
#  but you never know what the user is going to tell gcc with -f
#  options.

	.noregerr
	.text

	.globl	setjmp
	.type	setjmp,@function

setjmp:

	# $1 is the address of the buffer.  We return 0 in $0.

	sw	$0, ($1)
	sw	$1, 4($1)
	sw	$2, 8($1)
	sw	$3, 12($1)
	sw	$4, 16($1)
	sw	$5, 20($1)
	sw	$6, 24($1)
	sw	$7, 28($1)
	sw	$8, 32($1)
	sw	$9, 36($1)
	sw	$10, 40($1)
	sw	$11, 44($1)
	sw	$12, 48($1)
	sw	$13, 52($1)
	sw	$14, 56($1)
	sw	$15, 60($1)

	ldc	$0, $lp
	sw	$0, 64($1)
	ldc	$0, $opt
	sra	$0, 24
	and3	$0, $0, 3
	beqz	$0, sj_skip_hilo
	ldc	$0, $hi
	sw	$0, 68($1)
	ldc	$0, $lo
	sw	$0, 72($1)
sj_skip_hilo:

	mov	$0, 0
	ret

	.globl	longjmp
	.type	longjmp,@function

longjmp:

	# $1 is the address of the buffer.  $2 is the value setjmp
	# returns.  We do not faithfully restore $0 or $lp, because
	# the act of calling setjmp clobbered those anyway.

	bnez	$2, rv_not_zero
	mov	$2, 1
rv_not_zero:

	# We restore $sp first so we can save the return value there,
	# otherwise we'd need to have another unrestored register.
	lw	$15, 60($1)
	add3	$sp, $sp, -4
	sw	$2, ($sp)

	# Now restore the general registers.
	lw	$2, 8($1)
	lw	$3, 12($1)
	lw	$4, 16($1)
	lw	$5, 20($1)
	lw	$6, 24($1)
	lw	$7, 28($1)
	lw	$8, 32($1)
	lw	$9, 36($1)
	lw	$10, 40($1)
	lw	$11, 44($1)
	lw	$12, 48($1)
	lw	$13, 52($1)
	lw	$14, 56($1)

	# We restore $pc's value to $lp so that we can just ret later.
	lw	$0, 64($1)
	stc	$0, $lp
	ldc	$0, $opt
	sra	$0, 24
	and3	$0, $0, 3
	beqz	$0, lj_skip_hilo
	lw	$0, 68($1)
	stc	$0, $hi
	lw	$0, 72($1)
	stc	$0, $lo
lj_skip_hilo:

	# Restore $1
	lw	$1, 8($1)

	# Get the return value off the stack, and restore the stack.
	lw	$0, ($sp)
	add3	$sp, $sp, 4

	ret
