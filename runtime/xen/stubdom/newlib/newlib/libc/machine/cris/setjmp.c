/* A setjmp.c for CRIS
   Copyright (C) 1993-2005 Axis Communications.
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:

   1. Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

   2. Neither the name of Axis Communications nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY AXIS COMMUNICATIONS AND ITS CONTRIBUTORS
   ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL AXIS
   COMMUNICATIONS OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
   INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
   (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
   SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
   STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
   IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
   POSSIBILITY OF SUCH DAMAGE.  */

/* For benefit of CRIS v0..v3, we save and restore CCR to be able to
   correctly handle DI/EI; otherwise there would be no reason to save it.
   Note also that the "move x,ccr" does NOT affect
   the DMA enable bits (E and D) of v0..v3.

   We do not save mof; it is call-clobbered.  It also does not exist in
   v0..v8; it should be safe to read or write to it there, but better not.

   jmp_buf[0] - PC
   jmp_buf[1] - SP (R14)
   jmp_buf[2] - R13
   jmp_buf[3] - R12
   jmp_buf[4] - R11
   jmp_buf[5] - R10
   jmp_buf[6] - R9
   jmp_buf[7] - R8
   jmp_buf[8] - R7
   jmp_buf[9] - R6
   jmp_buf[10] - R5
   jmp_buf[11] - R4
   jmp_buf[12] - R3
   jmp_buf[13] - R2
   jmp_buf[14] - R1
   jmp_buf[15] - R0
   jmp_buf[16] - SRP
   jmp_buf[17] - CCR
   */

#include <setjmp.h>

int
setjmp (jmp_buf buf)
{
  int ret;
#if defined (__arch_common_v10_v32) || defined (__arch_v32)
  /* No offsets in the compatibility mode.  Also, movem saves in
     different order on v10 than on v32, so we use single move
     instructions instead, this not being a speed-prioritized operation.
     And we don't save CCR or CCS; since long unuseful.  */
  __asm__ __volatile__
    ("move.d %1,$r13							\n\
      move 0f,$mof							\n\
      move $mof,[$r13+]							\n\
      move.d $sp,[$r13+]						\n\
      clear.d [$r13+]							\n\
      move.d $r12,[$r13+]						\n\
      move.d $r11,[$r13+]						\n\
      move.d $r10,[$r13+]						\n\
      moveq 1,$r9							\n\
      move.d $r9,[$r13+]						\n\
      move.d $r8,[$r13+]						\n\
      move.d $r7,[$r13+]						\n\
      move.d $r6,[$r13+]						\n\
      move.d $r5,[$r13+]						\n\
      move.d $r4,[$r13+]						\n\
      move.d $r3,[$r13+]						\n\
      move.d $r2,[$r13+]						\n\
      move.d $r1,[$r13+]						\n\
      move.d $r0,[$r13+]						\n\
      move $srp,[$r13+]							\n\
      clear.d [$r13+]							\n\
      clear.d $r9							\n\
0:									\n\
      move.d $r9,%0"

     /* Output.  */
     : "=&r" (ret)

     /* Input.  */
     : "r" (buf)

     /* Clobber.  */
     : "r9", "r13", "memory");
#else /* not __arch_common_v10_v32 or __arch_v32 */
#ifdef __PIC__
  __asm__ __volatile__
    ("moveq 1,$r9							\n\
      movem $sp,[%1+1*4]						\n\
      move.d $pc,$r9							\n\
      addq 0f-.,$r9							\n\
      move.d $r9,[%1]							\n\
      move $srp,[%1+16*4]						\n\
      move $ccr,[%1+17*4]						\n\
      clear.d $r9							\n\
0:									\n\
      move.d $r9,%0"

     /* Output.  */
     : "=&r" (ret)

     /* Input.  */
     : "r" (buf)

     /* Clobber.  */
     : "r9", "memory");
#else  /* not PIC */
  __asm__ __volatile__
    ("moveq 1,$r9							\n\
      movem $sp,[%1+1*4]						\n\
      move.d 0f,$r9							\n\
      move.d $r9,[%1]							\n\
      move $srp,[%1+16*4]						\n\
      move $ccr,[%1+17*4]						\n\
      clear.d $r9							\n\
0:									\n\
      move.d $r9,%0"

     /* Output.  */
     : "=&r" (ret)

     /* Input.  */
     : "r" (buf)

     /* Clobber.  */
     : "r9");
#endif /* not PIC */
#endif /* not __arch_common_v10_v32 or __arch_v32 */
  return ret;
}

void
longjmp(jmp_buf buf, int val)
{
#if defined (__arch_common_v10_v32) || defined (__arch_v32)
  __asm__ __volatile__
    ("cmpq 0,%1								\n\
      beq 0f								\n\
      move.d %0,$r13	; In delay-slot.				\n\
      addq 6*4,$r13							\n\
      move.d %1,[$r13]							\n\
      subq 6*4,$r13							\n\
0:\n"
#ifdef __arch_common_v10_v32
     /* Cater to branch offset difference between v32 and v10.  We
	assume the branch above is 8-bit.  */
"     setf\n"
#endif
"     move [$r13+],$mof							\n\
      move.d [$r13+],$sp						\n\
      addq 4,$r13							\n\
      move.d [$r13+],$r12						\n\
      move.d [$r13+],$r11						\n\
      move.d [$r13+],$r10						\n\
      move.d [$r13+],$r9						\n\
      move.d [$r13+],$r8						\n\
      move.d [$r13+],$r7						\n\
      move.d [$r13+],$r6						\n\
      move.d [$r13+],$r5						\n\
      move.d [$r13+],$r4						\n\
      move.d [$r13+],$r3						\n\
      move.d [$r13+],$r2						\n\
      move.d [$r13+],$r1						\n\
      move.d [$r13+],$r0						\n\
      move [$r13+],$srp							\n\
      move $mof,$r13							\n\
      jump $r13								\n\
      setf"

     /* No outputs.  */
     :

     /* Inputs.  */
     : "r" (buf), "r" (val)
     : "r13", "memory");

#else /* not __arch_common_v10_v32 or __arch_v32 */
  __asm__ __volatile__
    ("move [%0+17*4],$ccr						\n\
      move [%0+16*4],$srp						\n\
      test.d %1								\n\
      beq 0f								\n\
      nop								\n\
      move.d %1,[%0+6*4]	; Offset for r9.			\n\
0:									\n\
      movem [%0],$pc"

     /* No outputs.  */
     :

     /* Inputs.  */
     : "r" (buf), "r" (val)
     : "memory");
#endif /* not __arch_common_v10_v32 or __arch_v32 */
}
