; @(#)proreg.h	1.3 90/10/14 20:56:11, AMD
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
;
; proreg.h
;
	; 16 function value return regs
	.reg	v0,  gr96
	.reg	v1,  gr97
	.reg	v2,  gr98
	.reg	v3,  gr99
	.reg	v4,  gr100
	.reg	v5,  gr101
	.reg	v6,  gr102
	.reg	v7,  gr103
	.reg	v8,  gr104
	.reg	v9,  gr105
	.reg	v10, gr106
	.reg	v11, gr107
	.reg	v12, gr108
	.reg	v13, gr109
	.reg	v14, gr110
	.reg	v15, gr111
;
	.reg	rsp, gr1	; Register Stack Pointer
	.reg	ret, gr96	; First word of return value
	.reg	rp0, gr112	; Reserved for Programmer, #0
	.reg	rp1, gr113	; Reserved for Programmer, #1
	.reg	rp2, gr114	; Reserved for Programmer, #2
	.reg	rp3, gr115	; Reserved for Programmer, #3
	.reg	tav, gr121	; Temporary, Argument for Trap Handlers
	.reg	tpc, gr122	; Temporary, Return PC for Trap Handlers
	.reg	lrp, gr123	; Large Return Pointer
	.reg	slp, gr124	; Static Link Pointer
	.reg	msp, gr125	; Memory Stack Pointer
	.reg	rab, gr126	; Register Allocate Bound
	.reg	rfb, gr127	; Register Free Bound
