/* Copyright 2003 SuperH Ltd.  */

#include "asm.h"

#ifdef __SH5__
#if __SHMEDIA__

#ifdef __LITTLE_ENDIAN__
#define ZPAD_MASK(src, dst) addi src, -1, dst
#else
#define ZPAD_MASK(src, dst) \
 byterev src, dst; addi dst, -1, dst; byterev dst, dst
#endif


/* We assume that the destination is not in the first 16 bytes of memory.
   A typical linker script will put the text section first, and as
   this code is longer that 16 bytes, you have to get out of your way
    to put data there.  */
ENTRY(strncpy)
 pt L_small, tr2
 ldlo.q r3, 0, r0
 shlli r3, 3, r19
 mcmpeq.b r0, r63, r1
 SHHI r1, r19, r7
 add r2, r4, r20
 addi r20, -8, r5
 /* If the size is greater than 8, we know we can read beyond the first
    (possibly partial) quadword, and write out a full first and last
    (possibly unaligned and/or overlapping) quadword.  */
 bge/u r2, r5, tr2 // L_small
 pt L_found0, tr0
 addi r2, 8, r22
 bnei/u r7, 0, tr0  // L_found0
 ori r3, -8, r38
 pt L_end_early, tr1
 sub r2, r38, r22
 stlo.q r2, 0, r0
 sthi.q r2, 7, r0
 sub r3, r2, r6
 ldx.q r22, r6, r0
 /* Before each iteration, check that we can store in full the next quad we
    are about to fetch.  */
 addi r5, -8, r36
 bgtu/u r22, r36, tr1 // L_end_early
 pt L_scan0, tr1
L_scan0:
 addi r22, 8, r22
 mcmpeq.b r0, r63, r1
 stlo.q r22, -8, r0
 bnei/u r1, 0, tr0   // L_found0
 sthi.q r22, -1, r0
 ldx.q r22, r6, r0
 bgeu/l r36, r22, tr1 // L_scan0
L_end:
 // At end; we might re-read a few bytes when we fetch the last quad.
 // branch mispredict, so load is ready now.
 mcmpeq.b r0, r63, r1
 addi r22, 8, r22
 bnei/u r1, 0, tr0   // L_found0
 add r3, r4, r7
 ldlo.q r7, -8, r1
 ldhi.q r7, -1, r7
 ptabs r18, tr0
 stlo.q r22, -8, r0
 or r1, r7, r1
 mcmpeq.b r1, r63, r7
 sthi.q r22, -1, r0
 ZPAD_MASK (r7, r7)
 and r1, r7, r1 // mask out non-zero bytes after first zero byte
 stlo.q r20, -8, r1
 sthi.q r20, -1, r1
 blink tr0, r63

L_end_early:
 /* Check if we can store the current quad in full.  */
 pt L_end, tr1
 add r3, r4, r7
 bgtu/u r5, r22, tr1 // L_end // Not really unlikely, but gap is short.
 /* If not, that means we can just proceed to process the last quad.
    Two pipeline stalls are unavoidable, as we don't have enough ILP.  */
 ldlo.q r7, -8, r1
 ldhi.q r7, -1, r7
 ptabs r18, tr0
 or r1, r7, r1
 mcmpeq.b r1, r63, r7
 ZPAD_MASK (r7, r7)
 and r1, r7, r1 // mask out non-zero bytes after first zero byte
 stlo.q r20, -8, r1
 sthi.q r20, -1, r1
 blink tr0, r63

L_found0:
 // r0: string to store, not yet zero-padding normalized.
 // r1: result of mcmpeq.b r0, r63, r1.
 // r22: store address plus 8.  I.e. address where zero padding beyond the
 //      string in r0 goes.
 // r20: store end address.
 // r5: store end address minus 8.
 pt L_write0_multiquad, tr0
 ZPAD_MASK (r1, r1)
 and r0, r1, r0 // mask out non-zero bytes after first zero byte
 stlo.q r22, -8, r0
 sthi.q r22, -1, r0
 andi r22, -8, r1 // Check if zeros to write fit in one quad word.
 bgtu/l r5, r1, tr0 // L_write0_multiquad
 ptabs r18, tr1
 sub r20, r22, r1
 shlli r1, 2, r1 // Do shift in two steps so that 64 bit case is
 SHLO r0, r1, r0 // handled correctly.
 SHLO r0, r1, r0
 sthi.q r20, -1, r0
 blink tr1, r63

L_write0_multiquad:
 pt L_write0_loop, tr0
 ptabs r18, tr1
 stlo.q r22, 0, r63
 sthi.q r20, -1, r63
 addi r1, 8, r1
 bgeu/l r5, r1, tr0 // L_write0_loop
 blink tr1, r63

L_write0_loop:
 st.q r1, 0 ,r63
 addi r1, 8, r1
 bgeu/l r5, r1, tr0 // L_write0_loop
 blink tr1, r63

L_small:
 // r0: string to store, not yet zero-padding normalized.
 // r1: result of mcmpeq.b r0, r63, r1.
 // r7: nonzero indicates relevant zero found r0.
 // r2: store address.
 // r3: read address.
 // r4: size, max 8
 // r20: store end address.
 // r5: store end address minus 8.
 pt L_nohi, tr0
 pt L_small_storelong, tr1
 ptabs r18, tr2
 sub r63, r4, r23
 bnei/u r7, 0, tr0  // L_nohi
 ori r3, -8, r7
 bge/l r23, r7, tr0 // L_nohi
 ldhi.q r3, 7, r1
 or r0, r1, r0
 mcmpeq.b r0, r63, r1
L_nohi:
 ZPAD_MASK (r1, r1)
 and r0, r1, r0
 movi 4, r19
 bge/u r4, r19, tr1 // L_small_storelong

 pt L_small_end, tr0
#ifndef __LITTLE_ENDIAN__
 byterev r0, r0
#endif
 beqi/u r4, 0, tr0 // L_small_end
 st.b r2, 0, r0
 beqi/u r4, 1, tr0 // L_small_end
 shlri r0, 8, r0
 st.b r2, 1, r0
 beqi/u r4, 2, tr0 // L_small_end
 shlri r0, 8, r0
 st.b r2, 2, r0
L_small_end:
 blink tr2, r63

L_small_storelong:
 shlli r23, 3, r7
 SHHI r0, r7, r1
#ifdef __LITTLE_ENDIAN__
 shlri r1, 32, r1
#else
 shlri r0, 32, r0
#endif
 stlo.l r2, 0, r0
 sthi.l r2, 3, r0
 stlo.l r20, -4, r1
 sthi.l r20, -1, r1
 blink tr2, r63

#else /* SHcompact */

/* This code is optimized for size.  Instruction selection is SH5 specific.
   SH4 should use a different version.  */
ENTRY(strncpy)
 mov #0, r6
 cmp/eq r4, r6
 bt return
 mov r2, r5
 add #-1, r5
 add r5, r4
loop:
 bt/s found0
 add #1, r5
 mov.b @r3+, r1
found0:
 cmp/eq r5,r4
 mov.b r1, @r5
 bf/s loop
 cmp/eq r1, r6
return:
 rts
 nop
 
#endif /* SHcompact */
#endif /* __SH5__ */
