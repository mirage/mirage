	.file "sbrk.c"
	.sect .lit,lit
gcc2_compiled.:
	.text
	.align 4
	.global __sbrk
	.word 0x30000
__sbrk:
	sub gr1,gr1,16
	asgeu V_SPILL,gr1,gr126
	add lr1,gr1,28
	sll lr2,lr6,0
	jmpt lr2,L4
	constn gr96,65535
	const gr116,__sysalloc
	consth gr116,__sysalloc
	calli lr0,gr116
	nop
	sll gr117,gr96,0
	cpneq gr116,gr117,0
	jmpf gr116,L4
	constn gr96,65535
	sll gr96,gr117,0
L4:
	add gr1,gr1,16
	nop
	jmpi lr0
	asleu V_FILL,lr1,gr127


