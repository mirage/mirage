/****************************************************************************

		THIS SOFTWARE IS NOT COPYRIGHTED

   HP offers the following for use in the public domain.  HP makes no
   warranty with regard to the software or it's performance and the
   user accepts the software "AS IS" with all faults.

   HP DISCLAIMS ANY WARRANTIES, EXPRESS OR IMPLIED, WITH REGARD
   TO THIS SOFTWARE INCLUDING BUT NOT LIMITED TO THE WARRANTIES
   OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

****************************************************************************/

		/* Interrupt Vector Table entry macros */

#define	cstring(Len,String)	.byte	Len !\
				.string	String

#define	cstringz(Len,String)	.byte	Len !\
				.stringz	String

AdvancePCOQ	.macro
	mtctl	%r0,%pcoq	; throw away iiaoq head pointer, tail->head
	mfctl	%pcoq,%r1	; get tail pointer
	mtctl	%r1,%pcoq	; insert tail pointer
	ldo	4(%r1),%r1	; advance tail pointer
	mtctl	%r1,%pcoq	; insert new tail pointer, former tail->head
	.endm

#ifdef	PRINTSTRING_LED
PrintString	.macro	NString,Num
	bl	put_led,%mrp
	ldi	Num+0xa0,%arg2
	addil	L%NString-$global$,%dp
	bl	puts,%rp
	ldo	R%NString-$global$(%r1),%arg0
	b,n	.
	nop
	.endm
#endif

#ifdef	HALT

PrintString	.macro	NString,Num
	bl,n	save_state,%r25
	nop
	bl	print_intr,%rp
	ldi	NString-Str01,%arg0
	bl	print_state,%rp
	nop
	b,n	halt
	nop
	.endm

#endif

#ifdef	RECOVER

PrintString	.macro	NString,Num
	bl,n	save_state,%r25
	nop
	bl	print_intr,%rp
	ldi	NString-Str01,%arg0
	bl	print_state,%rp
	nop
	b,n	recover
	nop
	.endm

#endif

PrintString	.macro	NString,Num
	bl,n	save_state,%r25
	nop
	bl	print_intr,%rp
	ldi	NString-Str01,%arg0
#ifdef	FULL_REPORT
	bl	print_state,%rp
#else
	nop
#endif
	nop
	b	restore_to_STUB
        ldi     Num,%r1
	.endm


	/* IVA register array offets */

#define	R_sr0		  0
#define	R_sr1		  4
#define	R_sr2		  8
#define	R_sr3		 12
#define	R_sr4		 16
#define	R_sr5		 20
#define	R_sr6		 24
#define	R_sr7		 28

#define	R_gr0		 32
#define	R_gr1		 36
#define	R_gr2		 40
#define	R_gr3		 44
#define	R_gr4		 48
#define	R_gr5		 52
#define	R_gr6		 56
#define	R_gr7		 60
#define	R_gr8		 64
#define	R_gr9		 68
#define	R_gr10		 72
#define	R_gr11		 76
#define	R_gr12		 80
#define	R_gr13		 84
#define	R_gr14		 88
#define	R_gr15		 92
#define	R_gr16		 96
#define	R_gr17		100
#define	R_gr18		104
#define	R_gr19		108
#define	R_gr20		112
#define	R_gr21		116
#define	R_gr22		120
#define	R_gr23		124
#define	R_gr24		128
#define	R_gr25		132
#define	R_gr26		136
#define	R_gr27		140
#define	R_gr28		144
#define	R_gr29		148
#define	R_gr30		152
#define	R_gr31		156

#define	R_rctr		160
#define	R_cpu0		164
#define	R_pidr1		168
#define	R_pidr2		172
#define	R_ccr		176
#define	R_sar		180
#define	R_pidr3		184
#define	R_pidr4		188
#define	R_iva		192
#define	R_eiem		196

#define	R_itmr		200
#define	R_pcsqH		204
#define	R_pcoqH		208
#define	R_iir		212
#define	R_pcsqT		216
#define	R_pcoqT		220
#define	R_isr		224
#define	R_ior		228
#define	R_ipsw		232
#define	R_eirr		236

#define	R_tr0		240
#define	R_tr1		244
#define	R_tr2		248
#define	R_tr3		252
#define	R_tr4		256
#define	R_tr5		260
#define	R_tr6		264
#define	R_tr7		268

#define	R_SIZE		272
