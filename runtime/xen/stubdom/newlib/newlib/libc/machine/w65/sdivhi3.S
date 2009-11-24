	.global	___sdivhi3

___sdivhi3:
	lda	<r4
	ldx	<r5		

	ldy	#0		!flag positive result
	rol	a
	ror	a
	bpl	L10

	iny			!flag negative result
	eor	#0xFFFF
	inc	a

L10:	pha
	txa
	bpl	L20

	dey			!flag negative/positive result
	eor	#0xFFFF
	inc	a
	tax

L20:	pla
	phy
	jsr	>udv
	ply
	beq	Lend		!if positive result

	eor	#0xFFFF		!negate result
	inc	a

Lend:	sta	<r0
	rtl
