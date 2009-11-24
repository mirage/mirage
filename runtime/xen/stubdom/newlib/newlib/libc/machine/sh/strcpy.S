! Entry: arg0: destination
!        arg1: source
! Exit:  result: destination
!
! SH5 code Copyright 2002 SuperH Ltd.

#include "asm.h"

ENTRY(strcpy)

#if __SHMEDIA__

	pta/l shortstring,tr1
	ldlo.q r3,0,r4
	ptabs r18,tr4
	shlli r3,3,r7
	addi r2, 8, r0
	mcmpeq.b r4,r63,r6
	SHHI r6,r7,r6
	bnei/u r6,0,tr1 // shortstring
	pta/l no_lddst, tr2
	ori r3,-8,r23
	sub r2, r23, r0
	sub r3, r2, r21
	addi r21, 8, r20
	ldx.q r0, r21, r5
	pta/l loop, tr0
	ori r2,-8,r22
	mcmpeq.b r5, r63, r6
	bgt/u r22, r23, tr2 // no_lddst

	// r22 < r23 :  Need to do a load from the destination.
	// r22 == r23 : Doesn't actually need to load from destination,
	//              but still can be handled here.
	ldlo.q r2, 0, r9
	movi -1, r8
	SHLO r8, r7, r8
	mcmv r4, r8, r9
	stlo.q r2, 0, r9
	beqi/l r6, 0, tr0 // loop

	add r5, r63, r4
	addi r0, 8, r0
	blink tr1, r63 // shortstring
no_lddst:
	// r22 > r23: note that for r22 == r23 the sthi.q would clobber
	//            bytes before the destination region.
	stlo.q r2, 0, r4
	SHHI r4, r7, r4
	sthi.q r0, -1, r4
	beqi/l r6, 0, tr0 // loop

	add r5, r63, r4
	addi r0, 8, r0
shortstring:
#ifndef __LITTLE_ENDIAN__
	pta/l shortstring2,tr1
	byterev r4,r4
#endif
shortstring2:
	st.b r0,-8,r4
	andi r4,0xff,r5
	shlri r4,8,r4
	addi r0,1,r0
	bnei/l r5,0,tr1
	blink tr4,r63 // return
	
	.balign 8
loop:
	stlo.q r0, 0, r5
	ldx.q r0, r20, r4
	addi r0, 16, r0
	sthi.q r0, -9, r5
	mcmpeq.b r4, r63, r6
	bnei/u r6, 0, tr1 // shortstring
	ldx.q r0, r21, r5
	stlo.q r0, -8, r4
	sthi.q r0, -1, r4
	mcmpeq.b r5, r63, r6
	beqi/l r6, 0, tr0 // loop

	add r5, r63, r4
	addi r0, 8, r0
	blink tr1, r63 // shortstring

#else /* ! __SHMEDIA__, i.e. SH 1..4 / SHcompact */

#ifdef __SH5__
#define DST r2
#define SRC r3
#define TMP r4
#define RESULT R2
!        r0,r1,r3,r4: clobbered
#else
#define DST r4
#define SRC r5
#define TMP r2
#define RESULT r0
!        r1-r2,r5: clobbered
#endif
	mov     DST,r0
	or      SRC,r0
	tst	#3,r0
	SL(bf, L_setup_char_loop, mov DST,r0)
	mov.l   @SRC+,r1
	mov     #0,TMP
	cmp/str TMP,r1
	SL(bt, Longword_loop_end, sub SRC,r0)
	.align  2
Longword_loop:
	mov.l   r1,@(r0,SRC)
	mov.l   @SRC+,r1
	cmp/str TMP,r1
	bt      Longword_loop_end
	mov.l   r1,@(r0,SRC)
	mov.l   @SRC+,r1
	cmp/str TMP,r1
	bf      Longword_loop
Longword_loop_end:
	add	#-4,SRC
	add	#3,r0
	.align  2
L_char_loop:
	mov.b	@SRC+,r1
L_char_loop_start:
	tst	r1,r1
	SL(bf, L_char_loop, mov.b r1,@(r0,SRC))
	rts
	mov DST,RESULT
L_setup_char_loop:
	mov.b	@SRC+,r1
	bra L_char_loop_start
	sub SRC,r0
#endif /* ! __SHMEDIA__ */
