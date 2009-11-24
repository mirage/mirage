/*
 * Copyright (c) 1992, 1993
 *      The Regents of the University of California.  All rights reserved.
 *
 *  Modified for incorporation into newlib by Joel Sherrill
 *  (joel@OARcorp.com), On-Line Applications Research, 1995.
 *  Did the following:
 *     + merged in DEFS.h
 *     + removed error check since it prevented using this setjmp
 *       to "context switch" 
 *     + added the support for the "user label" and "register" prefix
 *
 * This software was developed by the Computer Systems Engineering group
 * at Lawrence Berkeley Laboratory under DARPA contract BG 91-66 and
 * contributed to Berkeley.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *      This product includes software developed by the University of
 *      California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * from: $Header: /cvs/cvsfiles/devo/newlib/libc/machine/sparc/setjmp.S,v 1.1 1997/06/25 07:19:16 marka Exp $
 */

#if defined(LIBC_SCCS) && !defined(lint)
        .asciz "@(#)_setjmp.s   8.1 (Berkeley) 6/4/93"
#endif /* LIBC_SCCS and not lint */

/*
 *  Recent versions of GNU cpp define variables which indicate the
 *  need for underscores and percents.  If not using GNU cpp or
 *  the version does not support this, then you will obviously
 *  have to define these as appropriate.
 */
 
#ifndef __USER_LABEL_PREFIX__
#define __USER_LABEL_PREFIX__ _
#endif
 
#ifndef __REGISTER_PREFIX__
#define __REGISTER_PREFIX__
#endif

/* ANSI concatenation macros.  */
 
#define CONCAT1(a, b) CONCAT2(a, b)
#define CONCAT2(a, b) a ## b
 
/* Use the right prefix for global labels.  */
 
#define SYM(x) CONCAT1 (__USER_LABEL_PREFIX__, x)

/*********************************************************************
 *********************************************************************
 *                       Contents of DEFS.h                          *
 *********************************************************************
 *********************************************************************/

#ifdef PROF
#define ENTRY(x) \
        .align 4; .globl SYM(x); .proc 1; SYM(x):; .data; .align 4; 1: .long 0; \
        .text; save %sp,-96,%sp; sethi %hi(1b),%o0; call mcount; \
        or %lo(1b),%o0,%o0; restore
#else
#define ENTRY(x) \
        .align 4; .globl SYM(x); .proc 1; SYM(x):
#endif


 
/*********************************************************************
 *********************************************************************
 *                           END of DEFS.h                           *
 *********************************************************************
 *********************************************************************/


/*
 * C library -- _setjmp, _longjmp
 *
 *      _longjmp(a,v)
 * will generate a "return(v?v:1)" from
 * the last call to
 *      _setjmp(a)
 * by unwinding the call stack.
 * The previous signal state is NOT restored.
 */


/* #include "DEFS.h" */

ENTRY(setjmp)
ENTRY(_setjmp)
        st      %sp, [%o0]      /* caller's stack pointer */
        st      %i7, [%o0+4]    /* caller's return pc */
        st      %fp, [%o0+8]    /* store caller's frame pointer */
        st      %o7, [%o0+12]
        retl
        clr    %o0              ! return 0

ENTRY(longjmp)
ENTRY(_longjmp)
        ta      0x03            /* flush registers */
        addcc   %o1, %g0, %g6   ! compute v ? v : 1 in a global register
        be,a    0f
        mov     1, %g6
0:
        ld      [%o0], %sp      /* caller's stack pointer */

        ldd     [%sp], %l0
        ldd     [%sp+8], %l2
        ldd     [%sp+16], %l4
        ldd     [%sp+24], %l6

        ldd     [%sp+32], %i0
        ldd     [%sp+40], %i2
        ldd     [%sp+48], %i4

        ld      [%o0+4], %i7    /* caller's return pc */
        ld      [%o0+8], %fp    /* caller's frame pointer */
        ld      [%o0+12], %o7 

        jmp     %o7 + 8         ! success, return %g6
        mov     %g6, %o0

