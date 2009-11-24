; @(#)getenv.s	1.4 90/10/14 21:57:45, AMD
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
; getenv.s
;	char *value = getenv( const char *name );
;
	.file	"getenv.s"

	.include "sys/sysmac.h"

	.text
	.word	0x00030000	; Debugger tag word
	.global	_getenv
	.global	__getenv
_getenv:
__getenv:
	const tav,HIF_getenv @ asneq V_SYSCALL,gr1,gr1		; HIF service trap
	jmpti	tav, lr0	; If tav is true, were finished, return.
	const	tpc, _errno
	consth	tpc, _errno	; Otherwise,
	store	0, 0, tav, tpc	;   store error code in _errno,
	jmpi	lr0		;   then return
	const	v0, 0		;   with a value of 0 (NULL pointer).

	.end
