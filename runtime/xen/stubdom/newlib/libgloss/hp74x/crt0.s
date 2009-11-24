/*
 * crt0.S -- startup file for hppa.
 * 		rob@cygnus.com (Rob Savoye)
 */
	.VERSION "0.2"
	.COPYRIGHT "crt0.S for hppa"

;sp      .equ    %r30     		; stack pointer
;dp      .equ    %r27     		; global data pointer
;arg0    .equ    %r26     		; argument
;arg1    .equ    %r25     		; argument or high part of double argument
;arg2    .equ    %r24     		; argument
;arg3    .equ    %r23     		; argument or high part of double argument

#define         IMM(a,b)        ldil L%a,b  ! ldo  R%a(b),b
#define         imm(i,t)        ldil LS%i,t ! addi RS%i,t,t

	.DATA

/****
 * FIXME: these are just a gross hack so this will assemble
 ****/
_bss_start	.WORD
_bss_end	.WORD
_foobar	
		.STRINGZ "Foo Bar...\r\n"

;;_SYSTEM_ID	.WORD
;;		.EXPORT _SYSTEM_ID	; FIXME this is only so it'll
					; link
	
/* 
 * Set up the standard spaces (sections) These definitions come
 * from /lib/pcc_prefix.s.
 */
	.space  $TEXT$,0
	
        .SUBSPA $BOOT$,QUAD=0,ALIGN=8,ACCESS=0x2c,SORT=4
        .IMPORT _start

/*
 * stuff we need that's defined elsewhere.
 */
	.IMPORT main, CODE
	.IMPORT _bss_start, DATA
	.IMPORT _bss_end, DATA
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
	ldil 	L%_stack+48,%r30
        ldo 	R%_stack+48(%r30),%r30		; should be %r30 (sp) but then
						; we'd kill our test program :-)
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
	ldil 	L%_bss_end,%r5
        ldo 	R%_bss_end(%r5),%r5


bssloop
	addi	-1,%r5,%r5			; decrement _bss_end
	stb	%r0,0(0,%r5)			; we do this by bytes for now even
						; though it's slower, it's safer
	combf,=	%r4,%r5, bssloop	
	nop
	
	ldi	1,%ret0

/*
 * Call the main routine from the application to get it going.
 * main (argc, argv, environ)
 * We pass argv as a pointer to NULL.
 */

	bl	main,%r2
	nop

        .PROCEND
/*
 * _exit -- Exit from the application. Normally we cause a user trap
 * 	    to return to the ROM monitor for another run, but with
 *	    this monitor we can't. Still, "C" wants this symbol, it
 *	    should be here. Jumping to 0xF0000004 jumps back into the
 *	    firmware, while writing a 5 to 0xFFFE0030 causes a reset.
 */
	.EXPORT _exit, ENTRY
_exit
	.PROC
	.CALLINFO
	.ENTRY
;;	ldil	L%0xf0000004,%r1
;;	bl	%r1, %r2
	
	ldil 	L'4026531844,%r19
        ldo 	R'4026531844(%r19),%r19
	blr	%r19, %r2
	nop
	
	;; This just causes a breakpoint exception
;;	break	0x0e,0xa5a
;;      bv,n    (%rp)
	nop
	.EXIT
	.PROCEND

        .subspa $UNWIND_START$,QUAD=0,ALIGN=8,ACCESS=0x2c,SORT=56
        .export $UNWIND_START
$UNWIND_START
        .subspa $UNWIND$,QUAD=0,ALIGN=8,ACCESS=0x2c,SORT=64
        .subspa $UNWIND_END$,QUAD=0,ALIGN=8,ACCESS=0x2c,SORT=72
        .export $UNWIND_END
$UNWIND_END
        .subspa $RECOVER_START$,QUAD=0,ALIGN=4,ACCESS=0x2c,SORT=73
        .export $RECOVER_START
$RECOVER_START
        .subspa $RECOVER$,QUAD=0,ALIGN=4,ACCESS=0x2c,SORT=80
        .subspa $RECOVER_END$,QUAD=0,ALIGN=4,ACCESS=0x2c,SORT=88
        .export $RECOVER_END
$RECOVER_END

; The following declarations are, by default in the data space ($PRIVATE$)

;;        .space  $PRIVATE$,1

/*
 * Here we set up the standard date sub spaces.
 * _dp is for the WinBond board.
 *
 * Set up some room for a stack. We just grab a chunk of memory.
 * We also setup some space for the global variable space, which
 * must be done using the reserved name "$global$" so "C" code
 * can find it. The stack grows towards the higher addresses.
 */

        .subspa $DATA$,QUAD=1,ALIGN=8,ACCESS=0x1f,SORT=16
        .subspa $SHORTDATA$,QUAD=1,ALIGN=8,ACCESS=0x1f,SORT=24
        .subspa $GLOBAL$,QUAD=1,ALIGN=8,ACCESS=0x1f,SORT=40
        .export $global$
        .export _dp
$global$
_dp
        .subspa $SHORTBSS$,QUAD=1,ALIGN=8,ACCESS=0x1f,SORT=80,ZERO
        .subspa $BSS$,QUAD=1,ALIGN=8,ACCESS=0x1f,SORT=82,ZERO

       .subspa $STACK$,QUAD=1,ALIGN=8,ACCESS=0x1f,SORT=88,ZERO
        .export _stack
_stack
        .BLOCK          0x2000

/*
 * The heap follows the stack. To use dynamic memory routines in an
 * application, some space MUST be assigned to the stack.
 */

        .subspa $HEAP$,QUAD=1,ALIGN=8,ACCESS=0x1f,SORT=96,ZERO
        .export _heap
_heap
        .end
