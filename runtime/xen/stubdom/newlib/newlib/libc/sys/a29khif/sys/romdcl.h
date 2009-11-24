; @(#)romdcl.h	1.4 90/10/14 20:56:12, Copyright 1988, 1989, 1990 AMD 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Copyright 1990 Advanced Micro Devices, Inc.
;
; This software is the property of Advanced Micro Devices, Inc  (AMD)  which
; specifically  grants the user the right to modify, use and distribute this
; software provided this notice is not removed or altered.  All other rights
; are reserved by AMD.
;
; AMD MAKES NO WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, WITH REGARD TO THIS
; SOFTWARE.  IN NO EVENT SHALL AMD BE LIABLE FOR INCIDENTAL OR CONSEQUENTIAL
; DAMAGES IN CONNECTION WITH OR ARISING FROM THE FURNISHING, PERFORMANCE, OR
; USE OF THIS SOFTWARE.
;
; So that all may benefit from your experience, please report  any  problems
; or  suggestions about this software to the 29K Technical Support Center at
; 800-29-29-AMD (800-292-9263) in the USA, or 0800-89-1131  in  the  UK,  or
; 0031-11-1129 in Japan, toll free.  The direct dial number is 512-462-4118.
;
; Advanced Micro Devices, Inc.
; 29K Support Products
; Mail Stop 573
; 5900 E. Ben White Blvd.
; Austin, TX 78741
; 800-292-9263
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.sbttl	"Register, Constant and Macro Declarations - v1.4"

; Copyright 1988, Advanced Micro Devices
; Written by Gibbons and Associates, Inc.

;v1.4	JG	correct FUNCTION macro - fault in register padding to even

;-----------------------------------------------------------------------
;Global registers
;-----------------------------------------------------------------------
	.reg	rsp,		gr1	;local reg. var. stack pointer

	.equ	SYS_TEMP,	64	;system temp registers

	.reg	st0,		gr64
	.reg	st1,		gr65
	.reg	st2,		gr66
	.reg	st3,		gr67
	.reg	st4,		gr68
	.reg	st5,		gr69
	.reg	st6,		gr70
	.reg	st7,		gr71
	.reg	st8,		gr72
	.reg	st9,		gr73
	.reg	st10,		gr74
	.reg	st11,		gr75
	.reg	st12,		gr76
	.reg	st13,		gr77
	.reg	st14,		gr78
	.reg	st15,		gr79

	.equ	SYS_STAT,	80	;system static registers

	.reg	ss0,		gr80
	.reg	ss1,		gr81
	.reg	ss2,		gr82
	.reg	ss3,		gr83
	.reg	ss4,		gr84
	.reg	ss5,		gr85
	.reg	ss6,		gr86
	.reg	ss7,		gr87
	.reg	ss8,		gr88
	.reg	ss9,		gr89
	.reg	ss10,		gr90
	.reg	ss11,		gr91
	.reg	ss12,		gr92
	.reg	ss13,		gr93
	.reg	ss14,		gr94
	.reg	ss15,		gr95

	.equ	RET_VAL,	96	;return registers

	.reg	v0,		gr96
	.reg	v1,		gr97
	.reg	v2,		gr98
	.reg	v3,		gr99
	.reg	v4,		gr100
	.reg	v5,		gr101
	.reg	v6,		gr102
	.reg	v7,		gr103
	.reg	v8,		gr104
	.reg	v9,		gr105
	.reg	v10,		gr106
	.reg	v11,		gr107
	.reg	v12,		gr108
	.reg	v13,		gr109
	.reg	v14,		gr110
	.reg	v15,		gr111

	.equ	TEMP_REG,	96	;temp registers

	.reg	t0,		gr96
	.reg	t1,		gr97
	.reg	t2,		gr98
	.reg	t3,		gr99
	.reg	t4,		gr100
	.reg	t5,		gr101
	.reg	t6,		gr102
	.reg	t7,		gr103
	.reg	t8,		gr104
	.reg	t9,		gr105
	.reg	t10,		gr106
	.reg	t11,		gr107
	.reg	t12,		gr108
	.reg	t13,		gr109
	.reg	t14,		gr110
	.reg	t15,		gr111

	.equ	RES_REG,	112	;reserved (for user)

	.reg	r0,		gr112
	.reg	r1,		gr113
	.reg	r2,		gr114
	.reg	r3,		gr115

	.equ	TEMP_EXT,	116	;temp extension (and shared)

	.reg	x0,		gr116
	.reg	x1,		gr117
	.reg	x2,		gr118
	.reg	x3,		gr119
	.reg	x4,		gr120
	.reg	x5,		gr121
	.reg	x6,		gr122
	.reg	x7,		gr123
	.reg	x8,		gr124

;-----------------------------------------------------------------------
;Global registers with special calling convention uses
;-----------------------------------------------------------------------

	.reg	tav,		gr121	;trap handler argument (also x6)
	.reg	tpc,		gr122	;trap handler return (also x7)
	.reg	lsrp,		gr123	;large return pointer (also x8)
	.reg	slp,		gr124	;static link pointer (also x9)
	.reg	msp,		gr125	;memory stack pointer
	.reg	rab,		gr126	;register alloc bound
	.reg	rfb,		gr127	;register frame bound

;-----------------------------------------------------------------------
;Local compiler registers - output parameters, etc.
;  (only valid if frame has been established)
;-----------------------------------------------------------------------

	.reg	p15,		lr17	;parameter registers
	.reg	p14,		lr16
	.reg	p13,		lr15
	.reg	p12,		lr14
	.reg	p11,		lr13
	.reg	p10,		lr12
	.reg	p9,		lr11
	.reg	p8,		lr10
	.reg	p7,		lr9
	.reg	p6,		lr8
	.reg	p5,		lr7
	.reg	p4,		lr6
	.reg	p3,		lr5
	.reg	p2,		lr4
	.reg	p1,		lr3
	.reg	p0,		lr2


;-----------------------------------------------------------------------
;TLB register count
;-----------------------------------------------------------------------

	.equ	TLB_CNT,	128

	.eject

;-----------------------------------------------------------------------
;constants for general use
;-----------------------------------------------------------------------
	.equ	WRD_SIZ,	4		;word size
	.equ	TRUE,		0x80000000	;logical true -- bit 31
	.equ	FALSE,		0x00000000	;logical false -- 0
	.equ	CHKPAT_a5,	0xa5a5a5a5	;check pattern

;-----------------------------------------------------------------------
;constants for data access control
;-----------------------------------------------------------------------
	.equ	CE,		0b1		;coprocessor enable
	.equ	CD,		0b0		;coprocessor disable

	.equ	AS,		0b1000000	 ;set for I/O
	.equ	PA,		0b0100000	 ;set for physical ad
	.equ	SB,		0b0010000	 ;set for set BP
	.equ	UA,		0b0001000	 ;set for user access

	.equ	ROM_OPT,	0b100		 ;OPT values for acc
	.equ	DATA_OPT,	0b000
	.equ	INST_OPT,	0b000

	.equ	ROM_CTL,	(PA + ROM_OPT)	;control field
	.equ	DATA_CTL,	(PA + DATA_OPT)
	.equ	INST_CTL,	(PA + INST_OPT)
	.equ	IO_CTL,		(AS + PA + DATA_OPT)


	.eject

;-----------------------------------------------------------------------
;defined vectors
;-----------------------------------------------------------------------

	.equ	V_IllegalOp,		0
	.equ	V_Unaligned,		1
	.equ	V_OutOfRange,		2
	.equ	V_NoCoProc,		3
	.equ	V_CoProcExcept,		4
	.equ	V_ProtViol,		5
	.equ	V_InstAccExcept,	6
	.equ	V_DataAccExcept,	7
	.equ	V_UserInstTLB,		8
	.equ	V_UserDataTLB,		9
	.equ	V_SupInstTLB,		10
	.equ	V_SupDataTLB,		11
	.equ	V_InstTLBProt,		12
	.equ	V_DataTLBProt,		13
	.equ	V_Timer,		14
	.equ	V_Trace,		15
	.equ	V_INTR0,		16
	.equ	V_INTR1,		17
	.equ	V_INTR2,		18
	.equ	V_INTR3,		19
	.equ	V_TRAP0,		20
	.equ	V_TRAP1,		21

	;				22 - 31 reserved

	.equ	V_MULTIPLY,		32
	.equ	V_DIVIDE,		33
	.equ	V_MULTIPLU,		34
	.equ	V_DIVIDU,		35
	.equ	V_CONVERT,		36

	;				37 - 41 reserved

	.equ	V_FEQ,			42
	.equ	V_DEQ,			43
	.equ	V_FGT,			44
	.equ	V_DGT,			45
	.equ	V_FGE,			46
	.equ	V_DGE,			47
	.equ	V_FADD,			48
	.equ	V_DADD,			49
	.equ	V_FSUB,			50
	.equ	V_DSUB,			51
	.equ	V_FMUL,			52
	.equ	V_DMUL,			53
	.equ	V_FDIV,			54
	.equ	V_DDIV,			55

	;				56 - 63 reserved

	.equ	V_SPILL,		64
	.equ	V_FILL,			65
	.equ	V_BSDCALL,		66
	.equ	V_SYSVCALL,		67
	.equ	V_BRKPNT,		68
	.equ	V_EPI_OS,		69

	.eject

 .macro	R_LEFT,REGVAR

 ;Rotate left
 ;
 ; Parameters:	REGVAR	register to rotate

	add	REGVAR, REGVAR, REGVAR	;shift left by 1 bit, C = MSB
	addc	REGVAR, REGVAR, 0	;add C to LSB

 .endm
;----------------------------------------------------------------------


 .macro	FUNCTION,NAME,INCNT,LOCCNT,OUTCNT

 ;Introduces a non-leaf routine.
 ;
 ;This macro defines the standard tag word before the function,
 ;then establishes the statement label with the function's name
 ;and finally allocates a register stack frame.  It may not be used
 ;if a memory stack frame is required.
 ;
 ;Note also that the size of the register stack frame is limited.
 ;Neither this nor the lack of a memory frame is considered to be
 ;a severe restriction in an assembly language environment.  The
 ;assembler will report errors if the requested frame is too large
 ;for this macro.
 ;
 ;It may be good practice to allocate an even number of both output
 ;registers and local registers.  This will help in maintaining
 ;double word alignment within these groups.  The macro will assure
 ;double word alignment of the stack frame as a whole as required
 ;for correct linkage.
 ;
 ; Paramters:	NAME	the function name
 ;		INCNT	input parameter count
 ;		LOCCNT	local register count
 ;		OUTCNT	output parameter count

	.set	ALLOC_CNT, ((2 + OUTCNT + LOCCNT) << 2)
	.set	PAD_CNT, (ALLOC_CNT & 4)
	.set	ALLOC_CNT, (ALLOC_CNT + PAD_CNT)
	.set	REG_PAD, (PAD_CNT >> 2)
   .if	(INCNT)
	.set	IN_PRM, (4 + OUTCNT + REG_PAD + LOCCNT + 0x80)
   .endif
   .if	(LOCCNT)
	.set	LOC_REG, (2 + OUTCNT + REG_PAD + 0x80)
   .endif
   .if	(OUTCNT)
	.set	OUT_PRM, (2 + 0x80)
   .endif

	.word	((2 + OUTCNT + LOCCNT) << 16)
NAME:
	sub	rsp, rsp, ALLOC_CNT
	asgeu	V_SPILL, rsp, rab
	add	lr1, rsp, ((4 + OUTCNT + LOCCNT + REG_PAD + INCNT) << 2)

 .endm
;----------------------------------------------------------------------


 .macro	LEAF,NAME,INCNT

 ;Introduces a leaf routine
 ;
 ;This macro defines the standard tag word before the function,
 ;then establishes the statement label with the function's name.
 ;
 ; Paramters:	NAME	the function name
 ;		INCNT	input parameter count

   .if	(INCNT)
	.set	IN_PRM, (2 + 0x80)
   .endif
	.set	ALLOC_CNT, 0

	.word	0
NAME:

 .endm
;----------------------------------------------------------------------


 .macro	EPILOGUE

 ;De-allocates register stack frame (only and only if necessary).

   .if	(ALLOC_CNT)

	add	rsp, rsp, ALLOC_CNT
	nop
	jmpi	lr0
	asleu	V_FILL, lr1, rfb

   .else

	jmpi	lr0
	nop

   .endif

	.set	IN_PRM, (1024)		;illegal, to cause err on ref
	.set	LOC_REG, (1024)		;illegal, to cause err on ref
	.set	OUT_PRM, (1024)		;illegal, to cause err on ref
	.set	ALLOC_CNT, (1024)	;illegal, to cause err on ref

 .endm
;----------------------------------------------------------------------


;Initial values for macro set variables to guard against misuse

	.set	IN_PRM, (1024)		;illegal, to cause err on ref
	.set	LOC_REG, (1024)		;illegal, to cause err on ref
	.set	OUT_PRM, (1024)		;illegal, to cause err on ref
	.set	ALLOC_CNT, (1024)	;illegal, to cause err on ref

;......................................................................
; end of romdcl.h
