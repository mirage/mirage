/* Startup code for M68HC11/M68HC12.
 * Copyright (C) 1999, 2000, 2001, 2002 Stephane Carrez (stcarrez@nerim.fr)	
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */

;-----------------------------------------
; startup code
;-----------------------------------------
	.file	"crt0.s"

;; 
;; 
;; The linker concatenate the .install* sections in the following order:
;; 
;; .install0	Setup the stack pointer
;; .install1	Place holder for applications
;; .install2	Optional installation of data section in memory
;; .install3	Place holder for applications
;; .install4	Invokes the main
;; 
	.sect   .install0,"ax",@progbits
	.globl _start

_start:
;;
;; At this step, the stack is not initialized and interrupts are masked.
;; Applications only have 64 cycles to initialize some registers.
;;
;; To have a generic/configurable startup, initialize the stack to
;; the end of some memory region.  The _stack symbol is defined by
;; the linker.
;;
	lds	#_stack
	
	.sect	.install2,"ax",@progbits
;;
;; Call a specific initialization operation.  The default is empty.
;; It can be overriden by applications.  It is intended to initialize
;; the 68hc11 registers.  Function prototype is:
;; 
;;	int __premain(void);
;; 
	jsr	__premain
	
;;
;; 
;;
	.sect	.install4,"ax",@progbits
	jsr     main
fatal:
	jsr	exit
	bra fatal

;-----------------------------------------
; end startup code
;-----------------------------------------
;; Force loading of data section mapping and bss clear
	.globl	__map_data_section
	.globl	__init_bss_section

