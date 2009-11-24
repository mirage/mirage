	.file "isatty.c"
	.sect .lit,lit
gcc2_compiled.:
	.text
	.align 4
	.global __isatty
	.global _isatty
	.word 0x30000
__isatty:
_isatty:
	sub gr1,gr1,16
	asgeu V_SPILL,gr1,gr126
	add lr1,gr1,28
	const gr116,__iostat
	consth gr116,__iostat
	calli lr0,gr116
	sll lr2,lr6,0
	sll gr96,gr96,30
	add gr1,gr1,16
	srl gr96,gr96,31
	jmpi lr0
	asleu V_FILL,lr1,gr127
