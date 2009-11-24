	.global	___udivhi3

___udivhi3:
	stz	<r0
	ldy	#1
	ldx	<r4
	lda	<r5
	
div1:	
	asl	a
	bcs	div2
	iny
	cpy	#17
	bne	div1

div2:	ror	a

div4:	pha
	txa
	sec
	sbc	1,s
	bcc	div3
	tax

div3:	rol	<r0
	pla
	lsr	a
	dey
	bne	div4
	rtl
