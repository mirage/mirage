/* crt0.S -- startup file for hppa.
 *
 * Copyright (c) 1995 Cygnus Support
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
	.VERSION "1.0"
	.COPYRIGHT "crt0.o for the PA"

	.DATA

/* 
 * Set up the standard spaces (sections) These definitions come
 * from /lib/pcc_prefix.s.
 */
	.TEXT
	
/*
 * stuff we need that's defined elsewhere.
 */
	.IMPORT main, CODE
	.IMPORT exit, CODE
	.IMPORT _bss_start, DATA
	.IMPORT _end, DATA
	.IMPORT environ, DATA

/*
 * start -- set things up so the application will run.
 *
 */
        .PROC
        .CALLINFO SAVE_SP, FRAME=48
        .EXPORT $START$,ENTRY
$START$

	/* FIXME: this writes to page zero */
	;; setup the %30 (stack pointer) with some memory
	ldil 	L%_stack,%r30
        ldo 	R%_stack(%r30),%r30

	;; we need to set %r27 (global data pointer) here too 
	ldil 	L%$global$,%r27
        ldo 	R%$global$(%r27),%r27		; same problem as above

/*
 * zerobss -- zero out the bss section
 */
	; load the start of bss
	ldil 	L%_bss_start,%r4
        ldo 	R%_bss_start(%r4),%r4

	;  load the end of bss
	ldil 	L%_end,%r5
        ldo 	R%_end(%r5),%r5


L$bssloop
	addi	-1,%r5,%r5			; decrement _bss_end
	stb	%r0,0(0,%r5)			; we do this by bytes for now even
						; though it's slower, it's safer
	combf,=	%r4,%r5, L$bssloop	
	nop
	
	ldi	1,%ret0

/*
 * Call the main routine from the application to get it going.
 * main (argc, argv, environ)
 * We pass argv as a pointer to NULL.
 */

	ldil	L%main,%r22
	ble 	R%main(%sr4,%r22)
	copy	%r31,%r2
/*
 * Call exit() from the C library with the return value from main()
 */
	copy	%r28,%r26
	ldil	L%exit,%r22
	ble	R%exit(%sr4,%r22)
	copy	%r31,%r2

        .PROCEND
/*
 * _exit -- Exit from the application. Normally we cause a user trap
 * 	    to return to the ROM monitor for another run.
 */
	.EXPORT _exit, ENTRY
_exit
	.PROC
	.CALLINFO
	.ENTRY
	
	;; This just causes a breakpoint exception
	break	0x0,0x0
        bv,n    (%rp)
	nop
	.EXIT
	.PROCEND

/*
 * _sr4export -- support for called functions. (mostly for GDB)
 */
	.EXPORT _sr4export, ENTRY
_sr4export:
	.PROC
	.CALLINFO
	.ENTRY

	ble	0(%sr4,%r22)
	copy	%r31,%rp
	ldw	-24(%sr0,%sp),%rp
	ldsid	(%sr0,%rp),%r1
	mtsp	%r1,%sr0
	be,n	0(%sr0,%rp)
	nop
	.EXIT
	.PROCEND


