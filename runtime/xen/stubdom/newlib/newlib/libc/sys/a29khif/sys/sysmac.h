; @(#)sysmac.h	1.7 90/10/14 20:56:17, Copyright 1988, 1989, 1990 AMD
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Copyright 1988, 1989, 1990 Advanced Micro Devices, Inc.
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
; sysmac.h
;
	.include	"sys/proreg.h"

;	Supported system call function numbers - BSD emulation

	.equ	BSD_exit,	  1
	.equ	BSD_open,	  5
	.equ	BSD_close,	  6
	.equ	BSD_remove,	 10
	.equ	BSD_lseek,	 19
	.equ	BSD_sbrk,	 69
	.equ	BSD_readv,	120
	.equ	BSD_writev,	121
	.equ	BSD_rename,	128
;			Functions above 0x100 are handled by Am29000 code
	.equ	BSD_alloc,	0x101
	.equ	BSD_free,	0x102
	.equ	BSD_getpagesize,	0x103

	.equ	BSD_clock,	0x111

;	Supported system call function numbers - HIF version 2.0

	.equ	HIF_exit,	0x01

	.equ	HIF_open,	0x11
	.equ	HIF_close,	0x12
	.equ	HIF_read,	0x13
	.equ	HIF_write,	0x14
	.equ	HIF_lseek,	0x15
	.equ	HIF_remove,	0x16
	.equ	HIF_rename,	0x17
	.equ	HIF_ioctl,	0x18
	.equ	HIF_iowait,	0x19
	.equ	HIF_iostat,	0x1a

	.equ	HIF_tmpnam,	0x21

	.equ	HIF_time,	0x31

	.equ	HIF_getenv,	0x41
	.equ	HIF_gettz,	0x43

	.equ	HIF_sysalloc,	0x101
	.equ	HIF_alloc,	HIF_sysalloc	;Synonym.
	.equ	HIF_sysfree,	0x102
	.equ	HIF_free,	HIF_sysfree	;Synonym.
	.equ	HIF_getpsize,	0x103
	.equ	HIF_getpagesize,HIF_getpsize	;Synonym.
	.equ	HIF_getargs,	0x104

	.equ	HIF_clock,	0x111
	.equ	HIF_cycles,	0x112

	.equ	HIF_setvec,	0x121
	.equ	HIF_settrap,	0x122
	.equ	HIF_setim,	0x123

	.equ	HIF_query,	0x131

	.equ	HIF_signal,	0x141
	.equ	HIF_sigdfl,	0x142
	.equ	HIF_sigret,	0x143
	.equ	HIF_sigrep,	0x144
	.equ	HIF_sigskp,	0x145
	.equ	HIF_sendsig,	0x146

;Maintain compatibility with HIF 1.0 code.

	.equ	EPI_exit,	HIF_exit

	.equ	EPI_open,	HIF_open
	.equ	EPI_close,	HIF_close
	.equ	EPI_read,	HIF_read
	.equ	EPI_write,	HIF_write
	.equ	EPI_lseek,	HIF_lseek
	.equ	EPI_remove,	HIF_remove
	.equ	EPI_rename,	HIF_rename

	.equ	EPI_tmpnam,	HIF_tmpnam

	.equ	EPI_time,	HIF_time

	.equ	EPI_getenv,	HIF_getenv
	.equ	EPI_gettz,	HIF_gettz
	.equ	EPI_alloc,	HIF_sysalloc
	.equ	EPI_free,	HIF_sysfree
	.equ	EPI_getpagesize,	HIF_getpsize
	.equ	EPI_getargs,	HIF_getargs

	.equ	EPI_clock,	HIF_clock
	.equ	EPI_cycles,	HIF_cycles

	.equ	EPI_setvec,	HIF_setvec

	.equ	V_SYSCALL, 69

;		System call macros
/* Now that source files have been sed'd to avoid these macros, they
   are just commented out.  -- gnu@cygnus.com  Oct 90 

	.ifdef	_BSD_OS
	  .equ  V_SYSCALL, 66
	.else
	  .equ	V_SYSCALL, 69
	.endif

	.macro  syscall, name
	  .ifdef	_BSD_OS
	    const	  tav, SYS_@name
	  .else
	    const	  tav, HIF_@name
	  .endif
	  asneq		V_SYSCALL, gr1, gr1
	.endm

; error return
;   set errno to the error value in tav.
;   return -1
;
	.macro  returnerr
;;	  .extern	_errno		; rather have undef'd sym than multiple def's
	  const		tpc, _errno
	  consth	tpc, _errno
	  store		0, 0, tav, tpc
	  jmpi		lr0
	  constn	v0, -1
	.endm

; package the most common case in one macro
;
	.macro  system, name
	  syscall	name
	  jmpti		tav, lr0
	    returnerr
	.endm
 */
