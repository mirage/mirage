/*
 *  (c) Copyright 1986 HEWLETT-PACKARD COMPANY
 *
 *  To anyone who acknowledges that this file is provided "AS IS"
 *  without any express or implied warranty:
 *      permission to use, copy, modify, and distribute this file
 *  for any purpose is hereby granted without fee, provided that
 *  the above copyright notice and this notice appears in all
 *  copies, and that the name of Hewlett-Packard Company not be
 *  used in advertising or publicity pertaining to distribution
 *  of the software without specific, written prior permission.
 *  Hewlett-Packard Company makes no representations about the
 *  suitability of this software for any purpose.
 */

/* HPUX_ID = "@(#) $Revision: 1.1 $" */
/* strlen(s): Return length of string s */

#define start   arg0
#define end     ret0
#define tmp1    arg1
#define tmp2    arg2

#include "DEFS.h"

ENTRY(strlen)
        movb,=,n        start,end,$null_ptr
        depi            0,31,2,end
        comb,<>         start,end,$not_aligned
        ldws,ma         4(end),tmp1
        comib,tr        0,0,$loop       /* avoid INDIGO two register interlock */
        uxor,nbz        0,tmp1,0
$not_aligned:
        /*
        ;       Tricky code.  The problem is that the value of of the word
        ;       including the start of the string has some garbage bytes that
        ;       may be 0.  We don't want them to stop the string scan.  So
        ;       we make those bytes non-zero (and any old non-zero value
        ;       will do).  Notice that the end pointer has been rounded
        ;       down to a word boundary, and then incremented to the next
        ;       word by the time we get here.  Therefore, (start-end) has
        ;       one of the values (-3, -2, or -1).  Use uaddcm to do the
        ;       subtraction (instead of sub), and the result will be
        ;       (-4, -3, or -2).  Multiply this by 8, and put into the
        ;       shift register (which truncates to the last 5 bits) and
        ;       the value will be (0, 8, or 16).  Use this as a bit position,
        ;       and drop a mask down into tmp1.  All the garbage bytes will
        ;       have at least 1 bit affected by the vdepi, so all the garbage
        ;       in this first word will be non-zero garbage.
        */
        uaddcm          start,end,tmp2  /*  tmp2 <- {  -4,  -3,  -2 } */
        sh3add          tmp2,0,tmp2     /*  tmp2 <- { -32, -24, -16 } */
        mtsar           tmp2            /*  sar  <- {   0,   8,  16 } */
        vdepi           -1,32,tmp1
        uxor,nbz        0,tmp1,0
$loop:
        b,n             $end_loop
        ldws,ma         4(end),tmp1
        comib,tr        0,0,$loop       /* avoid INDIGO two register interlock */
        uxor,nbz        0,tmp1,0
$end_loop:
        /*       adjust the end pointer to one past the end of the string */
        extru,<>        tmp1,7,8,0
        addib,tr,n      -3,end,$out
        extru,<>        tmp1,15,8,0
        addib,tr,n      -2,end,$out
        extru,<>        tmp1,23,8,0
        addi            -1,end,end
$out:
        bv              0(rp)
        /*
        ;       tricky code.  the end pointer is just beyond the terminating
        ;       null byte, so the length is (end-start-1).  use uaddcm
        ;       to do this in 1 instruction
        */
        uaddcm          end,start,ret0

$null_ptr:
EXIT(strlen)
