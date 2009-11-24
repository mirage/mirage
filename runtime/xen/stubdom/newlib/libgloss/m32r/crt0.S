	.text
	.balign 4
	.global	_start
_start:

	seth	sp, #shigh(_stack)
	add3	sp, sp, #low(_stack)
	ldi	fp, #0

# Clear the BSS.  Do it in two parts for efficiency: longwords first
# for most of it, then the remaining 0 to 3 bytes.

	seth	r2, #shigh(__bss_start)
	add3	r2, r2, #low(__bss_start); R2 = start of BSS
	seth	r3, #shigh(_end)
	add3	r3, r3, #low(_end)	; R3 = end of BSS + 1
	
	sub	r3, r2		; R3 = BSS size in bytes
	mv	r4, r3
	srli	r4, #2		; R4 = BSS size in longwords (rounded down)
	ldi	r1, #0		; clear R1 for longword store
	addi	r2, #-4		; account for pre-inc store
	beqz	r4, .Lendloop1	; any more to go?
.Lloop1:
	st	r1, @+r2	; yep, zero out another longword
	addi	r4, #-1		; decrement count
	bnez	r4, .Lloop1	; go do some more
.Lendloop1:
	and3	r4, r3, #3	; get no. of remaining BSS bytes to clear
	addi	r2, #4		; account for pre-inc store
	beqz	r4, .Lendloop2	; any more to go?
.Lloop2:
	stb	r1, @r2		; yep, zero out another byte
	addi	r2, #1		; bump address
	addi	r4, #-1		; decrement count
	bnez	r4, .Lloop2	; go do some more
.Lendloop2:

# Run code in the .init section.
# This will queue the .fini section to be run with atexit.

	bl	__init

# Call main, then exit.

	bl	main
	bl	exit

# If that fails just loop.

.Lexit:
	bra	.Lexit
