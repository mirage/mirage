/*
 * Copyright (c) 1990 The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that the above copyright notice and this paragraph are
 * duplicated in all such forms and that any documentation,
 * advertising materials, and other materials related to such
 * distribution and use acknowledge that the software was developed
 * by the University of California, Berkeley.  The name of the
 * University may not be used to endorse or promote products derived
 * from this software without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */

#include "pcc_prefix.s"

#define	BLANK
#define	BANNER(str)	BLANK	.VERSION str
#define	ENTRY(Name)	BLANK	M_ENTRY	(Name,PROF_/**/Name)
#define	ENTRYC(Name)	BLANK	M_ENTRYC(Name,PROF_/**/Name)
#define	EXIT(Name)	BLANK	M_EXIT	(Name,PROF_/**/Name)
#define	EXITC(Name)	BLANK	M_EXITC	(Name,PROF_/**/Name)

#if 0
#define TEXT_SEGMENT \
        .SPACE  $TEXT$          !\
        .SUBSPA $CODE$
#define RO_SEGMENT \
        .SPACE  $TEXT$          !\
        .SUBSPA $lit$
#define DATA_SEGMENT \
        .SPACE  $PRIVATE$          !\
        .SUBSPA $data$
#define BSS_SEGMENT \
        .SPACE  $PRIVATE$          !\
        .SUBSPA $bss$
#else
#define TEXT_SEGMENT .text
#define RO_SEGMENT .rodata
#define DATA_SEGMENT .data
#define BSS_SEGMENT .bss
#endif




#ifdef PROF

;
; All four argument registers are saved into caller save registers
; and restored after the call to _mcount.  This is possible because
; the mcount routine does not modify them, so we can.  Mcount takes
; 3 arguments; the first argument is the incoming 'rp', the second
; is the starting address of the profiled routine, and the third is
; the address of the PROF label (which is where mcount stores the
; profile data).
;
#define M_ENTRY(name,prof)	\
	TEXT_SEGMENT		!\
        .label name		!\
        .PROC			!\
	.CALLINFO CALLER,SAVE_RP !\
	.ENTRY			!\
	stw	rp,-20(sp)	!\
	ldo	48(sp),sp	!\
	or	arg0,r0,r19	!\
	or	arg1,r0,r20	!\
	or	arg2,r0,r21	!\
	or	arg3,r0,r22	!\
	or	rp,r0,arg0	!\
	ldil	L%name,r1	!\
	ldo	R%name(r1),arg1	!\
	addil	L%prof-$global$,dp	!\
	bl	_mcount,rp	!\
	ldo	R%prof-$global$(r1),arg2	!\
	ldw	-68(sp),rp	!\
	ldo	-48(sp),sp	!\
	or	r19,r0,arg0	!\
	or	r20,r0,arg1	!\
	or	r21,r0,arg2	!\
	or	r22,r0,arg3	!\


#define M_ENTRYC(name,prof)	\
	TEXT_SEGMENT		!\
        .label name		!\
        .PROC			!\
	.CALLINFO CALLER,SAVE_RP !\
	.ENTRY			!\
	stw	rp,-20(sp)	!\
	ldo	128(sp),sp	!\
	or	arg0,r0,r19	!\
	or	arg1,r0,r20	!\
	or	arg2,r0,r21	!\
	or	arg3,r0,r22	!\
	or	rp,r0,arg0	!\
	ldil	L%name,r1	!\
	ldo	R%name(r1),arg1	!\
	addil	L%prof-$global$,dp	!\
	bl	_mcount,rp	!\
	ldo	R%prof-$global$(r1),arg2	!\
	ldw	-148(sp),rp	!\
	or	r19,r0,arg0	!\
	or	r20,r0,arg1	!\
	or	r21,r0,arg2	!\
	or	r22,r0,arg3	!\

;
; The HPUX profiler uses a word for each entrypoint to store the profiling
; information.  The setup code passes the address to the _mcount routine.
; The EXIT macro defines a label (PROF_foo), and a word of storage.
;
#define M_EXIT(name,prof)	\
        bv,n	r0(rp)		!\
	.EXIT			!\
        .PROCEND		!\
        .EXPORT	name,ENTRY	!\
	DATA_SEGMENT		!\
	.label prof		!\
	.WORD	0		!\
	.IMPORT	$global$,DATA	!\
	.IMPORT	_mcount,CODE

#define M_EXITC(name,prof)	\
        bv	r0(rp)		!\
        ldo	-128(sp),sp	!\
	.EXIT			!\
        .PROCEND		!\
        .EXPORT	name,ENTRY	!\
	DATA_SEGMENT		!\
	.label prof		!\
	.WORD	0		!\
	.IMPORT	$global$,DATA	!\
	.IMPORT	_mcount,CODE

#else	/* NOT profiling */

#define M_ENTRY(name,prof)	\
	TEXT_SEGMENT		!\
        .label name	!\
        .PROC		!\
        .CALLINFO	!\
	.ENTRY

#define M_ENTRYC(name,prof)	\
	TEXT_SEGMENT		!\
        .label name	!\
        .PROC		!\
        .CALLINFO CALLER,SAVE_RP	!\
	.ENTRY		!\
        stw     rp,-20(sp)	!\
        ldo     128(sp),sp

#define M_EXIT(name,prof)	\
        bv,n	r0(rp)	!\
	.EXIT		!\
        .PROCEND	!\
        .EXPORT	name,ENTRY

#define M_EXITC(name,prof)	\
        ldw	-148(sp),rp	!\
        bv	r0(rp)	!\
        ldo	-128(sp),sp	!\
	.EXIT		!\
        .PROCEND	!\
        .EXPORT	name,ENTRY

#define	ENTRY(Name)	BLANK	M_ENTRY	(Name,PROF_/**/Name)
#define	ENTRYC(Name)	BLANK	M_ENTRYC(Name,PROF_/**/Name)
#define	EXIT(Name)	BLANK	M_EXIT	(Name,PROF_/**/Name)
#define	EXITC(Name)	BLANK	M_EXITC	(Name,PROF_/**/Name)


#endif

