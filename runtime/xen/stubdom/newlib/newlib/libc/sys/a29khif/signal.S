;@(#)signal.s	2.15 90/10/14 21:57:55, AMD
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
	.file	"signal.s"

; SigEntry is the address of an array of C-level user code signal handlers.
; They must return to the top-level before doing a sigret() return function.
; Nested signals are supported.

	.extern	V_SPILL, V_FILL
	.extern fill		; In crt0.s

	.align	4
	.comm	WindowSize, 4
	.data
SigEntry:
	.word	0		; reserved
	.word	0		; adds. of #2 SIGINT handler
	.word	0		; reserved
	.word	0		; reserved
	.word	0		; reserved
	.word	0		; reserved
	.word	0		; reserved
	.word	0		; adds. of #8 SIGFPE handler

	.text

	.reg	v0,	gr96
	.reg	v1,	gr97
	.reg	v2,	gr98
	.reg	v3,	gr99

	.reg	tav,	gr121
	.reg	tpc,	gr122
	.reg	lrp,	gr123
	.reg	slp,	gr124
	.reg	msp,	gr125
	.reg	rab,	gr126
	.reg	rfb,	gr127

;=================================================================== setjmp()
; int
; setjmp(label_t jmpbuf)
; {
;	*jmpbuf = {gr1, msp, lr0, lr1};
;	return 0;
; }
;
	.global	_setjmp
_setjmp:
	store	0, 0, gr1, lr2
	add	lr2, lr2, 4
	store	0, 0, msp, lr2
	add	lr2, lr2, 4
	store	0, 0, lr0, lr2
	add	lr2, lr2, 4
	store	0, 0, lr1, lr2
	jmpi	lr0
	 const	v0, 0
;
;==================================================================== longjmp()
; int
; longjmp(label_t jmpbuf, int value)
; {
;	/* BUG: check for this
;	  if (msp > jmpbuf->msp || gr1 > jmpbuf->gr1)
;		longjmperror();
;	 */
;
;	gr1 = jmpbuf->gr1;
;	lr2addr = jmpbuf->gr1 + 8;
;	msp = jmpbuf->msp;
;
;	/* saved lr1 is invalid if saved lr2addr > rfb */
;	if (lr2addr > rfb) {
;		/*
;		 * None of the registers are useful.
;		 * Set rfb to lr2addr - 512 & rab to rfb - 512.
;		 * the FILL assert will take care of filling
;		 */
;		lr1 = jmpbuf->lr1;
;		rab = lr2addr - windowsize;
;		rfb = lr2addr;
;	}
;
;	lr0 = jmpbuf->lr0;
;	if (rfb < lr1)
;		raise V_FILL;
;	return value;
; }
;
	.global	_longjmp
_longjmp:
	load	0, 0, tav, lr2		; copy in gr1
	add	v1, lr2, 4		; v1 points to msp
	; make sure we return a non-zero value
	cpeq	v0, lr3, 0
	srl	v0, v0, 31
	or	v0, lr3, v0

	add	gr1, tav, 0		; now update gr1
	add	tav, tav, 8		; calculate lr2addr
	load	0, 0, msp, v1		; update msp from jmpbuf
	cpleu	v3, tav, rfb		; if (lr2addr > rfb)
	jmpt	v3, $1			; {
	 add	v1, v1, 4		; v1 points to lr0
	add	v2, v1, 4		;	v2 points to lr1
	load	0, 0, lr1, v2		;	lr1 = value from jmpbuf
	sub	v3, rfb, rab		;
	sub	rab, tav, v3		;	rab = lr2addr - windowsize
	add	rfb, tav, 0		;	rfb = lr2addr
$1:	; }
	load	0, 0, lr0, v1
	jmpi	lr0
	 asgeu	 V_FILL, rfb, lr1	; may fill from rfb to lr1
;
;================================================================== sigcode
; About to deliver a signal to a user mode signal handler.
;	msp+(15*4) = signal_number
;	msp+(14*4) = gr1
;	msp+(13*4) = rab
;	msp+(12*4) = PC0
;	msp+(11*4) = PC1
;	msp+(10*4) = PC2
;	msp+( 9*4) = CHA
;	msp+( 8*4) = CHD
;	msp+( 7*4) = CHC
;	msp+( 6*4) = ALU
;	msp+( 5*4) = OPS
;	msp+( 4*4) = gr121
;	msp+( 3*4) = gr99
;	msp+( 2*4) = gr98
;	msp+( 1*4) = gr97
;	msp        = gr96
; The state of all the registers (except for msp, chc and rab)
; is the same as when the process was interrupted.
;
; We must make the stack and window consistent before calling the handler
; The orignal rab value is on the stack. The interrupt handler placed
; rfb-Windowsize in rab. This is required to support nested interrupts.
;
; Note that the window becomes incosistent only during certain
; critical sections in spill, fill, longjmp and sigcode.
;	rfb - rab > windowsize => we are in spill
;	rfb - rab < windowsize => we are in fill
;	gr1 + 8   > rfb        => we are in long-longjmp case
; In case of spill, fill and lonjmp; rab is modified first,
; so if we are in one of these critical sections,
; we set rab to rfb - WINDOWSIZE.
;
	.equ	SIGCTX_SIZE,		(16)*4
	.equ	SIGCTX_SIGNUMB,		(15)*4
	.equ	SIGCTX_GR1_OFFSET,	(14)*4
	.equ	SIGCTX_RAB_OFFSET,	(13)*4
	.equ	SIGCTX_PC0_OFFSET,	(12)*4
	.equ	SIGCTX_PC1_OFFSET,	(11)*4
	.equ	SIGCTX_PC2_OFFSET,	(10)*4
	.equ	SIGCTX_CHC_OFFSET,	(7)*4
	.equ	SIGCTX_OPS_OFFSET,	(5)*4
	.equ	SIGCTX_TAV_OFFSET,	(4)*4
	.global	sigcode
sigcode:
; --------------------------------------------------------  R-Stack fixup
	const	v0, WindowSize		; get register cache size
	consth	v0, WindowSize
	load	0, 0, v0, v0
	add	v2, msp, SIGCTX_RAB_OFFSET
	load	0, 0, v2, v2		; get interrupted rab value
	sub	v1, rfb, v2		; determine if  rfb-rab <= WINDOW_SIZE
	cpgeu	v1, v1, v0		;
	jmpt	v1, nfill		; jmp if spill or 'normal' interrupt
	add	v1, gr1, 8
	 cpgt	v1, v1, rfb		; interrupted longjmp can look like fill
	jmpf	v1, nfill		; test for long-longjmp interruption
	 nop				; jmp if gr1+8 <= rfb
; Fixup signal stack to re-start interrupted fill
; backup pc1 -- this is needed for the partial fill case.
; Clear chc so an interrupted load/store does not restart.
; Reset rab to a window distance below rfb, rab shall be
; decremented again on re-starting the interrupted fill.
; The interrupt handler set rab=rfb-WindowSize.
;
	add	v0, msp, SIGCTX_RAB_OFFSET
	store	0, 0, rab, v0		; re-store (rfb-WindowSize) for rab
	const	v2, fill
	consth	v2, fill
	add	v0, msp, SIGCTX_PC1_OFFSET
	store	0, 0, v2, v0
	sub	v2, v2, 4		; determine pc0
	add	v0, msp, SIGCTX_PC0_OFFSET
	store	0, 0, v2, v0
	const	v2, 0			; clear chc
	add	v0, msp, SIGCTX_CHC_OFFSET
	store	0, 0, v2, v0

nfill:
	cpgt	v0, gr1, rfb		; if gr1 > rfb then gr1 = rfb
	jmpt	v0, lower
	 cplt	v0, gr1, rab		; if gr1 < rab then gr1 = rab
	jmpt	v0, raise
	 nop
; -------------------------------------------------------- save_regs
sig1:	sub	msp, msp, (4+2+25)*4	; reserve space for regs
	mfsr	gr96, ipc
	mfsr	gr97, ipa
	mfsr	gr98, ipb
	mfsr	gr99, q
	mtsrim	cr, 4-1
	storem  0, 0, gr96, msp
;					 "push" registers stack support
	add	gr96, lr1, 0
	add	gr97, rfb, 0
	mtsrim	cr, 2-1
	add	gr99, msp, 2*4
	storem  0, 0, gr96, gr99
;					  "push" remaining global registers
	mtsrim	cr, 25-1		; gr100-gr124
	add	gr96, msp, (4+2)*4
	storem  0, 0, gr100, gr96
;
; -------------------------------------------------------- Dummy Call
	.equ	RALLOC, 4*4		; make space for function calls
	add	v0, rfb, 0		; store original rfb
	sub	gr1, gr1, RALLOC
	asgeu	V_SPILL, gr1, rab
	add	lr1, v0, 0		; set lr1 = original rfb
	add	v1, msp, (4+2+25)*4 + SIGCTX_SIGNUMB
	load	0, 0, lr2, v1		; restore signal number
	sub	v1, lr2, 1		; get handler index
	sll	v1, v1, 2		; point to addresses
;
; -------------------------------------------------------- call C-level
; Handler must not use HIF services other than the _sigret() type.
	const	v0, SigEntry
	consth	v0, SigEntry
	add	v0, v0, v1
	load	0, 0, v0, v0		; determine if handler registered
	cpeq	v1, v0, 0
	jmpt	v1, NoHandler
	 nop
	calli	lr0, v0			; call C-level signal handler
	 nop
;
; -------------------------------------------------------- default return
NoHandler:
	jmp	__sigdfl
	 nop

; -------------------------------------------------------- support bits
lower:	sll	gr1, rfb, 0
	jmp	sig1
	 nop
raise:	sll	gr1, rab, 0
	jmp	sig1
	 nop
/*
; -------------------------------------------------------- repair_regs
	mtsrim	cr, 4-1
	loadm	0, 0, gr96, msp
	mtsr	ipc, gr96
	mtsr	ipa, gr97
	mtsr	ipb, gr98
	mtsr	Q, gr99
;					 "pop" registers stack support
	mtsrim	cr, 2-1
	add	gr99, msp, 2*4
	loadm	0, 0, gr96, gr99
	add	lr1, gr96, 0
	add	rfb, gr97, 0
;					  "pop" remaining global registers
	mtsrim	cr, 25-1		; gr100-gr124
	add	gr96, msp, (4+2)*4
	loadm	0, 0, gr100, gr96
	add	msp, msp, (4+2+25)*4	; repair msp to save_regs entry value
; -------------------------------------------------------- end repair
*/

; ======================================================== _sigret()
	.global	__sigret
__sigret:
;	repair_regs
; -------------------------------------------------------- repair_regs
	mtsrim	cr, 4-1
	loadm	0, 0, gr96, msp
	mtsr	ipc, gr96
	mtsr	ipa, gr97
	mtsr	ipb, gr98
	mtsr	q, gr99
;					 "pop" registers stack support
	mtsrim	cr, 2-1
	add	gr99, msp, 2*4
	loadm	0, 0, gr96, gr99
	add	lr1, gr96, 0
	add	rfb, gr97, 0
;					  "pop" remaining global registers
	mtsrim	cr, 25-1		; gr100-gr124
	add	gr96, msp, (4+2)*4
	loadm	0, 0, gr100, gr96
	add	msp, msp, (4+2+25)*4	; repair msp to save_regs entry value
; -------------------------------------------------------- end repair
	const	tav, 323		; HIF _sigret
	asneq	69, gr1,gr1
	halt				; commit suicide if returns

; ======================================================== _sigdfl()
	.global	__sigdfl
__sigdfl:
;	repair_regs
; -------------------------------------------------------- repair_regs
	mtsrim	cr, 4-1
	loadm	0, 0, gr96, msp
	mtsr	ipc, gr96
	mtsr	ipa, gr97
	mtsr	ipb, gr98
	mtsr	q, gr99
;					 "pop" registers stack support
	mtsrim	cr, 2-1
	add	gr99, msp, 2*4
	loadm	0, 0, gr96, gr99
	add	lr1, gr96, 0
	add	rfb, gr97, 0
;					  "pop" remaining global registers
	mtsrim	cr, 25-1		; gr100-gr124
	add	gr96, msp, (4+2)*4
	loadm	0, 0, gr100, gr96
	add	msp, msp, (4+2+25)*4	; repair msp to save_regs entry value
; -------------------------------------------------------- end repair
	const	tav, 322		; HIF _sigdfl
	asneq	69, gr1,gr1
	halt				; commit suicide if returns

; ======================================================== _sigrep()
__sigrep:
	.global	__sigrep
;	repair_regs
; -------------------------------------------------------- repair_regs
	mtsrim	cr, 4-1
	loadm	0, 0, gr96, msp
	mtsr	ipc, gr96
	mtsr	ipa, gr97
	mtsr	ipb, gr98
	mtsr	q, gr99
;					 "pop" registers stack support
	mtsrim	cr, 2-1
	add	gr99, msp, 2*4
	loadm	0, 0, gr96, gr99
	add	lr1, gr96, 0
	add	rfb, gr97, 0
;					  "pop" remaining global registers
	mtsrim	cr, 25-1		; gr100-gr124
	add	gr96, msp, (4+2)*4
	loadm	0, 0, gr100, gr96
	add	msp, msp, (4+2+25)*4	; repair msp to save_regs entry value
; -------------------------------------------------------- end repair
	const	tav, 324		; HIF _sigrep
	asneq	69, gr1,gr1
	halt				; commit suicide if returns

; ======================================================== _sigskp()
	.global	__sigskp
__sigskp:
;	repair_regs
; -------------------------------------------------------- repair_regs
	mtsrim	cr, 4-1
	loadm	0, 0, gr96, msp
	mtsr	ipc, gr96
	mtsr	ipa, gr97
	mtsr	ipb, gr98
	mtsr	q, gr99
;					 "pop" registers stack support
	mtsrim	cr, 2-1
	add	gr99, msp, 2*4
	loadm	0, 0, gr96, gr99
	add	lr1, gr96, 0
	add	rfb, gr97, 0
;					  "pop" remaining global registers
	mtsrim	cr, 25-1		; gr100-gr124
	add	gr96, msp, (4+2)*4
	loadm	0, 0, gr100, gr96
	add	msp, msp, (4+2+25)*4	; repair msp to save_regs entry value
; -------------------------------------------------------- end repair
	const	tav, 325		; HIF _sigskp
	asneq	69, gr1,gr1
	halt				; commit suicide if returns

; ======================================================== _sendsig()
; lr2 = signal number
	.global _raise
	.global	__sendsig
_raise:
__sendsig:
	const	tav, 326		; HIF sendsig
	asneq	69, gr1,gr1
	jmpi	lr0
	 nop

;
; ======================================================== signal()
;	lr2 = signal number
;	lr3 = handler address
	.global	_signal
_signal:
; the memory variable WindowSize must be initalised at the
; start when rfb and rab are a window size apart.
	const	v0, WindowSize		; get register cache size
	consth	v0, WindowSize
	load	0, 0, v1, v0
	cpeq	v1, v1, 0
	jmpf	v1, WindowSizeOK
	 sub	v1, rfb, rab		; rfb-rab = WINDOW_SIZE
	store	0, 0, v1, v0
WindowSizeOK:
	const	v1, SigEntry
	consth	v1, SigEntry
	sub	v3, lr2, 1		; get handler index
	sll	v3, v3, 2		; pointer to addresses
	add	v1, v1, v3
	store	0,0, lr3, v1		; save new handler

	const	lr2, sigcode
	consth	lr2, sigcode
	;Fall through to __signal
; ======================================================== _signal()
	.global	__signal
__signal:
	const	tav, 321		; HIF signal
	asneq	69, gr1,gr1
	jmpi	lr0
	 nop
