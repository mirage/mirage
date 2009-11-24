!
! Fast SH memcpy
!
! by Toshiyasu Morita (tm@netcom.com)
! hacked by J"orn Rernnecke (joern.rennecke@superh.com) ("o for o-umlaut)
! SH5 code Copyright 2002 SuperH Ltd.
!
! Entry: ARG0: destination pointer
!        ARG1: source pointer
!        ARG3: byte count
!
! Exit:  RESULT: destination pointer
!        any other registers in the range r0-r7: trashed
!
! Notes: Usually one wants to do small reads and write a longword, but
!        unfortunately it is difficult in some cases to concatanate bytes
!        into a longword on the SH, so this does a longword read and small
!        writes.
!
! This implementation makes two assumptions about how it is called:
!
! 1.: If the byte count is nonzero, the address of the last byte to be
!     copied is unsigned greater than the address of the first byte to
!     be copied.  This could be easily swapped for a signed comparison,
!     but the algorithm used needs some comparison.
!
! 2.: When there are two or three bytes in the last word of an 11-or-more
!     bytes memory chunk to b copied, the rest of the word can be read
!     without side effects.
!     This could be easily changed by increasing the minumum size of
!     a fast memcpy and the amount subtracted from r7 before L_2l_loop be 2,
!     however, this would cost a few extra cyles on average.
!     For SHmedia, the assumption is that any quadword can be read in its
!     enirety if at least one byte is included in the copy.
!

#include "asm.h"

ENTRY(memcpy)

#if __SHMEDIA__

#define LDUAQ(P,O,D0,D1) ldlo.q P,O,D0; ldhi.q P,O+7,D1
#define STUAQ(P,O,D0,D1) stlo.q P,O,D0; sthi.q P,O+7,D1
#define LDUAL(P,O,D0,D1) ldlo.l P,O,D0; ldhi.l P,O+3,D1
#define STUAL(P,O,D0,D1) stlo.l P,O,D0; sthi.l P,O+3,D1

	ld.b r3,0,r63
	pta/l Large,tr0
	movi 25,r0
	bgeu/u r4,r0,tr0
	nsb r4,r0
	shlli r0,5,r0
	movi (L1-L0+63*32 + 1) & 0xffff,r1
	sub r1, r0, r0
L0:	ptrel r0,tr0
	add r2,r4,r5
	ptabs r18,tr1
	add r3,r4,r6
	blink tr0,r63

	.balign 8
L1:
	/* 0 byte memcpy */
	blink tr1,r63

L4_7:	/* 4..7 byte memcpy cntd. */
	stlo.l r2, 0, r0
	or r6, r7, r6
	sthi.l r5, -1, r6
	stlo.l r5, -4, r6
	blink tr1,r63

L2_3:	/* 2 or 3 byte memcpy cntd. */
	st.b r5,-1,r6
	blink tr1,r63

	/* 1 byte memcpy */
	ld.b r3,0,r0
	st.b r2,0,r0
	blink tr1,r63

L8_15:	/* 8..15 byte memcpy cntd. */
	stlo.q r2, 0, r0
	or r6, r7, r6
	sthi.q r5, -1, r6
	stlo.q r5, -8, r6
	blink tr1,r63
	
	/* 2 or 3 byte memcpy */
	ld.b r3,0,r0
	ld.b r2,0,r63
	ld.b r3,1,r1
	st.b r2,0,r0
	pta/l L2_3,tr0
	ld.b r6,-1,r6
	st.b r2,1,r1
	blink tr0, r63

	/* 4 .. 7 byte memcpy */
	LDUAL (r3, 0, r0, r1)
	pta L4_7, tr0
	ldlo.l r6, -4, r7
	or r0, r1, r0
	sthi.l r2, 3, r0
	ldhi.l r6, -1, r6
	blink tr0, r63

	/* 8 .. 15 byte memcpy */
	LDUAQ (r3, 0, r0, r1)
	pta L8_15, tr0
	ldlo.q r6, -8, r7
	or r0, r1, r0
	sthi.q r2, 7, r0
	ldhi.q r6, -1, r6
	blink tr0, r63

	/* 16 .. 24 byte memcpy */
	LDUAQ (r3, 0, r0, r1)
	LDUAQ (r3, 8, r8, r9)
	or r0, r1, r0
	sthi.q r2, 7, r0
	or r8, r9, r8
	sthi.q r2, 15, r8
	ldlo.q r6, -8, r7
	ldhi.q r6, -1, r6
	stlo.q r2, 8, r8
	stlo.q r2, 0, r0
	or r6, r7, r6
	sthi.q r5, -1, r6
	stlo.q r5, -8, r6
	blink tr1,r63

Large:
	ld.b r2, 0, r63
	pta/l  Loop_ua, tr1
	ori r3, -8, r7
	sub r2, r7, r22
	sub r3, r2, r6
	add r2, r4, r5
	ldlo.q r3, 0, r0
	addi r5, -16, r5
	movi 64+8, r27 // could subtract r7 from that.
	stlo.q r2, 0, r0
	sthi.q r2, 7, r0
	ldx.q r22, r6, r0
	bgtu/l r27, r4, tr1

	addi r5, -48, r27
	pta/l Loop_line, tr0
	addi r6, 64, r36
	addi r6, -24, r19
	addi r6, -16, r20
	addi r6, -8, r21

Loop_line:
	ldx.q r22, r36, r63
	alloco r22, 32
	addi r22, 32, r22
	ldx.q r22, r19, r23
	sthi.q r22, -25, r0
	ldx.q r22, r20, r24
	ldx.q r22, r21, r25
	stlo.q r22, -32, r0
	ldx.q r22, r6,  r0
	sthi.q r22, -17, r23
	sthi.q r22,  -9, r24
	sthi.q r22,  -1, r25
	stlo.q r22, -24, r23
	stlo.q r22, -16, r24
	stlo.q r22,  -8, r25
	bgeu r27, r22, tr0

Loop_ua:
	addi r22, 8, r22
	sthi.q r22, -1, r0
	stlo.q r22, -8, r0
	ldx.q r22, r6, r0
	bgtu/l r5, r22, tr1

	add r3, r4, r7
	ldlo.q r7, -8, r1
	sthi.q r22, 7, r0
	ldhi.q r7, -1, r7
	ptabs r18,tr1
	stlo.q r22, 0, r0
	or r1, r7, r1
	sthi.q r5, 15, r1
	stlo.q r5, 8, r1
	blink tr1, r63

#else /* ! SHMEDIA, i.e. SH1 .. SH4 / SHcompact */

#ifdef __SH5__
#define DST r2
#define SRC r3
#define COUNT r4
#define TMP0 r5
#define TMP1 r6
#define RESULT r2
#else
#define DST r4
#define SRC r5
#define COUNT r6
#define TMP0 r2
#define TMP1 r3
#define RESULT r0
#endif

#ifdef __LITTLE_ENDIAN__
	! Little endian version copies with increasing addresses.
	mov DST,TMP1	! Save return value
	mov #11,r0	! Check if small number of bytes
	cmp/hs r0,COUNT
			! COUNT becomes src end address
	SL(bf, L_small, add SRC,COUNT)
	mov #1,r1
	tst r1,SRC	! check if source even
	SL(bt, L_even, mov COUNT,r7)
	mov.b @SRC+,r0	! no, make it even.
	mov.b r0,@DST
	add #1,DST
L_even:	tst r1,DST	! check if destination is even
	add #-3,r7
	SL(bf, L_odddst, mov #2,r1)
	tst r1,DST	! check if destination is 4-byte aligned
	mov DST,r0
	SL(bt, L_al4dst, sub SRC,r0)
	mov.w @SRC+,TMP0
	mov.w TMP0,@DST
	! add #2,DST  DST is dead here.
L_al4dst:
	tst r1,SRC
	bt L_al4both
	mov.w @SRC+,r1
	swap.w r1,r1
	add #-6,r0
	add #-6,r7	! r7 := src end address minus 9.
	.align 2
L_2l_loop:
	mov.l @SRC+,TMP0 ! Read & write two longwords per iteration
	xtrct TMP0,r1
	mov.l r1,@(r0,SRC)
	cmp/hs r7,SRC
	mov.l @SRC+,r1
	xtrct r1,TMP0
	mov.l TMP0,@(r0,SRC)
	bf L_2l_loop
	add #-2,SRC
	bra  L_cleanup
	add #5,r0
L_al4both:
	add #-4,r0
	.align 2
L_al4both_loop:
	mov.l @SRC+,DST   ! Read longword, write longword per iteration
	cmp/hs r7,SRC
	SL(bf, L_al4both_loop, mov.l DST,@(r0,SRC))

	bra L_cleanup
	add #3,r0

L_odddst:
	tst r1,SRC
	SL(bt, L_al4src, add #-1,DST)
	mov.w @SRC+,r0
	mov.b r0,@(1,DST)
	shlr8 r0
	mov.b r0,@(2,DST)
	add #2,DST
L_al4src:
	.align 2
L_odd_loop:
	mov.l @SRC+,r0   ! Read longword, write byte, word, byte per iteration
	cmp/hs r7,SRC
	mov.b r0,@(1,DST)
	shlr8 r0
	mov.w r0,@(2,DST)
	shlr16 r0
	mov.b r0,@(4,DST)
	SL(bf, L_odd_loop, add #4,DST)
	.align 2 ! avoid nop in more frequently executed code.
L_cleanup2:
	mov	DST,r0
	sub	SRC,r0
L_cleanup:
	cmp/eq	COUNT,SRC
	bt	L_ready
	.align 2
L_cleanup_loop:
	mov.b	@SRC+,r1
	cmp/eq	COUNT,SRC
	mov.b	r1,@(r0,SRC)
	bf	L_cleanup_loop
L_ready:
	rts
	mov	TMP1,RESULT
L_small:
	bra L_cleanup2
	add #-1,DST
#else /* ! __LITTLE_ENDIAN__ */
	! Big endian version copies with decreasing addresses.
	mov DST,r0
	add COUNT,r0
	sub DST,SRC
	mov #11,r1
	cmp/hs r1,COUNT
	SL(bf, L_small, add #-1,SRC)
	mov SRC,TMP1
	add r0,TMP1
	shlr TMP1
	SL(bt, L_even,
	mov DST,r7)
	mov.b @(r0,SRC),TMP0
	add #-1,TMP1
	mov.b TMP0,@-r0
L_even:
	tst #1,r0
	add #-1,SRC
	SL(bf, L_odddst, add #8,r7)
	tst #2,r0
	bt L_al4dst
	add #-1,TMP1
	mov.w @(r0,SRC),r1
	mov.w r1,@-r0
L_al4dst:
	shlr TMP1
	bt L_al4both
	mov.w @(r0,SRC),r1
	swap.w r1,r1
	add #4,r7
	add #-4,SRC
	.align 2
L_2l_loop:
	mov.l @(r0,SRC),TMP0
	xtrct TMP0,r1
	mov.l r1,@-r0
	cmp/hs r7,r0
	mov.l @(r0,SRC),r1
	xtrct r1,TMP0
	mov.l TMP0,@-r0
	bt L_2l_loop
	bra L_cleanup
	add #5,SRC

	nop ! avoid nop in executed code.
L_al4both:
	add #-2,SRC
	.align 2
L_al4both_loop:
	mov.l @(r0,SRC),r1
	cmp/hs r7,r0
	SL(bt, L_al4both_loop,
	mov.l r1,@-r0)
	bra L_cleanup
	add #3,SRC

	nop ! avoid nop in executed code.
L_odddst:
	shlr TMP1
	bt L_al4src
	mov.w @(r0,SRC),r1
	mov.b r1,@-r0
	shlr8 r1
	mov.b r1,@-r0
L_al4src:
	add #-2,SRC
	.align 2
L_odd_loop:
	mov.l @(r0,SRC),TMP0
	cmp/hs r7,r0
	mov.b TMP0,@-r0
	shlr8 TMP0
	mov.w TMP0,@-r0
	shlr16 TMP0
	mov.b TMP0,@-r0
	bt L_odd_loop

	add #3,SRC
L_cleanup:
L_small:
	cmp/eq DST,r0
	bt L_ready
	add #1,DST
	.align 2
L_cleanup_loop:
	mov.b @(r0,SRC),TMP0
	cmp/eq DST,r0
	mov.b TMP0,@-r0
	bf L_cleanup_loop
L_ready:
	rts
	mov r0,RESULT
#endif /* ! __LITTLE_ENDIAN__ */
#endif /* ! SHMEDIA */
