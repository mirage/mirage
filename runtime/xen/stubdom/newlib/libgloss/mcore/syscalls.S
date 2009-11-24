.macro FUNC_START name
	.text
	.globl \name
	.globl _\name
\name:
_\name:
.endm
	
FUNC_START _sbrk
	mov	r4, r2			// save increment
	lrw	r3, brkval
	ldw	r2, (r3)		// get next spot

	movi	r5, 7
	addi	r2, 7			// round up to 8 bytes
	andn	r2, r5

	addu	r4, r2			// save updated pointer
	stw	r4, (r3)
	jmp	r15

// brk() could go in here too...

	.data
	.import	_end
brkval:	.long	_end

	
FUNC_START _exit
	mov	r1, r1		// accomodate simulator glitch...
	.short	0x5000
	br	_exit		// hard loop here

// 0x5001 - printf
// 0x5002 - scanf
	
FUNC_START utime
	.short	0x5003
	jmp	r15


.macro stub name value
FUNC_START \name
	movi	r1, \value
	.short  0x50FF
	jmp	r15
.endm

stub _close   6
stub _lseek  19
stub _open    5	
stub _read    3
stub _times  43
stub _unlink 10
stub _write   4
	
//stub access  33
//stub creat    8
//stub link     9
//stub time    13

//stub profil 98  // movi r6, 2
//stub lprofil 98 // movi r6, 4
		
