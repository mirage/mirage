;
;  (c) Copyright 1986 HEWLETT-PACKARD COMPANY
;
;  To anyone who acknowledges that this file is provided "AS IS"
;  without any express or implied warranty:
;      permission to use, copy, modify, and distribute this file
;  for any purpose is hereby granted without fee, provided that
;  the above copyright notice and this notice appears in all
;  copies, and that the name of Hewlett-Packard Company not be
;  used in advertising or publicity pertaining to distribution
;  of the software without specific, written prior permission.
;  Hewlett-Packard Company makes no representations about the
;  suitability of this software for any purpose.
;

; Standard Hardware Register Definitions for Use with Assembler
; version A.08.06
;	- fr16-31 added at Utah
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Hardware General Registers
r0: .equ	0

r1: .equ	1

r2: .equ	2

r3: .equ	3

r4: .equ	4

r5: .equ	5

r6: .equ	6

r7: .equ	7

r8: .equ	8

r9: .equ	9

r10: .equ	10

r11: .equ	11

r12: .equ	12

r13: .equ	13

r14: .equ	14

r15: .equ	15

r16: .equ	16

r17: .equ	17

r18: .equ	18

r19: .equ	19

r20: .equ	20

r21: .equ	21

r22: .equ	22

r23: .equ	23

r24: .equ	24

r25: .equ	25

r26: .equ	26

r27: .equ	27

r28: .equ	28

r29: .equ	29

r30: .equ	30

r31: .equ	31

; Hardware Space Registers
sr0: .equ	0

sr1: .equ	1

sr2: .equ	2

sr3: .equ	3

sr4: .equ	4

sr5: .equ	5

sr6: .equ	6

sr7: .equ	7

; Hardware Floating Point Registers
fr0: .equ	0

fr1: .equ	1

fr2: .equ	2

fr3: .equ	3

fr4: .equ	4

fr5: .equ	5

fr6: .equ	6

fr7: .equ	7

fr8: .equ	8

fr9: .equ	9

fr10: .equ	10

fr11: .equ	11

fr12: .equ	12

fr13: .equ	13

fr14: .equ	14

fr15: .equ	15

fr16: .equ	16

fr17: .equ	17

fr18: .equ	18

fr19: .equ	19

fr20: .equ	20

fr21: .equ	21

fr22: .equ	22

fr23: .equ	23

fr24: .equ	24

fr25: .equ	25

fr26: .equ	26

fr27: .equ	27

fr28: .equ	28

fr29: .equ	29

fr30: .equ	30

fr31: .equ	31

; Hardware Control Registers
cr0: .equ	0

rctr: .equ	0			; Recovery Counter Register


cr8: .equ	8			; Protection ID 1

pidr1: .equ	8


cr9: .equ	9			; Protection ID 2

pidr2: .equ	9


cr10: .equ	10

ccr: .equ	10			; Coprocessor Confiquration Register


cr11: .equ	11

sar: .equ	11			; Shift Amount Register


cr12: .equ	12

pidr3: .equ	12			; Protection ID 3


cr13: .equ	13

pidr4: .equ	13			; Protection ID 4


cr14: .equ	14

iva: .equ	14			; Interrupt Vector Address


cr15: .equ	15

eiem: .equ	15			; External Interrupt Enable Mask


cr16: .equ	16

itmr: .equ	16			; Interval Timer


cr17: .equ	17

pcsq: .equ	17			; Program Counter Space queue


cr18: .equ	18

pcoq: .equ	18			; Program Counter Offset queue


cr19: .equ	19

iir: .equ	19			; Interruption Instruction Register


cr20: .equ	20

isr: .equ	20			; Interruption Space Register


cr21: .equ	21

ior: .equ	21			; Interruption Offset Register


cr22: .equ	22

ipsw: .equ	22			; Interrpution Processor Status Word


cr23: .equ	23

eirr: .equ	23			; External Interrupt Request


cr24: .equ	24

ppda: .equ	24			; Physcial Page Directory Address

tr0: .equ	24			; Temporary register 0


cr25: .equ	25

hta: .equ	25			; Hash Table Address

tr1: .equ	25			; Temporary register 1


cr26: .equ	26

tr2: .equ	26			; Temporary register 2


cr27: .equ	27

tr3: .equ	27			; Temporary register 3


cr28: .equ	28

tr4: .equ	28			; Temporary register 4


cr29: .equ	29

tr5: .equ	29			; Temporary register 5


cr30: .equ	30

tr6: .equ	30			; Temporary register 6


cr31: .equ	31

tr7: .equ	31			; Temporary register 7

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Procedure Call Convention                                                  ~
; Register Definitions for Use with Assembler                                ~
; version A.08.06
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Software Architecture General Registers
rp: .equ    r2	; return pointer

mrp: .equ	r31	; millicode return pointer

ret0: .equ    r28	; return value

ret1: .equ    r29	; return value (high part of double)

sl: .equ    r29	; static link

sp: .equ 	r30	; stack pointer

dp: .equ	r27	; data pointer

arg0: .equ	r26	; argument

arg1: .equ	r25	; argument or high part of double argument

arg2: .equ	r24	; argument

arg3: .equ	r23	; argument or high part of double argument

;_____________________________________________________________________________
; Software Architecture Space Registers
;		sr0	; return link form BLE
sret: .equ	sr1	; return value

sarg: .equ	sr1	; argument

;		sr4	; PC SPACE tracker
;		sr5	; process private data
;_____________________________________________________________________________
; Software Architecture Pseudo Registers
previous_sp: .equ	64	; old stack pointer (locates previous frame)

#if 0
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Standard space and subspace definitions.  version A.08.06
; These are generally suitable for programs on HP_UX and HPE.
; Statements commented out are used when building such things as operating
; system kernels.
;;;;;;;;;;;;;;;;
	.SPACE	$TEXT$,		SPNUM=0,SORT=8
;	.subspa $FIRST$,	QUAD=0,ALIGN=2048,ACCESS=0x2c,SORT=4,FIRST
;	.subspa $REAL$,		QUAD=0,ALIGN=8,ACCESS=0x2c,SORT=4,FIRST,LOCK
	.subspa $MILLICODE$,	QUAD=0,ALIGN=8,ACCESS=0x2c,SORT=8
	.subspa $LIT$,		QUAD=0,ALIGN=8,ACCESS=0x2c,SORT=16
	.subspa $CODE$,		QUAD=0,ALIGN=8,ACCESS=0x2c,SORT=24
;	.subspa $UNWIND$,	QUAD=0,ALIGN=4,ACCESS=0x2c,SORT=64
;	.subspa $RECOVER$,	QUAD=0,ALIGN=4,ACCESS=0x2c,SORT=80
;	.subspa $RESERVED$,	QUAD=0,ALIGN=8,ACCESS=0x73,SORT=82
;	.subspa $GATE$,		QUAD=0,ALIGN=8,ACCESS=0x4c,SORT=84,CODE_ONLY
; Additional code subspaces should have ALIGN=8 for an interspace BV
; and should have SORT=24.
; 
; For an incomplete executable (program bound to shared libraries), 
; sort keys $GLOBAL$ -1 and $GLOBAL$ -2 are reserved for the $DLT$ 
; and $PLT$ subspaces respectively. 
;;;;;;;;;;;;;;;
	.SPACE $PRIVATE$,	SPNUM=1,PRIVATE,SORT=16
	.subspa $GLOBAL$,	QUAD=1,ALIGN=8,ACCESS=0x1f,SORT=40
	.import $global$
	.subspa $SHORTDATA$,	QUAD=1,ALIGN=8,ACCESS=0x1f,SORT=24
	.subspa $DATA$,		QUAD=1,ALIGN=8,ACCESS=0x1f,SORT=16
	.subspa $PFA_COUNTER$,	QUAD=1,ALIGN=4,ACCESS=0x1f,SORT=8
	.subspa $SHORTBSS$,     QUAD=1,ALIGN=8,ACCESS=0x1f,SORT=80,ZERO
	.subspa $BSS$,		QUAD=1,ALIGN=8,ACCESS=0x1f,SORT=82,ZERO
;	.subspa $PCB$,		QUAD=1,ALIGN=8,ACCESS=0x10,SORT=82
;	.subspa	$STACK$,	QUAD=1,ALIGN=8,ACCESS=0x1f,SORT=82
;	.subspa	$HEAP$,		QUAD=1,ALIGN=8,ACCESS=0x1f,SORT=82
;;;;;;;;;;;;;;;;
;	.SPACE	$PFA$,		SPNUM=0,PRIVATE,UNLOADABLE,SORT=64
;	.subspa	$PFA_ADDRESS$,	ALIGN=4,ACCESS=0x2c,UNLOADABLE
;;;;;;;;;;;;;;;;
;	.SPACE	$DEBUG$,	SPNUM=2,PRIVATE,UNLOADABLE,SORT=80
;	.subspa $HEADER$,	ALIGN=4,ACCESS=0,UNLOADABLE,FIRST
;	.subspa	$GNTT$,		ALIGN=4,ACCESS=0,UNLOADABLE
;	.subspa $LNTT$,		ALIGN=4,ACCESS=0,UNLOADABLE
;	.subspa	$SLT$,		ALIGN=4,ACCESS=0,UNLOADABLE
;	.subspa $VT$,		ALIGN=4,ACCESS=0,UNLOADABLE

; To satisfy the copyright terms each .o will have a reference
; the the actual copyright.  This will force the actual copyright
; message to be brought in from libgloss/hp-milli.s
        .space $PRIVATE$
        .subspa $DATA$
#else
	.data
#endif
        .import ___hp_free_copyright,data
L$copyright .word ___hp_free_copyright
