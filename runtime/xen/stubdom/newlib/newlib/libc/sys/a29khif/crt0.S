; @(#)crt0.s	2.7 90/10/15 13:17:57, AMD
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Copyright 1988, 1989, 1990 Advanced Micro Devices, Inc.
;
; This software is the property of Advanced Micro Devices, Inc	(AMD)  which
; specifically	grants the user the right to modify, use and distribute this
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
; 800-29-29-AMD (800-292-9263) in the USA, or 0800-89-1131  in	the  UK,  or
; 0031-11-1129 in Japan, toll free.  The direct dial number is 512-462-4118.
;
; Advanced Micro Devices, Inc.
; 29K Support Products
; Mail Stop 573
; 5900 E. Ben White Blvd.
; Austin, TX 78741
; 800-292-9263
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.file	"crt0.s"
; crt0.s version 2.1-7
;
; This module gets control from the OS.
; It saves away the Am29027 Mode register settings and
; then sets up the pointers to the resident spill and fill
; trap handlers. It then establishes argv and argc for passing
; to main. It then calls _main. If main returns, it calls _exit.
;
;	void = start( );
;	NOTE - not C callable (no lead underscore)
;
	.include	"sys/sysmac.h"
;
;
	.extern V_SPILL, V_FILL
	.comm	__29027Mode, 8	; A shadow of the mode register
	.comm	__LibInit, 4
	.comm	__environ, 4	; Environment variables, currently none.
	.text
	.extern _main, _exit
	.extern _memset

	.word	0			; Terminating tag word
	.global start
start:
	sub	gr1, gr1, 6 * 4
	asgeu	V_SPILL, gr1, rab	; better not ever happen
	add	lr1, gr1, 6 * 4
;
; Initialize the .bss section to zero by using the memset library function.
; The .bss initialization section below has been commented out as it breaks
; XRAY29K that has been released. The operators sizeof and startof create
; new sections that are not recognized by XRAY29k, but will be implemented
; in the next release (2.0).
;
;	const	lr4, $sizeof(.bss)	; get size of .bss section to zero out
;	consth	lr4, $sizeof(.bss)
;	const	lr2, $startof(.bss)	; Get start address of .bss section
;	consth	lr2, $startof(.bss)
;	const	lr0, _memset		; address of memset function
;	consth	lr0, _memset
;	calli	lr0, lr0		; call memset function
;	const	lr3, 0

; Save the initial value of the Am29027's Mode register
; If your const tav,HIF_does @ asneq V_SYSCALL,gr1,gr1 @ jmpti tav,lr0 @ const tpc,_errno @ consth tpc,_errno @ store 0,0,tav,tpc @ jmpi lr0 @ constn v0,-1 not enter crt0 with value for Am29027's Mode register
; in gr96 and gr97, and also if the coprocessor is active uncomment the
; next 4 lines.
;	const	gr96, 0xfc00820
;	consth	gr96, 0xfc00820
;	const	gr97, 0x1375
;	store	1, 3, gr96, gr97
;
	const	gr98, __29027Mode
	consth	gr98, __29027Mode
	store	0, 0, gr96, gr98
	add	gr98, gr98, 4
	store	0, 0, gr97, gr98
;
; Now call the const tav,HIF_to @ asneq V_SYSCALL,gr1,gr1 @ jmpti tav,lr0 @ const tpc,_errno @ consth tpc,_errno @ store 0,0,tav,tpc @ jmpi lr0 @ constn v0,-1 setup the spill and fill trap handlers
;
	const	lr3, spill
	consth	lr3, spill
	const	lr2, V_SPILL
	const tav,HIF_setvec @ asneq V_SYSCALL,gr1,gr1
	const	lr3, fill
	consth	lr3, fill
	const	lr2, V_FILL
	const tav,HIF_setvec @ asneq V_SYSCALL,gr1,gr1
;
; Set up dividu handler, since native one don't work?!
; Set it up by hand (FIXME) since HIF_settrap doesn't work either!
;
;	const	lr3,Edividu
;	consth	lr3,Edividu
;
;	const	lr2,35
;	const tav,HIF_settrap @ asneq V_SYSCALL,gr1,gr1
;	asge	0x50,gr121,0	; check whether it failed
;	const	lr2,0x8000008c	; abs addr of dividu trap handler on EB
;	consth	lr2,0x8000008c
;	store	0,0,lr3,lr2	; Clobber vector FIXME

;
;	Get the argv base address and calculate argc.
;
	const tav,HIF_getargs @ asneq V_SYSCALL,gr1,gr1
	add	lr3, v0, 0		; argv
	add	lr4, v0, 0
	constn	lr2, -1
argcloop:				; scan for NULL terminator
	load	0, 0, gr97, lr4
	add	lr4, lr4, 4
	cpeq	gr97, gr97, 0
	jmpf	gr97, argcloop
	add	lr2, lr2, 1
;
; Now call LibInit, if there is one. To aid runtime libraries
; that need to do some startup initialization, we have created
; a bss variable called LibInit. If the library doesn't need
; any run-time initialization, the variable is still 0. If the
; library does need run-time initialization, the library will
; contain a definition like
; void (*_LibInit)(void) = LibInitFunction;
; The linker will match up our bss LibInit with this data LibInit
; and the variable will not be 0.
;
	const	lr0, __LibInit
	consth	lr0, __LibInit
	load	0, 0, lr0, lr0
	cpeq	gr96, lr0, 0
	jmpt	gr96, NoLibInit
	nop
	calli	lr0, lr0
	nop
NoLibInit:
;
; call main, passing it 2 arguments. main( argc, argv )
;
	const	lr0, _main
	consth	lr0, _main
	calli	lr0, lr0
	nop
;
; call exit
;
	const	lr0, _exit
	consth	lr0, _exit
	calli	lr0, lr0
	add	lr2, gr96, 0
;
; Should never get here, but just in case
;
loop:
	const tav,HIF_exit @ asneq V_SYSCALL,gr1,gr1
	jmp	loop
	nop
	.sbttl	"Spill and Fill trap handlers"
	.eject
;
;	SPILL, FILL trap handlers
;
; Note that these Spill and Fill trap handlers allow the OS to
; assume that the only registers of use are between gr1 and rfb.
; Therefore, if the OS desires to, it may simply preserve from
; lr0 for (rfb-gr1)/4 registers when doing a context save.
;
;
; Here is the spill handler
;
; spill registers from [*gr1..*rab)
; and move rab downto where gr1 points
;
; rab must change before rfb for signals to work
;
; On entry:	rfb - rab = windowsize, gr1 < rab
; Near the end: rfb - rab > windowsize, gr1 == rab
; On exit:	rfb - rab = windowsize, gr1 == rab
;
	.global spill
spill:
	sub	tav, rab, gr1	; tav = number of bytes to spill
	srl	tav, tav, 2	; change byte count to word count
	sub	tav, tav, 1	; make count zero based
	mtsr	cr, tav		; set Count Remaining register
	sub	tav, rab, gr1
	sub	tav, rfb, tav	; pull down free bound and save it in rab
	add	rab, gr1, 0	; first pull down allocate bound
	storem	0, 0, lr0, tav	; store lr0..lr(tav) into rfb
	jmpi	tpc		; return...
	  add	rfb, tav, 0
;
; Here is the fill handler
;
; fill registers from [*rfb..*lr1)
; and move rfb upto where lr1 points.
;
; rab must change before rfb for signals to work
;
; On entry:	rfb - rab = windowsize, lr1 > rfb
; Near the end: rfb - rab < windowsize, lr1 == rab + windowsize
; On exit:	rfb - rab = windowsize, lr1 == rfb
;
	.global fill
fill:
	const	tav, 0x80 << 2
	or	tav, tav, rfb	; tav = ((rfb>>2) | 0x80)<<2 == [rfb]<<2
	mtsr	ipa, tav	; ipa = [rfb]<<2 == 1st reg to fill
				; gr0 is now the first reg to spill
	sub	tav, lr1, rfb	; tav = number of bytes to spill
	add	rab, rab, tav	; push up allocate bound
	srl	tav, tav, 2	; change byte count to word count
	sub	tav, tav, 1	; make count zero based
	mtsr	cr, tav		; set Count Remaining register
	loadm	0, 0, gr0, rfb	; load registers
	jmpi	tpc		; return...
	  add	rfb, lr1, 0	; ... first pushing up free bound

	.end
