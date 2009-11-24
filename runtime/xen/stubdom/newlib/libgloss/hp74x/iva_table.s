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

#include	"diagnose.h"
#if 0
#include	"iva_table.h"
#endif

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
R_rctr		.equ	160
R_cpu0		.equ	164
R_pidr1		.equ	168
R_pidr2		.equ	172
R_ccr 		.equ	176
R_sar 		.equ	180
R_pidr3         .equ	184
R_pidr4         .equ	188
R_iva 		.equ	192
R_eiem		.equ	196

R_itmr		.equ	200
R_pcsqH         .equ	204
R_pcoqH         .equ	208
R_iir 		.equ	212
R_pcsqT         .equ	216
R_pcoqT         .equ	220
R_isr 		.equ	224
R_ior 		.equ	228
R_ipsw		.equ	232
R_eirr		.equ	236
R_tr0 		.equ	240
R_tr1 		.equ	244
R_tr2 		.equ	248
R_tr3 		.equ	252
R_tr4 		.equ	256
R_tr5 		.equ	260
R_tr6 		.equ	264
R_tr7 		.equ	268

R_SIZE          .equ	300

	.import	putc,code
	.import	puts,code
	.import	putnum,code
	.import	put_led,code
	.import	save_regs,code
	.import	STUB_RESTORE,code
	.import	RegBlk,data
	.export	iva_table,data
	.IMPORT led_putnum,code
	.IMPORT delay,code
	.IMPORT putnum,code
	.IMPORT outbyte,code
	.IMPORT print,code

	.align	2048
iva_table
	.blockz	32	; entry 0 is reserved

	.align	32
hpmc
	nop
	b,n	hpmc_handler
	nop
	.word	0
	.word	0
	.word	0
	.word	hpmc_handler
	.word	0

	.align	32
power_fail
;	PrintString	Str02,0x2
	ldi	1,%r26
	bl,n	putnum,%r2
	nop
	
	.align	32
recovery
;;	PrintString	Str03,0x3
	ldi	2,%r26
	bl,n	putnum,%r2
	nop
		ldi	3,%r1
	b,n	handle_rcc
	nop

	.align	32
external
;	PrintString	Str04,0x4
	ldi	3,%r26
	bl,n	putnum,%r2
	nop
	
	.align	32
lpmc
;	PrintString	Str05,0x5
	ldi	4,%r26
	bl,n	putnum,%r2
	nop
	
	.align	32
itlb_miss
;	PrintString	Str06,0x6
	ldi	5,%r26
	bl,n	putnum,%r2
	nop
	
	.align	32
imem_protection
;	PrintString	Str07,0x7
	ldi	6,%r26
	bl,n	putnum,%r2
	nop
	
	.align	32
illegal_inst
;	PrintString	Str08,0x8
	ldi	7,%r26
	bl,n	putnum,%r2
	nop
	
	.align	32
break
	b,n	break_handler
	nop

	.align	32
privileged_op
;	PrintString	Str0a,0xa
	ldi	8,%r26
	bl,n	putnum,%r2
	nop
	
	.align	32
privileged_reg
;	PrintString	Str0b,0xb
	ldi	9,%r26
	bl,n	putnum,%r2
	nop
	
	.align	32
overflow
;	PrintString	Str0c,0xc
	ldi	32,%r26
	bl,n	putnum,%r2
	nop
	
	.align	32
conditional
;	PrintString	Str0d,0xd
	ldi	32,%r26
	bl,n	putnum,%r2
	nop
	
	.align	32
assist_excep
;	PrintString	Str0e,0xe
	ldi	32,%r26
	bl,n	putnum,%r2
	nop
	
	.align	32
dtlb_miss
;	PrintString	Str0f,0xf
	ldi	32,%r26
	bl,n	putnum,%r2
	nop
	
	.align	32
na_itlb
;	PrintString	Str10,0x10
	ldi	32,%r26
	bl,n	putnum,%r2
	nop
	
	.align	32
na_dtlb
;	PrintString	Str11,0x11
	ldi	32,%r26
	bl,n	putnum,%r2
	nop
	
	.align	32
dmem_protection
;	PrintString	Str12,0x12
	ldi	32,%r26
	bl,n	putnum,%r2
	nop
	
	.align	32
dmem_break
;	PrintString	Str13,0x13
	ldi	32,%r26
	bl,n	putnum,%r2
	nop
	
	.align	32
tlb_dirty
;	PrintString	Str14,0x14
	ldi	32,%r26
	bl,n	putnum,%r2
	nop
	
	.align	32
page_ref
;	PrintString	Str15,0x15
	ldi	32,%r26
	bl,n	putnum,%r2
	nop
	
	.align	32
assist_emul
;	PrintString	Str16,0x16
	ldi	32,%r26
	bl,n	putnum,%r2
	nop
	
	.align	32
high_priv
;	PrintString	Str17,0x17
	ldi	32,%r26
	bl,n	putnum,%r2
	nop
	
	.align	32
low_priv
;	PrintString	Str18,0x18
	ldi	32,%r26
	bl,n	putnum,%r2
	nop
	
	.align	32
branch_taken
;	PrintString	Str19,0x19
	ldi	32,%r26
	bl,n	putnum,%r2
	nop
	
/*
 * foobar -- debug procedure calling between C and assembler
 */
	.EXPORT foobar,ENTRY,ARGW0=GR,RTNVAL=GR
foobar
	.PROC
	.CALLINFO CALLER,FRAME=128,SAVE_RP
	.ENTRY

	stw     %r2,-20(0,%r30)			; stash the return pointer
	ldo	128(%r30),%r30			; push up the stack pointer

	ldi	8, %r26
	bl,n	led_putnum,%r2
	nop
        ldil 	L'900000,%r26
        ldo 	R'900000(%r26),%r26
	bl,n	delay,%r2
	nop
	ldi	8, %r26
	bl,n	led_putnum,%r2
	nop
        ldil 	L'900000,%r26
        ldo 	R'900000(%r26),%r26
	bl,n	delay,%r2
	nop
;;	copy	%r26,%r26
;;	bl,n	putnum,%r2
	nop

	ldw 	-148(0,%r30),%r2		; retrieve the return pointer
	ldo 	-128(%r30),%r30			; reset the stack pointer
	bv,n    0(%r2) 
	nop
	
	.EXIT
	.PROCEND
	
/*
 * setup_vectors -- add vectors for GDB to the vector table.
 *	%r3 - current vector table
 *	%r4 - new vector table
 */
	.EXPORT setup_vectors,ENTRY,ARGW0=GR,RTNVAL=GR
setup_vectors
	.PROC
	.CALLINFO CALLER,FRAME=128,SAVE_RP
	.ENTRY
	stw     %r2,-20(0,%r30)			; stash the return pointer
	ldo	128(%r30),%r30			; push up the stack pointer

        mfctl   %iva,%r3

	ldil 	L%iva_table,%r4			; Get the new vector table
        ldo 	R%iva_table(%r4),%r4		; address
	
	ldil 	L%break_handler,%r5		; Get the breakpoint
        ldo 	R%break_handler(%r5),%r5	; handler vector

	ldil 	L%break_default,%r6		; Get the default handler
        ldo 	R%break_default(%r6),%r6	; vector

	stw	%r6,4(%r4)			; ad the default vector
	stw	%r5,36(%r4)			; add the break vector

	mtctl	%r4,%iva
	
	ldw 	-148(0,%r30),%r2		; retrieve the return pointer
	ldo 	-128(%r30),%r30			; reset the stack pointer
	bv,n    0(%r2) 
	nop
	
	.EXIT
	.PROCEND

;-------------------------------------------------------------------------------
hpmc_handler
	bl,n	save_state,%r25
	nop
	bl	print_intr,%rp
	ldi	Str01-Str01,%arg0
	bl	print_state,%rp
	nop
	ldil	L%0xf0000000,%r1
	ldw	(%r1),%r1		; read from ROM to reset HPMC

	mfcpu_c	0,%r1
	mfcpu_c	0,%r1
	depi	0,CPU_DIAG_0_PREV_HPMC_PREP_BIT,1,%r1	; clear Prev HPMC bit
	
#ifdef PCXL
	depi    0,CPU_DIAG_0_L2DHPMC_BIT,1,%r1
	depi    0,CPU_DIAG_0_L2IHPMC_BIT,1,%r1
	depi    0,CPU_DIAG_0_L1IHPMC_BIT,1,%r1
	depi    0,CPU_DIAG_0_L2PARERR_BIT,4,%r1
#else	/* PCXT */
	depi	0,CPU_DIAG_0_DHPMC_BIT,1,%r1		; don't clear DHPMC
	depi	0,CPU_DIAG_0_ILPMC_BIT,1,%r1		; don't clear ILPMC
	depi	0,CPU_DIAG_0_HTOC_BIT,1,%r1		; don't clear HTOC
#endif

	mtcpu	%r1,0
	mtcpu	%r1,0

	b,n	restore_to_STUB
	ldi	0x1,%r1

/*
 * break_handler -- this is the main entry point for an exception
 */
	.ALIGN	2048
break_handler

	mfctl	%iir,%r1			; r1 = break instruction
	extru	%r1,18,13,%r8
	ldo	-i13BREAK(%r8),%r8		; if im13 field doesn't match
	comb,<>,n %r8,%r0,break_default		;   go to default operation
	extru	%r1,31,5,%r8
	ldi	0x9,%r1				; set exception index
	comib,=,n i5BP,%r8,break_breakpoint
	comib,=,n i5PSW,%r8,break_psw
	comib,=,n i5REG,%r8,break_reg_init
	comib,=,n i5INLINE,%r8,break_breakpoint 
	; fall through to break_default

break_default
;	PrintString	Str09,0x9
	ldi	32,%r26
	bl,n	putnum,%r2
	nop
	
break_reg_init
	bl	setup_vectors,%r25
	nop
	bl	save_regs,%r25
	nop
	; fall through to advance past break instruction

break_psw
	b,n	recover

break_breakpoint
	b,n	STUB_RESTORE

;-------------------------------------------------------------------------------

handle_rcc
        mfctl   %ipsw,%r1
        bb,>=,n %r1,10,do_restore	; check nullify bit
	dep     %r0,10,1,%r1
        mtctl   %r1,%ipsw               ; clear nullify bit

	;; was the AdvancePCOQ .macro
	mtctl   %r0,%pcoq       	; throw away iiaoq head pointer, tail->head
        mfctl   %pcoq,%r1       	; get tail pointer
        mtctl   %r1,%pcoq       	; insert tail pointer
        ldo     4(%r1),%r1      	; advance tail pointer
        mtctl   %r1,%pcoq       	; insert new tail pointer, former tail->head

do_restore
	b,n	STUB_RESTORE
	nop
;-------------------------------------------------------------------------------

print_intr
; %dp may be messed up, so do self-relocating to reach Save_area
	blr	%r0,%r1
	addil	L%Str01-pr_intr_0,%r1

pr_intr_0
	ldo	R%Str01-pr_intr_0(%r1),%r1	; r1 points to Save_area
	b	puts				; print string--return through rp
	add	%r1,%arg0,%arg0

;-------------------------------------------------------------------------------

halt
; %dp may be messed up, so do self-relocating to reach Save_area
	blr	%r0,%r1
	addil	L%HaltStr-halt_0,%r1

halt_0
	bl	puts,%rp			; print halt message
	ldo	R%HaltStr-halt_0(%r1),%arg0

	nop
	b,n	.				; loop forever
	nop

;-------------------------------------------------------------------------------

recover
	;; was the AdvancePCOQ .macro
	mtctl   %r0,%pcoq       		; throw away iiaoq head pointer, tail->head
        mfctl   %pcoq,%r1       		; get tail pointer
        mtctl   %r1,%pcoq       		; insert tail pointer
        ldo     4(%r1),%r1      		; advance tail pointer
        mtctl   %r1,%pcoq       		; insert new tail pointer, former tail->head

	rfir

;-------------------------------------------------------------------------------

save_state	; %r25 is return pointer
; %dp may be messed up, so do self-relocating to reach Save_area
	blr	%r0,%r1
	addil	L%Save_area-sa_st_0,%r1

sa_st_0
	ldo	R%Save_area-sa_st_0(%r1),%r1	; r1 points to Save_area

; save general registers
	stw	%r0,R_gr0(%r1)
				; don't save %r1 until restored
	stw	%r2,R_gr2(%r1)
	stw	%r3,R_gr3(%r1)
	stw	%r4,R_gr4(%r1)
	stw	%r5,R_gr5(%r1)
	stw	%r6,R_gr6(%r1)
	stw	%r7,R_gr7(%r1)
				; don't save %r8, %r9 until restored
	stw	%r10,R_gr10(%r1)
	stw	%r11,R_gr11(%r1)
	stw	%r12,R_gr12(%r1)
	stw	%r13,R_gr13(%r1)
	stw	%r14,R_gr14(%r1)
	stw	%r15,R_gr15(%r1)
				; don't save %r16, %r17 until restored
	stw	%r18,R_gr18(%r1)
	stw	%r19,R_gr19(%r1)
	stw	%r20,R_gr20(%r1)
	stw	%r21,R_gr21(%r1)
	stw	%r22,R_gr22(%r1)
	stw	%r23,R_gr23(%r1)
				; don't save %r24, %r25 until restored
	stw	%r26,R_gr26(%r1)
	stw	%r27,R_gr27(%r1)
	stw	%r28,R_gr28(%r1)
	stw	%r29,R_gr29(%r1)
	copy	%r25,%rp	; copy return pointer to %rp
	stw	%r30,R_gr30(%r1)
	copy	%r1,%r19	; save Save_area pointer in %r19
	stw	%r31,R_gr31(%r1)
	shdw_gr			; restore %r1 and %r25 (et al.) from shadow regs
	shdw_gr
	stw	%r1,R_gr1(%r19)	; save %r1
	stw	%r8,R_gr8(%r19)
	stw	%r9,R_gr9(%r19)
	stw	%r16,R_gr16(%r19)
	stw	%r17,R_gr17(%r19)
	stw	%r24,R_gr24(%r19)

; save control registers
	mfctl	%rctr,%r1
	stw	%r1,R_rctr(%r19)
	mfctl	%pidr1,%r1
	stw	%r1,R_pidr1(%r19)
	mfctl	%pidr2,%r1
	stw	%r1,R_pidr2(%r19)
	mfctl	%ccr,%r1
	stw	%r1,R_ccr(%r19)
	mfctl	%sar,%r1
	stw	%r1,R_sar(%r19)
	mfctl	%pidr3,%r1
	stw	%r1,R_pidr3(%r19)
	mfctl	%pidr4,%r1
	stw	%r1,R_pidr4(%r19)
	mfctl	%iva,%r1
	stw	%r1,R_iva(%r19)
	mfctl	%eiem,%r1
	stw	%r1,R_eiem(%r19)
	mfctl	%itmr,%r1
	stw	%r1,R_itmr(%r19)
	mfctl	%pcsq,%r1
	mtctl	%r1,%pcsq
	stw	%r1,R_pcsqH(%r19)
	mfctl	%pcsq,%r1
	mtctl	%r1,%pcsq
	stw	%r1,R_pcsqT(%r19)
	mfctl	%pcoq,%r1
	mtctl	%r1,%pcoq
	stw	%r1,R_pcoqH(%r19)
	mfctl	%pcoq,%r1
	mtctl	%r1,%pcoq
	stw	%r1,R_pcoqT(%r19)
	mfctl	%iir,%r1
	stw	%r1,R_iir(%r19)
	mfctl	%isr,%r1
	stw	%r1,R_isr(%r19)
	mfctl	%ior,%r1
	stw	%r1,R_ior(%r19)
	mfctl	%ipsw,%r1
	stw	%r1,R_ipsw(%r19)
	mfctl	%eirr,%r1
	stw	%r1,R_eirr(%r19)
	mfctl	%tr0,%r1
	stw	%r1,R_tr0(%r19)
	mfctl	%tr1,%r1
	stw	%r1,R_tr1(%r19)
	mfctl	%tr2,%r1
	stw	%r1,R_tr2(%r19)
	mfctl	%tr3,%r1
	stw	%r1,R_tr3(%r19)
	mfctl	%tr4,%r1
	stw	%r1,R_tr4(%r19)
	mfctl	%tr5,%r1
	stw	%r1,R_tr5(%r19)
	mfctl	%tr6,%r1
	stw	%r1,R_tr6(%r19)
	mfctl	%tr7,%r1
	stw	%r1,R_tr7(%r19)

; save diagnose registers
	mfcpu_c	0,%r1
	mfcpu_c	0,%r1
	stw	%r1,R_cpu0(%r19)

#ifdef	PRINT_SPACE
	stw	%r25,R_gr25(%r19)

; save space registers
	mfsp	%sr0,%r1
	stw	%r1,R_sr0(%r19)
	mfsp	%sr1,%r1
	stw	%r1,R_sr1(%r19)
	mfsp	%sr2,%r1
	stw	%r1,R_sr2(%r19)
	mfsp	%sr3,%r1
	stw	%r1,R_sr3(%r19)
	mfsp	%sr4,%r1
	stw	%r1,R_sr4(%r19)
	mfsp	%sr5,%r1
	stw	%r1,R_sr5(%r19)
	mfsp	%sr6,%r1
	stw	%r1,R_sr6(%r19)
	mfsp	%sr7,%r1
	bv	(%rp)
	stw	%r1,R_sr7(%r19)
#else
	bv	(%rp)
	stw	%r25,R_gr25(%r19)
#endif


;-------------------------------------------------------------------------------

restore_to_STUB		; doesn't return--goes to STUB_RESTORE
			; Note--STUB_RESTORE executes rfir,
			;	so we don't need to
	copy	%r1,%r8	; save exception index
; %dp may be messed up, so do self-relocating to reach Save_area
	bl	re_st_0,%r1
	addil	L%Save_area-re_st_0,%r1

re_st_0
	ldo	R%Save_area-re_st_0(%r1),%r1	; r1 points to Save_area

; restore general registers
	ldw	R_gr2(%r1),%r2
	ldw	R_gr3(%r1),%r3
	ldw	R_gr4(%r1),%r4
	ldw	R_gr5(%r1),%r5
	ldw	R_gr6(%r1),%r6
	ldw	R_gr7(%r1),%r7
;	ldw	R_gr8(%r1),%r8         don't smash the exception index
	ldw	R_gr9(%r1),%r9
	ldw	R_gr10(%r1),%r10
	ldw	R_gr11(%r1),%r11
	ldw	R_gr12(%r1),%r12
	ldw	R_gr13(%r1),%r13
	ldw	R_gr14(%r1),%r14
	ldw	R_gr15(%r1),%r15
	ldw	R_gr16(%r1),%r16
	ldw	R_gr17(%r1),%r17
	ldw	R_gr18(%r1),%r18
	ldw	R_gr19(%r1),%r19
	ldw	R_gr20(%r1),%r20
	ldw	R_gr21(%r1),%r21
	ldw	R_gr22(%r1),%r22
	ldw	R_gr23(%r1),%r23
	ldw	R_gr24(%r1),%r24
	ldw	R_gr25(%r1),%r25
	ldw	R_gr26(%r1),%r26
	ldw	R_gr27(%r1),%r27
	ldw	R_gr28(%r1),%r28
	ldw	R_gr29(%r1),%r29
	ldw	R_gr30(%r1),%r30
	ldw	R_gr31(%r1),%r31
	ldw	R_gr1(%r1),%r1
	b	STUB_RESTORE
	copy	%r8,%r1			; restore the exception index

;-------------------------------------------------------------------------------

#define	HoldPtr		%r10
#define	SavePtr		%r11
#define	StrPtr		%r12
#define	Count		%r13

#define	Hold_Hold	0*4	/* First word of hold area */
#define	Hold_Save	1*4	/* Second word of hold area */
#define	Hold_Str	2*4	/* Third word of hold area */
#define	Hold_Count	3*4	/* Fourth word of hold area */
#define	Hold_rp		4*4	/* Fifth word of hold area */

print_state
; %dp may be messed up, so do self-relocating to reach Save_area
	blr	%r0,%mrp
	addil	L%Hold_area-pr_st_0,%mrp

pr_st_0
	ldo	R%Hold_area-pr_st_0(%r1),%r1	; r1 points to Hold_area

; save working registers

	stw	HoldPtr,Hold_Hold(%r1)
	copy	%r1,HoldPtr			; HoldPtr = &Hold_area
	stw	SavePtr,Hold_Save(HoldPtr)
	ldo	Save_area-Hold_area(HoldPtr),SavePtr	; SavePtr = &Save_area
	stw	StrPtr,Hold_Str(HoldPtr)
	addil	L%PrintLabels-pr_st_0,%mrp
	stw	Count,Hold_Count(HoldPtr)
	ldo	R%PrintLabels-pr_st_0(%r1),StrPtr
	stw	%rp,Hold_rp(HoldPtr)


#ifdef	PRINT_SPACE
	ldi	68,Count
#else
	ldo	R_gr0(SavePtr),SavePtr
	ldi	60,Count
#endif

; print register values

print_loop
	bl	puts,%rp		; print label
	ldo	1(StrPtr),%arg0		; advance past length byte
	bl	putnum,%rp		; print register value
	ldwm	4(SavePtr),%arg0
	ldbs,ma	1(StrPtr),%r1
	addib,>	-1,Count,print_loop
	add	%r1,StrPtr,StrPtr

; skip to next line
	bl	puts,%rp		; print label
	ldo	1(StrPtr),%arg0		; advance past length byte

; restore working registers

	ldw	Hold_rp(HoldPtr),%rp
	ldw	Hold_Count(HoldPtr),Count
	ldw	Hold_Str(HoldPtr),StrPtr
	ldw	Hold_Save(HoldPtr),SavePtr
	bv	(%rp)
	ldw	Hold_Hold(HoldPtr),HoldPtr

#undef	SavePtr
#undef	HoldPtr
#undef	StrPtr
#undef	Count

#undef	Hold_Save
#undef	Hold_Scr
#undef	Hold_Str
#undef	Hold_Count
#undef	Hold_rp

;-------------------------------------------------------------------------------

	.space	$PRIVATE$
	.subspa	$DATA$,align=4,access=0x1f

/* Used to save machine registers before printing */
Save_area
	.block		R_SIZE		; Used to store registers

/* Used to hold callee-save registers */
Hold_area
	.block		8*4		; 8 words to store temp. registers

HaltStr
	.stringz	"\r\nHalted\r\n"

RebootStr
	.stringz	"\r\nRebooting . . .\r\n"

Str01
	.stringz	"\r\nHPMC\r\n"

Str02
	.stringz	"\r\nPower Fail\r\n"

Str03
	.stringz	"\r\nRecovery Counter Trap\r\n"

Str04
	.stringz	"\r\nExternal Interrupt\r\n"

Str05
	.stringz	"\r\nLPMC\r\n"

Str06
	.stringz	"\r\nITLB Miss\r\n"

Str07
	.stringz	"\r\nInstruction Memory Protection Trap\r\n"

Str08
	.stringz	"\r\nIllegal Instruction\r\n"

Str09
	.stringz	"\r\nBreak Trap\r\n"

Str0a
	.stringz	"\r\nPrivileged Operation\r\n"

Str0b
	.stringz	"\r\nPrivileged Register\r\n"

Str0c
	.stringz	"\r\nOverflow Trap\r\n"

Str0d
	.stringz	"\r\nConditional Trap\r\n"

Str0e
	.stringz	"\r\nAssist Exception\r\n"

Str0f
	.stringz	"\r\nData TLB Miss\r\n"

Str10
	.stringz	"\r\nNon-access ITLB Miss\r\n"

Str11
	.stringz	"\r\nNon-access DTLB Miss\r\n"

Str12
	.stringz	"\r\nData Memory Protection Trap\r\n"

Str13
	.stringz	"\r\nData Memory Break\r\n"

Str14
	.stringz	"\r\nTLB Dirty Bit Trap\r\n"

Str15
	.stringz	"\r\nPage Reference Trap\r\n"

Str16
	.stringz	"\r\nAssist Emulation Trap\r\n"

Str17
	.stringz	"\r\nHigher-privilege Trap\r\n"

Str18
	.stringz	"\r\nLower-privilege Trap\r\n"

Str19
	.stringz	"\r\nTaken Branch Trap\r\n"

Str20
	.stringz	"\r\nHere I am!\r\n"

PrintLabels
#ifdef	PRINT_SPACE
	.byte		10
	.stringz	"sr 0 = 0x"
	.byte		13
	.stringz	"sr 1 = 0x"
	.byte		13
	.stringz	"sr 2 = 0x"
	.byte		13
	.stringz	"   sr 3 = 0x"
	.byte		12
	.stringz	"\r\nsr 4 = 0x"
	.byte		13
	.stringz	"   sr 5 = 0x"
	.byte		13
	.stringz	"   sr 6 = 0x"
	.byte		13
	.stringz	"   sr 7 = 0x"
	.byte		13
	.stringz	"\r\n\ngr 0 = 0x"
#else
	.byte		10
	.stringz	"gr 0 = 0x"
#endif

	.byte		13
	.stringz	"   gr 1 = 0x"
	.byte		13
	.stringz	"   gr 2 = 0x"
	.byte		13
	.stringz	"   gr 3 = 0x"
	.byte		12
	.stringz	"\r\ngr 4 = 0x"
	.byte		13
	.stringz	"   gr 5 = 0x"
	.byte		13
	.stringz	"   gr 6 = 0x"
	.byte		13
	.stringz	"   gr 7 = 0x"
	.byte		12
	.stringz	"\r\ngr 8 = 0x"
	.byte		13
	.stringz	"   gr 9 = 0x"
	.byte		13
	.stringz	"   gr10 = 0x"
	.byte		13
	.stringz	"   gr11 = 0x"
	.byte		12
	.stringz	"\r\ngr12 = 0x"
	.byte		13
	.stringz	"   gr13 = 0x"
	.byte		13
	.stringz	"   gr14 = 0x"
	.byte		13
	.stringz	"   gr15 = 0x"
	.byte		12
	.stringz	"\r\ngr16 = 0x"
	.byte		13
	.stringz	"   gr17 = 0x"
	.byte		13
	.stringz	"   gr18 = 0x"
	.byte		13
	.stringz	"   gr19 = 0x"
	.byte		12
	.stringz	"\r\ngr20 = 0x"
	.byte		13
	.stringz	"   gr21 = 0x"
	.byte		13
	.stringz	"   gr22 = 0x"
	.byte		13
	.stringz	"   gr23 = 0x"
	.byte		12
	.stringz	"\r\ngr24 = 0x"
	.byte		13
	.stringz	"   gr25 = 0x"
	.byte		13
	.stringz	"   gr26 = 0x"
	.byte		13
	.stringz	"   gr27 = 0x"
	.byte		12
	.stringz	"\r\ngr28 = 0x"
	.byte		13
	.stringz	"   gr29 = 0x"
	.byte		13
	.stringz	"   gr30 = 0x"
	.byte		13
	.stringz	"   gr31 = 0x"
	.byte		13
	.stringz	"\r\n\nrctr = 0x"
	.byte		53
	.stringz	"                                           cpu0 = 0x"
	.byte		12
	.stringz	"\r\npid1 = 0x"
	.byte		13
	.stringz	"   pid2 = 0x"
	.byte		13
	.stringz	"    ccr = 0x"
	.byte		13
	.stringz	"    sar = 0x"
	.byte		12
	.stringz	"\r\npid3 = 0x"
	.byte		13
	.stringz	"   pid4 = 0x"
	.byte		13
	.stringz	"    iva = 0x"
	.byte		13
	.stringz	"   eiem = 0x"
	.byte		12
	.stringz	"\r\nitmr = 0x"
	.byte		13
	.stringz	"   iasq = 0x"
	.byte		13
	.stringz	"   iaoq = 0x"
	.byte		13
	.stringz	"    iir = 0x"
	.byte		32
	.stringz	"\r\n                    iasq = 0x"
	.byte		13
	.stringz	"   iaoq = 0x"
	.byte		12
	.stringz	"\r\n isr = 0x"
	.byte		13
	.stringz	"    ior = 0x"
	.byte		13
	.stringz	"   ipsw = 0x"
	.byte		13
	.stringz	"   eirr = 0x"
	.byte		12
	.stringz	"\r\ncr24 = 0x"
	.byte		13
	.stringz	"   cr25 = 0x"
	.byte		13
	.stringz	"   cr26 = 0x"
	.byte		13
	.stringz	"   cr27 = 0x"
	.byte		12
	.stringz	"\r\ncr28 = 0x"
	.byte		13
	.stringz	"   cr29 = 0x"
	.byte		13
	.stringz	"   cr30 = 0x"
	.byte		13
	.stringz	"   cr31 = 0x"
	.byte		4
	.stringz	"\r\n\n"

	.end
