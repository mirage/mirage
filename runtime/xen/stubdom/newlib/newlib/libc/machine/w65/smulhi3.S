	.global	___smulhi3
___smulhi3:	


	
	lda	#0
mult1:	ldx	<r4
	beq	done
	lsr	<r4
	bcc	mult2
	clc
	adc	<r5

mult2:	asl	<r5
	bra	mult1

done:	sta	<r0
	rtl


