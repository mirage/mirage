	.file "_fstat.c"
	.sect .lit,lit
gcc2_compiled.:
	.text
	.align 4
	.global __fstat
;; syscalls used now -- 	.global _fstat
	.word 0x40000
__fstat:
;; syscalls used now -- _fstat:
	sub gr1,gr1,32
	asgeu V_SPILL,gr1,gr126
	add lr1,gr1,48
	sll lr5,lr10,0
	const gr116,__iostat
	consth gr116,__iostat
	calli lr0,gr116
	sll lr2,lr5,0
	sll lr10,gr96,0
	jmpt lr10,L8
	sll gr116,lr10,30
	jmpf gr116,L3
	add gr116,lr11,12
	add gr117,lr11,12
	const gr116,4096
	store 0,0,gr116,gr117
	add gr117,lr11,4
	const gr116,1
	jmp L4
	store 0,0,gr116,gr117
L3:
	const gr117,8192
	store 0,0,gr117,gr116
	add gr116,lr11,4
	store 0,0,gr117,gr116
L4:
	add gr117,lr11,20
	const gr116,0
	store 0,0,gr116,gr117
	store 0,0,gr116,lr11
	const gr116,_time
	consth gr116,_time
	calli lr0,gr116
	const lr2,0
	add gr116,lr11,16
	store 0,0,gr96,gr116
	sll lr2,lr5,0
	const lr3,0
	const lr7,__lseek
	consth lr7,__lseek
	calli lr0,lr7
	const lr4,1
	sll lr10,gr96,0
	constn lr6,65535
	cpneq gr116,lr10,lr6
	jmpf gr116,L7
	sll lr2,lr5,0
	const lr3,0
	calli lr0,lr7
	const lr4,2
	add gr116,lr11,8
	store 0,0,gr96,gr116
	cpneq gr96,gr96,lr6
	jmpf gr96,L7
	sll lr2,lr5,0
	sll lr3,lr10,0
	calli lr0,lr7
	const lr4,0
	cpneq gr96,gr96,lr6
	jmpt gr96,L8
	const gr96,0
L7:
	constn gr96,65535
L8:
	add gr1,gr1,32
	nop
	jmpi lr0
	asleu V_FILL,lr1,gr127

