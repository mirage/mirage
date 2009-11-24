; @(#)cpudef.h	2.3 90/10/14 20:55:56, Copyright 1989, 1990 AMD
;-----------------------------------------------------------------------
; Useful equates
;-----------------------------------------------------------------------
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Copyright 1989, 1990 Advanced Micro Devices, Inc.
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

	; Processor status registers OPS (sr1) and CPS (sr2)
	.equ	CA,0x8000	; Coprocessor active
	.equ	IP,0x4000	; Interrupt pending
	.equ	TE,0x2000	; Trace enable
	.equ	TP,0x1000	; Trace pending
	.equ	TU,0x0800	; Trap unaligned access
	.equ	FZ,0x0400	; Freeze
	.equ	LK,0x0200	; Lock
	.equ	RE,0x0100	; ROM enable
	.equ	WM,0x0080	; Wait mode
	.equ	PD,0x0040	; No translation for Data
	.equ	PI,0x0020	; No translation for Instr
	.equ	SM,0x0010	; Supervisor mode
	.equ	IM,0x000C	; Interrupt mask
	.equ	IM1,0x0100	; enable INTR0-1
	.equ	IM2,0x1000	; enable INTR0-2
	.equ	IM3,0x1100	; enable INTR0-3
	.equ	DI,0x0002	; Disable ints
	.equ	DA,0x0001	; Disable ints and traps

	; Configuration register CFG (sr3)
	.equ	PRL,0xFF000000	; Processor release level
	.equ	VF,0x10		; Vector fetch
	.equ	RV,0x08		; ROM Vector area
	.equ	BO,0x04		; Byte order
	.equ	CP,0x02		; Coprocessor present
	.equ	CD,0x01		; BTC disable

	; Channel control register CHC (sr6)
	.equ	LS,0x8000	; Load store
	.equ	ML,0x4000	; Multiple operation
	.equ	ST,0x2000	; Set
	.equ	LA,0x1000	; Lock active
	.equ	TF,0x0400	; Transaction faulted
	.equ	TR,0x03FC	; Target register
	.equ	NN,0x0002	; Not needed
	.equ	CV,0x0001	; Contents valid

	; Timer reload register TMR (sr9)
	.equ	IE,0x01000000	; timer int enable
	.equ	IN,0x02000000	; timer int pending
	.equ	OV,0x04000000	; timer Overflow

	; MMU configuration register MMU (sr13)
	.equ	PS,0x300	; Page size
	.equ	PID,0xFF	; Process identifier

	; ALU status register ALU (sr132)
	.equ	DF,0x800	; Divide flag
	.equ	V,0x400		; Overflow
	.equ	N,0x200		; Negative
	.equ	Z,0x100		; Zero
	.equ	C,0x080		; Carry

	; TLB entry
	.equ	VTAG,0xFFFF8000	; Virtual tag
	.equ	VE,0x4000	; Valid entry
	.equ	SR,0x2000	; Supervisor read
	.equ	SW,0x1000	; Supervisor write
	.equ	SE,0x0800	; Supervisor execute
	.equ	UR,0x0400	; User read
	.equ	UW,0x0200	; User write
	.equ	UE,0x0100	; User execute
	.equ	TID,0x00FF	; Task identifier
	.equ	RPN,0xFFFFFC00	; Real page number
	.equ	PGM,0x00C0	; User programmable
	.equ	U,0x0002	; Usage
	.equ	F,0x0001	; Flag

;-----------------------------------------------------------------------
;Global registers
;-----------------------------------------------------------------------

	.reg	rsp, gr1	; local register stack pointer

	; System-wide statics
	.reg	s0, gr64
	.reg	spillreg, s0	; pointer to user spill handler
	.reg	s1, gr65
	.reg	fillreg, s1	; pointer to user fill handler
	.reg	s2, gr66
	.reg	heapptr, s2	; pointer to heap area
	.reg	s3, gr67
	.reg	s4, gr68
	.reg	s5, gr69
	.reg	s6, gr70
	.reg	s7, gr71
	.reg	s8, gr72
	.reg	s9, gr73
	.reg	s10, gr74
	.reg	s11, gr75
	.reg	s12, gr76
	.reg	s13, gr77
	.reg	s14, gr78
	.reg	s15, gr79

	; Interrupt handler temporaries
	.reg	i0, gr80
	.reg	i1, gr81
	.reg	i2, gr82
	.reg	i3, gr83
	.reg	i4, gr84
	.reg	i5, gr85
	.reg	i6, gr86
	.reg	i7, gr87
	.reg	i8, gr88
	.reg	i9, gr89
	.reg	i10, gr90
	.reg	i11, gr91
	.reg	i12, gr92
	.reg	i13, gr93
	.reg	i14, gr94
	.reg	i15, gr95

	; Subroutine/function temporaries
	;  also used for function return values
	.reg	t0, gr96
	.reg	rtn, t0
	.reg	t1, gr97
	.reg	t2, gr98
	.reg	t3, gr99
	.reg	t4, gr100
	.reg	t5, gr101
	.reg	t6, gr102
	.reg	t7, gr103
	.reg	t8, gr104
	.reg	t9, gr105
	.reg	t10, gr106
	.reg	t11, gr107
	.reg	t12, gr108
	.reg	t13, gr109
	.reg	t14, gr110
	.reg	t15, gr111

	; User process statics
	.reg	u0, gr112
	.reg	u1, gr113
	.reg	u2, gr114
	.reg	u3, gr115

	; More subroutine/function temporaries
	.reg	t16, gr116
	.reg	t17, gr117
	.reg	t18, gr118
	.reg	t19, gr119
	.reg	t20, gr120

	; Older names for the same registers
	.reg	tmp0, gr116
	.reg	tmp1, gr117
	.reg	tmp2, gr118
	.reg	tmp3, gr119
	.reg	tmp4, gr120

	; Trap handler temporaries
	.reg	tav, gr121	; arg/temp
	.reg	tpc, gr122	; rtn/temp

	; Linkage pointers
	.reg	lrp, gr123	; large rtn ptr
	.reg	slp, gr124	; static link ptr
	.reg	msp, gr125	; memory stack ptr
	.reg	rab, gr126	; register allocate bound
	.reg	rfb, gr127	; register free bound

;-----------------------------------------------------------------------
;Local compiler registers
;  (only valid if frame has been established)
;-----------------------------------------------------------------------

	.reg	p15,		lr17	; outgoing arg 16
	.reg	p14,		lr16	; outgoing arg 15
	.reg	p13,		lr15	; outgoing arg 14
	.reg	p12,		lr14	; outgoing arg 13
	.reg	p11,		lr13	; outgoing arg 12
	.reg	p10,		lr12	; outgoing arg 11
	.reg	p9,		lr11	; outgoing arg 10
	.reg	p8,		lr10	; outgoing arg 9
	.reg	p7,		lr9	; outgoing arg 8
	.reg	p6,		lr8	; outgoing arg 7
	.reg	p5,		lr7	; outgoing arg 6
	.reg	p4,		lr6	; outgoing arg 5
	.reg	p3,		lr5	; outgoing arg 4
	.reg	p2,		lr4	; outgoing arg 3
	.reg	p1,		lr3	; outgoing arg 2
	.reg	p0,		lr2	; outgoing arg 1
	.reg	fp,		lr1	; frame pointer
	.reg	raddr,		lr0	; return address

;-----------------------------------------------------------------------
; Vectors
;-----------------------------------------------------------------------

	.equ	V_ILLEG,	0	; Illegal opcode
	.equ	V_ALIGN,	1	; Unaligned access
	.equ	V_RANGE,	2	; Out of range
	.equ	V_COPRE,	3	; Coprocessor not present
	.equ	V_COEXC,	4	; Coprocessor exception
	.equ	V_PROT,		5	; Protection violation
	.equ	V_INSTR,	6	; Instruction access exception
	.equ	V_DATA,		7	; Data access exception
	.equ	V_UITLB,	8	; User-mode instruction TLB miss
	.equ	V_UDTLB,	9	; User-mode data TLB miss
	.equ	V_SITLB,	10	; Supervisor-mode instr TLB miss
	.equ	V_SDTLB,	11	; Supervisor-mode data TLB miss
	.equ	V_ITLB,		12	; Instruction TLB violation
	.equ	V_DTLB,		13	; Data TLB violation
	.equ	V_TIMER,	14	; Timer
	.equ	V_TRACE,	15	; Trace
	.equ	V_INTR0,	16	; Interrupt 0
	.equ	V_INTR1,	17	; Interrupt 1
	.equ	V_INTR2,	18	; Interrupt 2
	.equ	V_INTR3,	19	; Interrupt 3
	.equ	V_TRAP0,	20	; Trap 0
	.equ	V_TRAP1,	21	; Trap 1

;-----------------------------------------------------------------------
;constants for LOAD and STORE operations
;-----------------------------------------------------------------------

; CE operand values
	.equ	CE,		0b1		;coprocessor enable
	.equ	ME,		0b0		; memory enable

; CNTL operand values
	.equ	IO,		0b1000000	;set for I/O
	.equ	PA,		0b0100000	;force physical addr
	.equ	SB,		0b0010000	;set for set BP
	.equ	UA,		0b0001000	;force user mode access
	.equ	ROM,		0b0000100	;ROM access
	.equ	HWORD,		0b0000010	;Half word access
	.equ	BYTE,		0b0000001	;Byte access
	.equ	WORD,		0b0000000	;Word access

;-----------------------------------------------------------------------
; stack alignment value
;-----------------------------------------------------------------------
	.equ	STKALIGN, 8		; double word align

