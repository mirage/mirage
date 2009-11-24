/****************************************************************************

		THIS SOFTWARE IS NOT COPYRIGHTED

   HP offers the following for use in the public domain.  HP makes no
   warranty with regard to the software or it's performance and the
   user accepts the software "AS IS" with all faults.

   HP DISCLAIMS ANY WARRANTIES, EXPRESS OR IMPLIED, WITH REGARD
   TO THIS SOFTWARE INCLUDING BUT NOT LIMITED TO THE WARRANTIES
   OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

****************************************************************************/

		/* Diagnose register definitions */


#ifdef PCXL

#define CPU_DIAG_0_L2IHPMC_BIT           6   /* Level 2 I-cache error flag */
#define CPU_DIAG_0_L2DHPMC_BIT           8   /* Level 2 D-cache error flag */
#define CPU_DIAG_0_L1IHPMC_BIT          10   /* Level 1 I-cache error flag */
#define CPU_DIAG_0_L2PARERR_BIT         15   /* rightmost bit */
#define	CPU_DIAG_0_PREV_HPMC_PREP_BIT   16   /* Previous HPMC finished */
#define	CPU_DIAG_0_PWR_FAIL_BIT	        17
#define	CPU_DIAG_0_EXPECT_HPMC_BIT      18   /* Expecting HPMC */

	/* Mask for Read/clear bits in CPU diagnose register 0 */
#define CPU0_MASK	0x02AF0000

#else  /* PCXT */

#define CPU_DIAG_0_PREV_HPMC_PREP_BIT	 3   /* Previous HPMC finished */
#define	CPU_DIAG_0_BOOTING_BIT		 4
#define	CPU_DIAG_0_EXPECT_HPMC_BIT	 5   /* Expecting HPMC */

#define CPU_DIAG_0_DHPMC_BIT		10
#define CPU_DIAG_0_ILPMC_BIT		14
#define CPU_DIAG_0_HTOC_BIT		23

	/* Mask for Read/clear bits in CPU diagnose register 0 */
#define CPU0_MASK	0x00220100

#endif

		/* Diagnose instruction macros */

#ifdef PCXL

/*** Different PCXL diagnose commands ***/

/* Original mfcpu replaced with the two commands mfcpu_t & mfcpu_c */
mfcpu_t .macro	diag_reg,gen_reg
	{ 0 ..	5}	= 0x5 {26 .. 31}
	{ 6 .. 10}	= diag_reg {27 .. 31}
	{11 .. 15}	= 0x0 {27 .. 31}
	{16 .. 18}	= 0x0 {29 .. 31}
	{19 .. 26}	= 0xa0 {24 .. 31}
	{27 .. 31}	= gen_reg {27 .. 31}
	.endm

mfcpu_c .macro	diag_reg,gen_reg
	{ 0 ..	5}	= 0x5 {26 .. 31}
	{ 6 .. 10}	= diag_reg {27 .. 31}
	{11 .. 15}	= gen_reg {27 .. 31}
	{16 .. 18}	= 0x0 {29 .. 31}
	{19 .. 26}	= 0x30 {24 .. 31}
	{27 .. 31}	= 0x0 {27 .. 31}
	.endm

mtcpu	.macro	gen_reg,diag_reg
	{ 0 ..	5}	= 0x5 {26 .. 31}
	{ 6 .. 10}	= diag_reg {27 .. 31}
	{11 .. 15}	= gen_reg {27 .. 31}
	{16 .. 18}	= 0x0 {29 .. 31}
	{19 .. 26}	= 0x12 {24 .. 31}
	{27 .. 31}	= 0x0 {27 .. 31}
	.endm

shdw_gr .macro
	{ 0 ..	5}	= 0x5 {26 .. 31}
	{ 6 .. 10}	= 0x0 {27 .. 31}
	{11 .. 15}	= 0x0 {27 .. 31}
	{16 .. 18}	= 0x0 {29 .. 31}
	{19 .. 26}	= 0xd0 {24 .. 31}
	{27 .. 31}	= 0x0 {27 .. 31}
	.endm

gr_shdw .macro
	{ 0 ..	5}	= 0x5 {26 .. 31}
	{ 6 .. 10}	= 0x0 {27 .. 31}
	{11 .. 15}	= 0x0 {27 .. 31}
	{16 .. 18}	= 0x0 {29 .. 31}
	{19 .. 26}	= 0xd2 {24 .. 31}
	{27 .. 31}	= 0x0 {27 .. 31}
	.endm

#else

/*** original PCXT version ***/

/* Originally  was mfcpu without the _c */
mfcpu_c .macro	diag_reg,gen_reg
	{ 0 ..	5}	= 0x5 {26 .. 31}
	{ 6 .. 10}	= diag_reg {27 .. 31}
	{11 .. 15}	= gen_reg {27 .. 31}
	{16 .. 18}	= 0x0 {29 .. 31}
	{19 .. 26}	= 0xd0 {24 .. 31}
	{27 .. 31}	= 0x0 {27 .. 31}
	.endm

mtcpu	.macro	gen_reg,diag_reg
	{ 0 ..	5}	= 0x5 {26 .. 31}
	{ 6 .. 10}	= diag_reg {27 .. 31}
	{11 .. 15}	= gen_reg {27 .. 31}
	{16 .. 18}	= 0x0 {29 .. 31}
	{19 .. 26}	= 0xb0 {24 .. 31}
	{27 .. 31}	= 0x0 {27 .. 31}
	.endm

shdw_gr .macro
	{ 0 ..	5}	= 0x5 {26 .. 31}
	{ 6 .. 10}	= 0x2 {27 .. 31}
	{11 .. 15}	= 0x0 {27 .. 31}
	{16 .. 18}	= 0x1 {29 .. 31}
	{19 .. 26}	= 0x30 {24 .. 31}
	{27 .. 31}	= 0x0 {27 .. 31}
	.endm

gr_shdw .macro
	{ 0 ..	5}	= 0x5 {26 .. 31}
	{ 6 .. 10}	= 0x2 {27 .. 31}
	{11 .. 15}	= 0x0 {27 .. 31}
	{16 .. 18}	= 0x0 {29 .. 31}
	{19 .. 26}	= 0x31 {24 .. 31}
	{27 .. 31}	= 0x0 {27 .. 31}
	.endm

#endif


	/* Actual commands used doubled instructions for cpu timing */


#define SHDW_GR		shdw_gr ! \
			shdw_gr


	/* Break instruction definitions */

#define i13BREAK	0xa5a	/* im13 field for specified functions */
#define i5REG		0x06	/* Init registers */
#define i5BP		0x09	/* GDB breakpoint */
#define i5PSW		0x0b	/* Get PSW */
#define i5INLINE	0x0e	/* Get INLINE */

BR_INIT_REGS	.macro
	break	i5REG,i13BREAK
	.endm

BR_GET_PSW	.macro
	break	i5PSW,i13BREAK
	.endm

BR_INLINE	.macro
	break	i5INLINE,i13BREAK
	.endm

