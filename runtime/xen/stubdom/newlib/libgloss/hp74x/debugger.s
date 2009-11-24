/****************************************************************************

		THIS SOFTWARE IS NOT COPYRIGHTED

   HP offers the following for use in the public domain.  HP makes no
   warranty with regard to the software or it's performance and the
   user accepts the software "AS IS" with all faults.

   HP DISCLAIMS ANY WARRANTIES, EXPRESS OR IMPLIED, WITH REGARD
   TO THIS SOFTWARE INCLUDING BUT NOT LIMITED TO THE WARRANTIES
   OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

****************************************************************************/
	.space	$TEXT$
	.subspa	$CODE$,access=0x2c

#if 1
#include	"diagnose.h"
#endif

i13BREAK	.equ    0xa5a			; im13 field for specified functions
i5REG		.equ	0x06			; Init registers
i5BP		.equ	0x09			; GDB breakpoin
i5PSW		.equ	0x0b			; Get PSW
i5INLINE	.equ	0x0e			; Get INLINE
R_gr0		.equ	 0
R_gr1		.equ	 4
R_gr2		.equ	 8
R_gr3		.equ	12
R_gr4		.equ	16
R_gr5		.equ	20
R_gr6		.equ	24
R_gr7		.equ	28
R_gr8		.equ	32
R_gr9		.equ	36
R_gr10		.equ	40
R_gr11		.equ	44
R_gr12		.equ	48
R_gr13		.equ	52
R_gr14		.equ	56
R_gr15		.equ	60
R_gr16		.equ	64
R_gr17		.equ	68
R_gr18		.equ	72
R_gr19		.equ	76
R_gr20		.equ	80
R_gr21		.equ	84
R_gr22		.equ	88
R_gr23		.equ	92
R_gr24		.equ	96
R_gr25		.equ	100
R_gr26		.equ	104
R_gr27		.equ	108
R_gr28		.equ	112
R_gr29		.equ	116
R_gr30		.equ	120
R_gr31		.equ	124

R_sr0		.equ	128
R_sr1		.equ	132
R_sr2		.equ	136
R_sr3		.equ	140
R_sr4		.equ	144
R_sr5		.equ	148
R_sr6		.equ	152
R_sr7		.equ	156

R_cr0		.equ	160
R_cr1		.equ	164
R_cr2		.equ	168
R_cr3		.equ	172
R_cr4		.equ	176
R_cr5		.equ	180
R_cr6		.equ	184
R_cr7		.equ	188
R_cr8		.equ	192
R_cr9		.equ	196
R_cr10		.equ	200
R_cr11		.equ	204
R_cr12		.equ	208
R_cr13		.equ	212
R_cr14		.equ	216
R_cr15		.equ	220
R_cr16		.equ	224
R_cr17H		.equ	228
R_cr18H		.equ	232
R_cr19		.equ	236
R_cr20		.equ	240
R_cr21		.equ	244
R_cr22		.equ	248
R_cr23		.equ	252
R_cr24		.equ	256
R_cr25		.equ	260
R_cr26		.equ	264
R_cr27		.equ	268
R_cr28		.equ	272
R_cr29		.equ	276
R_cr30		.equ	280
R_cr31		.equ	284

R_cr17T		.equ	288
R_cr18T		.equ	292

R_cpu0		.equ	296

R_SIZE          .equ	300

min_stack	.equ     64

	.import	handle_exception
	.import $global$, data
	.IMPORT putnum, code
	.IMPORT led_putnum, code
	.IMPORT delay, code

        .export FICE
	.export	DEBUG_GO
	.export	DEBUG_SS
	.export	STUB_RESTORE

	.export	save_regs
	.export	RegBlk
	.export Exception_index

;-------------------------------------------------------------------------------
        .EXPORT breakpoint,ENTRY,ARGW0=GR,RTNVAL=GR
breakpoint
	.PROC
	.CALLINFO CALLER,FRAME=128,SAVE_RP
	.ENTRY

	stw     %r2,-20(0,%r30)			; stash the return pointer
	ldo	128(%r30),%r30			; push up the stack pointer

;;; debug
	ldi	6, %r26
	bl,n	led_putnum,%r2
	nop
        ldil 	L'900000,%r26
        ldo 	R'900000(%r26),%r26
	bl,n	delay,%r2
	nop
;;; 
	break   i5INLINE,i13BREAK
;;; more debug
	ldi	7, %r26
	bl,n	led_putnum,%r2
	nop
        ldil 	L'900000,%r26
        ldo 	R'900000(%r26),%r26
	bl,n	delay,%r2
	nop
;;; 
	
FICE	fice	0(0,%r26)			; Flush the i cache entry
	sync

	ldw 	-148(0,%r30),%r2		; retrieve the return pointer
	ldo 	-128(%r30),%r30			; reset the stack pointer
	bv,n    0(%r2)				; return to caller
	nop

	.EXIT
	.PROCEND

;-------------------------------------------------------------------------------
DEBUG_GO
	or,tr	%r0,%r0,%r10	; if go, do not set R-bit to 1

DEBUG_SS
	ldi	1,%r10		; else set R-bit to 1

DEBUG_EXEC

	bl	DGO_0,%r8			; r8 points to register block
	addil	L%RegBlk-DGO_0,%r8
DGO_0
	ldo	R%RegBlk-DGO_0(%r1),%r8

; load space registers

	ldw	R_sr0(%r8),%r1
	mtsp	%r1,%sr0
	ldw	R_sr1(%r8),%r1
	mtsp	%r1,%sr1
	ldw	R_sr2(%r8),%r1
	mtsp	%r1,%sr2
	ldw	R_sr3(%r8),%r1
	mtsp	%r1,%sr3
	ldw	R_sr4(%r8),%r1
	mtsp	%r1,%sr4
	ldw	R_sr5(%r8),%r1
	mtsp	%r1,%sr5
	ldw	R_sr6(%r8),%r1
	mtsp	%r1,%sr6
	ldw	R_sr7(%r8),%r1
	mtsp	%r1,%sr7

; clear Q-bit for rfi

	rsm	0x08,%r0

; load control registers

	ldw	R_cr0(%r8),%r1
	or,=	%r10,%r0,%r0		; if single step
	copy	%r0,%r1			;   set %cr0 to 0
	mtctl	%r1,%cr0
	ldw	R_cr8(%r8),%r1
	mtctl	%r1,%cr8
	ldw	R_cr9(%r8),%r1
	mtctl	%r1,%cr9
	ldw	R_cr10(%r8),%r1
	mtctl	%r1,%cr10
	ldw	R_cr11(%r8),%r1
	mtctl	%r1,%cr11
	ldw	R_cr12(%r8),%r1
	mtctl	%r1,%cr12
	ldw	R_cr13(%r8),%r1
	mtctl	%r1,%cr13
	ldw	R_cr14(%r8),%r1
	mtctl	%r1,%cr14
	ldw	R_cr15(%r8),%r1
	mtctl	%r1,%cr15
	ldw	R_cr16(%r8),%r1
	mtctl	%r1,%cr16
	ldw	R_cr17H(%r8),%r1	; load iiasq.head
	mtctl	%r1,%cr17
	ldw	R_cr18H(%r8),%r1	; load iiaoq.head
	mtctl	%r1,%cr18
	ldw	R_cr17T(%r8),%r1	; load iiasq.tail
	mtctl	%r1,%cr17
	ldw	R_cr18T(%r8),%r1	; load iiaoq.tail
	mtctl	%r1,%cr18
	ldw	R_cr19(%r8),%r1
	mtctl	%r1,%cr19
	ldw	R_cr20(%r8),%r1
	mtctl	%r1,%cr20
	ldw	R_cr21(%r8),%r1
	mtctl	%r1,%cr21
	ldw	R_cr22(%r8),%r1
	dep	%r10,27,1,%r1		; set R-bit if applicable
	mtctl	%r1,%cr22
	ldw	R_cr23(%r8),%r1
	mtctl	%r1,%cr23
	ldw	R_cr24(%r8),%r1
	mtctl	%r1,%cr24
	ldw	R_cr25(%r8),%r1
	mtctl	%r1,%cr25
	ldw	R_cr26(%r8),%r1
	mtctl	%r1,%cr26
	ldw	R_cr27(%r8),%r1
	mtctl	%r1,%cr27
	ldw	R_cr28(%r8),%r1
	mtctl	%r1,%cr28
	ldw	R_cr29(%r8),%r1
	mtctl	%r1,%cr29
	ldw	R_cr30(%r8),%r1
	mtctl	%r1,%cr30
	ldw	R_cr31(%r8),%r1
	mtctl	%r1,%cr31

; load diagnose registers

	ldw	R_cpu0(%r8),%r1
	ldil	L%CPU0_MASK,%r2
	ldo	R%CPU0_MASK(%r2),%r2
	xor	%r1,%r2,%r1		; xor the read/clear bits
	nop
	mtcpu	%r1,0
	mtcpu	%r1,0

; load general registers

	ldw	R_gr1(%r8),%r1
	ldw	R_gr2(%r8),%r2
	ldw	R_gr3(%r8),%r3
	ldw	R_gr4(%r8),%r4
	ldw	R_gr5(%r8),%r5
	ldw	R_gr6(%r8),%r6
	ldw	R_gr7(%r8),%r7
	ldw	R_gr9(%r8),%r9
	ldw	R_gr10(%r8),%r10
	ldw	R_gr11(%r8),%r11
	ldw	R_gr12(%r8),%r12
	ldw	R_gr13(%r8),%r13
	ldw	R_gr14(%r8),%r14
	ldw	R_gr15(%r8),%r15
	ldw	R_gr16(%r8),%r16
	ldw	R_gr17(%r8),%r17
	ldw	R_gr18(%r8),%r18
	ldw	R_gr19(%r8),%r19
	ldw	R_gr20(%r8),%r20
	ldw	R_gr21(%r8),%r21
	ldw	R_gr22(%r8),%r22
	ldw	R_gr23(%r8),%r23
	ldw	R_gr24(%r8),%r24
	ldw	R_gr25(%r8),%r25
	ldw	R_gr26(%r8),%r26
	ldw	R_gr27(%r8),%r27
	ldw	R_gr28(%r8),%r28
	ldw	R_gr29(%r8),%r29
	ldw	R_gr30(%r8),%r30
	ldw	R_gr31(%r8),%r31
	ldw	R_gr8(%r8),%r8

; execute user program

	nop
	rfi		; switch to user code
	nop

;-------------------------------------------------------------------------------

STUB_RESTORE
	copy	%r1,%r9	; save exception index
	bl	SR_00,%r8
	addil	L%Exception_index-SR_00,%r8
SR_00
	ldo	R%Exception_index-SR_00(%r1),%r8
	stw	%r9,(%r8)

	bl	save_regs,%r25
	nop
	
#ifdef	DEBUG_DEBUGGER1
	stwm	%r1,8(%sp)
	bl	putc,%rp
	ldi	CR,%arg0
	bl	putc,%rp
	ldi	LF,%arg0
	bl	printit,%mrp
	mfctl	%pcoq,%arg0

	mfctl	%pcoq,%r1
	mtctl	%r1,%pcoq
	mfctl	%pcoq,%arg0
	bl	printit,%mrp
	mtctl	%arg0,%pcoq

	bl	printit,%mrp
	ldw	-8(%sp),%arg0

	ldwm	-8(%sp),%r1
#endif

#ifdef	DEBUG_DEBUGGER2
	stwm	%r1,8(%sp)
	bl	putc,%rp
	ldi	LF,%arg0
	ldwm	-8(%sp),%r1
#endif

#ifdef	DEBUG_DEBUGGER3
	bl	printit,%mrp
	copy	iptr,%arg0
	bl	printit,%mrp
	copy	rstack,%arg0
	bl	printit,%mrp
	copy	gspace,%arg0
	bl	printit,%mrp
	copy	dstack,%arg0
	bl	printit,%mrp
	copy	nextptr,%arg0
	bl	printit,%mrp
	copy	%dp,%arg0
	bl	printit,%mrp
	copy	%sp,%arg0
	bl	printit,%mrp
	mfctl	%rctr,%arg0
	bl	printit,%mrp
	mfctl	%iva,%arg0
	bl	printit,%mrp
	mfctl	%eiem,%arg0
	bl	printit,%mrp
	mfctl	%ipsw,%arg0
	bl	printit,%mrp
	copy	%r0,%arg0
#endif
	bl	SR_1,%sp
	addil	L%Stub_stack-SR_1,%sp
SR_1
	ldo	R%Stub_stack-SR_1(%r1),%sp	; set the stack pointer

	bl	SR_2,%arg0
	addil	L%RegBlk-SR_2,%arg0
SR_2
	ldo	R%RegBlk-SR_2(%r1),%arg0	; set arg0 (save register area)

	bl	SR_3,%arg1
	addil	L%Exception_index-SR_3,%arg1	; set arg1 address
SR_3
	ldo	R%Exception_index-SR_3(%r1),%arg1	; set arg1 address

	addi	min_stack,%sp,%sp		; allocate min stack frame

	bl	handle_exception,%r2
	ldw	0(%arg1),%arg1			; load arg1
        addi	-min_stack,%sp,%sp		; de allocate min stack frame

	b	DEBUG_EXEC			; 
	copy	%r28,%r10	
;-------------------------------------------------------------------------------

save_regs	; return address is in %r25

	bl	SR_0,%r1			; r1 points to Register block
	addil   L%RegBlk-SR_0,%r1
SR_0
	ldo     R%RegBlk-SR_0(%r1),%r1

; save general registers

	stw	%r0,R_gr0(%r1)
	; don't store %r1 yet
	stw	%r2,R_gr2(%r1)
	stw	%r3,R_gr3(%r1)
	stw	%r4,R_gr4(%r1)
	stw	%r5,R_gr5(%r1)
	stw	%r6,R_gr6(%r1)
	stw	%r7,R_gr7(%r1)
	; don't store %r8 yet
	; don't store %r9 yet
	stw	%r10,R_gr10(%r1)
	stw	%r11,R_gr11(%r1)
	stw	%r12,R_gr12(%r1)
	stw	%r13,R_gr13(%r1)
	stw	%r14,R_gr14(%r1)
	stw	%r15,R_gr15(%r1)
	; don't store %r16 yet
	; don't store %r17 yet
	stw	%r18,R_gr18(%r1)
	stw	%r19,R_gr19(%r1)
	stw	%r20,R_gr20(%r1)
	stw	%r21,R_gr21(%r1)
	stw	%r22,R_gr22(%r1)
	stw	%r23,R_gr23(%r1)
	; don't store %r24 yet
	; don't store %r25 yet
	stw	%r26,R_gr26(%r1)
	stw	%r27,R_gr27(%r1)
	stw	%r28,R_gr28(%r1)
	stw	%r29,R_gr29(%r1)
	stw	%r30,R_gr30(%r1)
	stw	%r31,R_gr31(%r1)

; restore general registers from shadow registers and save them

	copy	%r1,%r10	; hold Register block pointer
	copy	%r25,%rp	; hold return pointer
	shdw_gr
	shdw_gr
	stw	%r1,R_gr1(%r10)
	stw	%r8,R_gr8(%r10)
	stw	%r9,R_gr9(%r10)
	stw	%r16,R_gr16(%r10)
	stw	%r17,R_gr17(%r10)
	stw	%r24,R_gr24(%r10)
	stw	%r25,R_gr25(%r10)

; save control registers

	mfctl	%cr0,%r1
	stw	%r1,R_cr0(%r10)
	stw	%r0,R_cr1(%r10)
	stw	%r0,R_cr2(%r10)
	stw	%r0,R_cr3(%r10)
	stw	%r0,R_cr4(%r10)
	stw	%r0,R_cr5(%r10)
	stw	%r0,R_cr6(%r10)
	stw	%r0,R_cr7(%r10)
	mfctl	%cr8,%r1
	stw	%r1,R_cr8(%r10)
	mfctl	%cr9,%r1
	stw	%r1,R_cr9(%r10)
	mfctl	%cr10,%r1
	stw	%r1,R_cr10(%r10)
	mfctl	%cr11,%r1
	stw	%r1,R_cr11(%r10)
	mfctl	%cr12,%r1
	stw	%r1,R_cr12(%r10)
	mfctl	%cr13,%r1
	stw	%r1,R_cr13(%r10)
	mfctl	%cr14,%r1
	stw	%r1,R_cr14(%r10)
	mfctl	%cr15,%r1
	stw	%r1,R_cr15(%r10)
	mfctl	%cr16,%r1
	stw	%r1,R_cr16(%r10)
	mfctl	%cr17,%r1
	stw	%r1,R_cr17H(%r10)
	mtctl	%r1,%cr17
	mfctl	%cr17,%r1
	stw	%r1,R_cr17T(%r10)
	mtctl	%r1,%cr17
	mfctl	%cr18,%r1
	stw	%r1,R_cr18H(%r10)
	mtctl	%r1,%cr18
	mfctl	%cr18,%r1
	stw	%r1,R_cr18T(%r10)
	mtctl	%r1,%cr18
	mfctl	%cr19,%r1
	stw	%r1,R_cr19(%r10)
	mfctl	%cr20,%r1
	stw	%r1,R_cr20(%r10)
	mfctl	%cr21,%r1
	stw	%r1,R_cr21(%r10)
	mfctl	%cr22,%r1
	stw	%r1,R_cr22(%r10)
	mfctl	%cr23,%r1
	stw	%r1,R_cr23(%r10)
	mfctl	%cr24,%r1
	stw	%r1,R_cr24(%r10)
	mfctl	%cr25,%r1
	stw	%r1,R_cr25(%r10)
	mfctl	%cr26,%r1
	stw	%r1,R_cr26(%r10)
	mfctl	%cr27,%r1
	stw	%r1,R_cr27(%r10)
	mfctl	%cr28,%r1
	stw	%r1,R_cr28(%r10)
	mfctl	%cr29,%r1
	stw	%r1,R_cr29(%r10)
	mfctl	%cr30,%r1
	stw	%r1,R_cr30(%r10)
	mfctl	%cr31,%r1
	stw	%r1,R_cr31(%r10)

; save diagnose registers

	mfcpu_c	0,%r1
	mfcpu_c	0,%r1
	stw	%r1,R_cpu0(%r10)

; save space registers

	mfsp	%sr0,%r1
	stw	%r1,R_sr0(%r10)
	mfsp	%sr1,%r1
	stw	%r1,R_sr1(%r10)
	mfsp	%sr2,%r1
	stw	%r1,R_sr2(%r10)
	mfsp	%sr3,%r1
	stw	%r1,R_sr3(%r10)
	mfsp	%sr4,%r1
	stw	%r1,R_sr4(%r10)
	mfsp	%sr5,%r1
	stw	%r1,R_sr5(%r10)
	mfsp	%sr6,%r1
	stw	%r1,R_sr6(%r10)
	mfsp	%sr7,%r1
	bv	(%rp)
	stw	%r1,R_sr7(%r10)

#ifdef	DEBUG_DEBUGGER
;-------------------------------------------------------------------------------
printit
	mtctl	%rp,%tr0
	mtctl	%r1,%tr1
	bl	putnum,%rp
	copy	%rp,%arg0

	mtctl	%mrp,%tr2
	bl	putc,%rp
	ldi	CR,%arg0
	bl	putc,%rp
	ldi	LF,%arg0
	mfctl	%tr2,%mrp
	mfctl	%tr1,%r1
	bv	(%mrp)
	mfctl	%tr0,%rp
#endif
	.space	$PRIVATE$
	.subspa	$DATA$,align=4,access=0x1f

Exception_index
	.word	0
	
RegBlk
	.block	R_SIZE		; register block

Stub_stack
	.block	1024

	.end
