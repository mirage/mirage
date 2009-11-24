/****************************************************************************

		THIS SOFTWARE IS NOT COPYRIGHTED

   HP offers the following for use in the public domain.  HP makes no
   warranty with regard to the software or it's performance and the
   user accepts the software "AS IS" with all faults.

   HP DISCLAIMS ANY WARRANTIES, EXPRESS OR IMPLIED, WITH REGARD
   TO THIS SOFTWARE INCLUDING BUT NOT LIMITED TO THE WARRANTIES
   OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

****************************************************************************/

	/* Debugger register array offets */

#define	R_gr0		 0
#define	R_gr1		 4
#define	R_gr2		 8
#define	R_gr3		12
#define	R_gr4		16
#define	R_gr5		20
#define	R_gr6		24
#define	R_gr7		28
#define	R_gr8		32
#define	R_gr9		36
#define	R_gr10		40
#define	R_gr11		44
#define	R_gr12		48
#define	R_gr13		52
#define	R_gr14		56
#define	R_gr15		60
#define	R_gr16		64
#define	R_gr17		68
#define	R_gr18		72
#define	R_gr19		76
#define	R_gr20		80
#define	R_gr21		84
#define	R_gr22		88
#define	R_gr23		92
#define	R_gr24		96
#define	R_gr25		100
#define	R_gr26		104
#define	R_gr27		108
#define	R_gr28		112
#define	R_gr29		116
#define	R_gr30		120
#define	R_gr31		124

#define	R_sr0		128
#define	R_sr1		132
#define	R_sr2		136
#define	R_sr3		140
#define	R_sr4		144
#define	R_sr5		148
#define	R_sr6		152
#define	R_sr7		156

#define	R_cr0		160
#define	R_cr1		164
#define	R_cr2		168
#define	R_cr3		172
#define	R_cr4		176
#define	R_cr5		180
#define	R_cr6		184
#define	R_cr7		188
#define	R_cr8		192
#define	R_cr9		196
#define	R_cr10		200
#define	R_cr11		204
#define	R_cr12		208
#define	R_cr13		212
#define	R_cr14		216
#define	R_cr15		220
#define	R_cr16		224
#define	R_cr17H		228
#define	R_cr18H		232
#define	R_cr19		236
#define	R_cr20		240
#define	R_cr21		244
#define	R_cr22		248
#define	R_cr23		252
#define	R_cr24		256
#define	R_cr25		260
#define	R_cr26		264
#define	R_cr27		268
#define	R_cr28		272
#define	R_cr29		276
#define	R_cr30		280
#define	R_cr31		284

#define	R_cr17T		288
#define	R_cr18T		292

#define	R_cpu0		296

#define R_SIZE          300

#define min_stack       64

; -----------------------------------------------------------
; ------ ASCII control codes
; -----------------------------------------------------------

#define	NULL	0x00	/* <break>	soft-reset	(input only) */
#define	DELP	0x03	/* <ctrl>C	del-collapse	(input only, non-std) */
#define	DELE	0x04	/* <ctrl>D	del-to_eol	(input only, non-std) */
#define	BELL	0x07	/* <ctrl>G	bell - audio */
#define	BS	0x08	/* <ctrl>H	back space	(left arrow) */
#define	HT	0x09	/* <ctrl>I	horizontal tab */
#define	LF	0x0a	/* <ctrl>J	line feed	(down arrow) */
#define	VT	0x0b	/* <ctrl>K	vertical tab	(up arrow) */
#define	FF	0x0c	/* <ctrl>L	form feed	(right arrow) */
#define	RTN	0x0d	/* <ctrl>M	carrage return */
#define	CR	0x0d	/* <ctrl>M	carrage return */
#define	INSC	0x0e	/* <ctrl>N	insert char	(input only, non-std) */
#define	XON	0x11	/* <ctrl>Q	DC1 - continue */
#define	BT	0x12	/* <ctrl>R	reverse tab	(input only, non-std) */
#define	XOFF	0x13	/* <ctrl>S	DC3 - wait */
#define	INSE	0x16	/* <ctrl>V	insert-expand	(input only, non-std) */
#define	DELC	0x18	/* <ctrl>X	delete char	(input only, non-std) */
#define	CLRH	0x1a	/* <ctrl>Z	clear/home	(input only) */
#define	ESC	0x1b	/* <ctrl>[	escape		(must call key again) */
#define	ENDL	0x1c	/* <ctrl>\	cursor-to-eol	(input only, non-std) */
#define	HOME	0x1e	/* <ctrl>^	cursor home	(input only) */
#define	DEL	0x7f	/* <shift>BS	destructive backspace */

