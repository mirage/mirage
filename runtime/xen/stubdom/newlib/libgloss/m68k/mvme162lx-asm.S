/*
 * mvme162lx-asm.S -- assembler routines for the MVME stub.
 *
 * This code was pulled out of mvme162lx-stub.c by Ian Taylor so that I
 * could handle different register and label prefixes in a sensible
 * way.
 */

/****************************************************************************

		THIS SOFTWARE IS NOT COPYRIGHTED  
   
   HP offers the following for use in the public domain.  HP makes no
   warranty with regard to the software or it's performance and the 
   user accepts the software "AS IS" with all faults.

   HP DISCLAIMS ANY WARRANTIES, EXPRESS OR IMPLIED, WITH REGARD
   TO THIS SOFTWARE INCLUDING BUT NOT LIMITED TO THE WARRANTIES
   OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

****************************************************************************/

#include "asm.h"

	.title "mvme162lx-asm.S for m68k"

	.globl SYM (registers)
	.globl SYM (lastFrame)
	.globl SYM (superStack)
	.globl SYM (exceptionHook)
	.globl SYM (_returnFromException)
	.globl SYM (stackPtr)
	.globl SYM (handle_exception)
	.globl SYM (exceptionSize)

.text
.globl SYM (return_to_super)
SYM (return_to_super):
        movel   SYM (registers)+60,sp /* get new stack pointer */
        movel   SYM (lastFrame),a0    /* get last frame info  */
        bra     return_to_any

.globl SYM (return_to_user)
SYM (return_to_user):
        movel   SYM (registers)+60,a0   /* get usp */
        movel   a0,usp           /* set usp */
        movel   SYM (superStack),sp    /* get original stack pointer */

return_to_any:
        movel   SYM (lastFrame),a0     /* get last frame info  */
        movel   a0@+,SYM (lastFrame)   /* link in previous frame     */
        addql   IMM (8),a0            /* skip over pc, vector#*/              
        movew  	a0@+,d0         /* get # of words in cpu frame */       
        addw    d0,a0           /* point to end of data        */       
        addw    d0,a0           /* point to end of data        */       
        movel   a0,a1
/* copy the stack frame */
        subql   IMM (1),d0
copyUserLoop:                                                               
        movew   a1@-,sp@-                                               
        dbf     d0,copyUserLoop                                             

#ifdef __HAVE_68881__
	fmoveml  SYM (registers)+168,fpcr/fpsr/fpi
	fmovemx  SYM (registers)+72,fp0-fp7
	cmpl     IMM (-1),a0@     /* skip frestore flag set ? */
	beq      skip_frestore
	frestore a0@+
skip_frestore:
#endif

	moveml  SYM (registers),d0-d7/a0-a6
	rte  /* pop and go! */


/* this function is called immediately when a level 7 interrupt occurs */
/* if the previous interrupt level was 7 then we're already servicing  */
/* this interrupt and an rte is in order to return to the debugger.    */
/* For the 68000, the offset for sr is 6 due to the jsr return address */
.text
.globl SYM (_debug_level7)
SYM (_debug_level7):
	movew   d0,sp@-
#ifdef mc68020
	movew   sp@(2),d0
#else
	movew   sp@(6),d0
#endif
	andiw   IMM (0x700),d0
	cmpiw   IMM (0x700),d0
	beq     _already7
        movew   sp@+,d0	
        bra     SYM (_catchException)
_already7:
	movew   sp@+,d0
#ifndef mc68020
	lea     sp@(4),sp     /* pull off 68000 return address */
#endif
	rte

#ifdef mc68020
/* This function is called when a 68020 exception occurs.  It saves
 * all the cpu and fpcp regs in the _registers array, creates a frame on a
 * linked list of frames which has the cpu and fpcp stack frames needed
 * to properly restore the context of these processors, and invokes
 * an exception handler (remcom_handler).
 *
 * stack on entry:                       stack on exit:
 *   N bytes of junk                     exception # MSWord
 *   Exception Format Word               exception # MSWord
 *   Program counter LSWord              
 *   Program counter MSWord             
 *   Status Register                    
 *                                       
 *                                       
 */

.text
.globl SYM (_catchException)
SYM (_catchException):

	oriw   IMM (0x0700),sr	/* Disable interrupts */

        moveml  d0-d7/a0-a6,SYM (registers) /* save registers        */
	movel	SYM (lastFrame),a0	/* last frame pointer */

#ifdef __HAVE_68881__
	/* do an fsave, then remember the address to begin a restore from */
	fsave   a0@-
	fmovemx fp0-fp7, SYM (registers)+72
	fmoveml fpcr/fpsr/fpi, SYM (registers)+168
#endif

	lea     SYM (registers),a5    /* get address of registers     */
        movew   sp@,d1          /* get status register          */
        movew   d1,a5@(66)      /* save sr		 	*/	
	movel   sp@(2),a4       /* save pc in a4 for later use  */
        movel   a4,a5@(68)      /* save pc in _regisers[]      	*/

/* figure out how many bytes in the stack frame */
	movew   sp@(6),d0	/* get '020 exception format	*/
        movew   d0,d2   	/* make a copy of format word   */
        andiw   IMM (0xf000),d0 /* mask off format type         */
        rolw    IMM (5),d0           /* rotate into the low byte *2  */
        lea     SYM (exceptionSize),a1
        addw    d0,a1          /* index into the table         */
	movew   a1@,d0         /* get number of words in frame */
        movew   d0,d3          /* save it                      */
        subw    d0,a0	       /* adjust save pointer          */
        subw    d0,a0	       /* adjust save pointer(bytes)   */
	movel   a0,a1          /* copy save pointer            */
	subql   IMM (1),d0     /* predecrement loop counter    */

/* copy the frame */

saveFrameLoop:
	movew  	sp@+,a1@+
	dbf     d0,saveFrameLoop

/* now that the stack has been clenaed,
 * save the a7 in use at time of exception
 */
        movel   sp,SYM (superStack)  /* save supervisor sp           */
        andiw   IMM (0x2000),d1      /* were we in supervisor mode ? */
        beq     userMode       
        movel   a7,a5@(60)      /* save a7                  */
        bra     a7saveDone
userMode:  
	movel   usp,a1    	
        movel   a1,a5@(60)     /* save user stack pointer	*/
a7saveDone:


/* save size of frame */
        movew   d3,a0@-

/* compute exception number */
	andl    IMM (0xfff),d2   	/* mask off vector offset	*/
	lsrw    IMM (2),d2   	/* divide by 4 to get vect num	*/
        movel   d2,a0@-       /* save it                      */

/* save pc causing exception */
        movel   a4,a0@-

/* save old frame link and set the new value*/
	movel	SYM (lastFrame),a1	/* last frame pointer */
	movel   a1,a0@-		/* save pointer to prev frame	*/
        movel   a0,SYM (lastFrame)

        movel   d2,sp@-		/* push exception num           */
#ifdef TMP_HACK
	movel   SYM (exceptionHook),a0   /* get address of handler */
        jbsr    a0@            /* and call it */
#else
        jbsr    SYM (remcomHandler)
#endif
        clrl    sp@             /* replace exception num parm with frame ptr */
        jbsr    SYM (_returnFromException)    /* jbsr, but never returns */

#else /* mc68000 */

/* This function is called when an exception occurs.  It translates the
 * return address found on the stack into an exception vector # which
 * is then handled by either handle_exception or a system handler.
 * _catchException provides a front end for both.  
 *
 * stack on entry:                       stack on exit:
 *   Program counter MSWord              exception # MSWord 
 *   Program counter LSWord              exception # MSWord
 *   Status Register                     
 *   Return Address  MSWord              
 *   Return Address  LSWord             
 */
.text
.globl SYM (_catchException)
SYM (_catchException):

	oriw   IMM (0x0700),sr	/* Disable interrupts */

        moveml d0-d7/a0-a6,SYM (registers)  /* save registers               */
	movel	SYM (lastFrame),a0	/* last frame pointer */

#ifdef __HAVE_68881__
	/* do an fsave, then remember the address to begin a restore from */
	fsave   a0@-
	fmovemx fp0-fp7, SYM (registers)+72
	fmoveml fpcr/fpsr/fpi, SYM (registers)+168
#endif

        lea     SYM (registers),a5    /* get address of registers     */
        movel   sp@+,d2        /* pop return address           */
	addl 	IMM (1530),d2  /* convert return addr to 	*/
	divs 	IMM (6),d2     /*  exception number		*/
	extl    d2   

        moveql  IMM (3),d3     /* assume a three word frame     */

        cmpiw   IMM (3),d2     /* bus error or address error ? */
        bgt     normal         /* if >3 then normal error      */
        movel   sp@+,a0@-      /* copy error info to frame buff*/
        movel   sp@+,a0@-      /* these are never used         */
        moveql  IMM (7),d3     /* this is a 7 word frame       */
     
normal:   
	movew   sp@+,d1        /* pop status register          */
        movel   sp@+,a4        /* pop program counter          */
        movew   d1,a5@(66)     /* save sr		 	*/	
        movel   a4,a5@(68)     /* save pc in _regisers[]      	*/
        movel   a4,a0@-        /* copy pc to frame buffer      */
	movew   d1,a0@-        /* copy sr to frame buffer      */

        movel   sp,SYM (superStack)   /* save supervisor sp          */

        andiw   IMM (0x2000),d1      /* were we in supervisor mode ? */
        beq     userMode       
        movel   a7,a5@(60)      /* save a7                  */
        bra     saveDone             
userMode:
        movel   usp,a1    	 /* save user stack pointer 	*/
        movel   a1,a5@(60)     /* save user stack pointer	*/
saveDone:

        movew   d3,a0@-        /* push frame size in words     */
        movel   d2,a0@-        /* push vector number           */
        movel   a4,a0@-        /* push exception pc            */

/* save old frame link and set the new value */
	movel	SYM (lastFrame),a1	 /* last frame pointer */
	movel   a1,a0@-	 /* save pointer to prev frame	*/
        movel   a0,SYM (lastFrame)

        movel   d2,sp@-	    	/* push exception num           */
	movel   SYM (exceptionHook),a0   /* get address of handler */
        jbsr    a0@             /* and call it */
        clrl    sp@             /* replace exception num parm with frame ptr */
        jbsr     SYM (_returnFromException)   /* jbsr, but never returns */

#endif /* m68000 */

/*
 * remcomHandler is a front end for handle_exception.  It moves the
 * stack pointer into an area reserved for debugger use in case the
 * breakpoint happened in supervisor mode.
 */
.globl SYM (remcomHandler)
SYM (remcomHandler):
	addl    IMM (4),sp	/* pop off return address     */
        movel   sp@+,d0     	/* get the exception number   */
	movel   SYM (stackPtr),sp	/* move to remcom stack area  */
	movel   d0,sp@-	 	/* push exception onto stack  */
	jbsr    SYM (handle_exception)	/* this never returns */
        rts			/* return */
