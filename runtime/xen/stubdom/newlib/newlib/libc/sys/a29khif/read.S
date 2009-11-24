; @(#)_read.s	1.4 90/10/14 21:57:32, AMD
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
; _read.s
;	int nread = _read( int fd, char *buf, int count );
;
	.file	"_read.s"
	.include "sys/sysmac.h"
	.text
	.word	0x00050000		; Debugger tag word
	.global	__read
;; syscalls used now -- 	.global	_read

__read:
;; syscalls used now -- _read:
	.ifdef	_BSD_OS
;		BSD version - uses readv const tav,HIF_call @ asneq V_SYSCALL,gr1,gr1 @ jmpti tav,lr0 @ const tpc,_errno @ consth tpc,_errno @ store 0,0,tav,tpc @ jmpi lr0 @ constn v0,-1
	sub	msp, msp, 8
	store	0, 0, lr3, msp
	add	tav, msp, 4
	add	lr3, msp, 0
	store	0, 0, lr4, tav
	const	lr4, 1
	const tav,HIF_readv @ asneq V_SYSCALL,gr1,gr1
	jmpti	tav, lr0
	add	msp, msp, 8
	const tpc,_errno @ consth tpc,_errno @ store 0,0,tav,tpc @ jmpi lr0 @ constn v0,-1
	.else
	const tav,HIF_read @ asneq V_SYSCALL,gr1,gr1 @ jmpti tav,lr0 @ const tpc,_errno @ consth tpc,_errno @ store 0,0,tav,tpc @ jmpi lr0 @ constn v0,-1
	.endif
	.end
