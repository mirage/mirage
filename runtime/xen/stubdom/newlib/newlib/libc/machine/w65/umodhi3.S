	.global	___umodhi3

___umodhi3:
	jsr	>___udivhi3
	stx	<r0
	rtl

