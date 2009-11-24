! SH5 code Copyright 2002 SuperH Ltd.

#include "asm.h"

ENTRY(strcmp)

#if __SHMEDIA__
	ld.ub	r2,0,r4
	pt/l	quickret0,tr0
	ld.ub	r3,0,r5
	ptabs	r18,tr2
	beqi/u	r4,0,tr0
	ld.ub	r2,1,r6
	bne/u	r4,r5,tr0
	pt/l	quickret1,tr1
	ld.ub	r3,1,r7
	beqi/u	r6,0,tr1
	ld.ub	r2,2,r4
	bne/u	r6,r7,tr1
	ld.ub	r3,2,r5
	beqi/u	r4,0,tr0
	ld.ub	r2,3,r6
	bne/u	r4,r5,tr0
	ld.ub	r3,3,r7
	beqi/u	r6,0,tr1
	ld.ub	r2,4,r4
	bne/u	r6,r7,tr1
	ld.ub	r3,4,r5
	beqi/u	r4,0,tr0
	ld.ub	r2,5,r6
	bne/u	r4,r5,tr0
	ld.ub	r3,5,r7
	beqi/u	r6,0,tr1
	ld.ub	r2,6,r4
	bne/u	r6,r7,tr1
	ld.ub	r3,6,r5
	beqi/u	r4,0,tr0
	ld.ub	r2,7,r6
	bne/u	r4,r5,tr0
	ld.ub	r3,7,r7
	beqi/u	r6,0,tr1
	sub	r3,r2,r3
	bne/u	r6,r7,tr1

	andi	r2,-8,r2
	add	r3,r2,r3
	ldlo.q	r3,8,r23
	pt	r23_zero,tr0
	shlli	r3,3,r22
	sub	r63,r22,r20
	movi	0x101,r6
	mperm.w	r6,r63,r6
	SHLO	r6,r22,r7
	msubs.ub r7,r23,r8
	pt	loop,tr1
	bnei/u	r8,0,tr0 // r23_zero
	pt	found_zero,tr0
	addi	r3,15,r3
	andi	r3,-8,r3
	sub	r3,r2,r3
	bne/l	r7,r6,tr1 // loop
	/* The strings are aligned to each other.  */
	/* It is possible to have a loop with six cycles / iteration
	   by re-ordering the exit conditions, but then it needs extra
	   time and/or code to sort out the r4 != r5 case.  */
	pt	al_loop,tr1
	pt	al_found_zero,tr0
al_loop:
	ld.q	r2,8,r4
	ldx.q	r2,r3,r5
	addi	r2,8,r2
	mcmpeq.b r63,r4,r8
	pt	cmp_quad,tr3
	bnei/u	r8,0,tr0  // al_found_zero
	beq/l	r4,r5,tr1 // al_loop
	blink	tr3,r63   // cmp_quad

	.balign 8
quickret0:
	sub	r4,r5,r2
	blink	tr2,r63
quickret1:
	sub	r6,r7,r2
	blink	tr2,r63

loop:
	ld.q	r2,8,r4
	ldx.q	r2,r3,r19
	addi	r2,8,r2
	msubs.ub r6,r4,r8
	mcmpeq.b r63,r19,r9
	SHHI	r19,r20,r21
	or	r21,r23,r5
	SHLO	r19,r22,r23
	bne/u	r8,r9,tr0 // found_zero
	beq/l	r4,r5,tr1 // loop
cmp_quad:
#ifdef __LITTLE_ENDIAN__
	byterev r4,r4
	byterev r5,r5
#endif
	cmpgtu	r4,r5,r6
	cmpgtu	r5,r4,r7
	sub	r6,r7,r2
	blink tr2,r63
found_zero:
	pt	zero_now,tr0
	pt	cmp_quad,tr1
	SHHI	r9,r20,r7
	bne/u	r8,r7,tr0 // zero_now
	bne/u	r4,r5,tr1 // cmp_quad
	SHLO	r9,r22,r8
r23_zero:
	ld.q	r2,8,r4
	add	r23,r63,r5
zero_now:
al_found_zero:
/* We konw that one of the values has at lest one zero, and r8 holds
   an 0x01 or 0xff mask for every zero found in one of the operands.
   If both operands have the first zero in the same place, this mask
   allows us to truncate the comparison to the valid bytes in the
   strings.  If the first zero is in different places, it doesn't
   matter if some invalid bytes are included, since the comparison
   of the zero with the non-zero will determine the outcome.  */
#ifdef __LITTLE_ENDIAN__
	shlli	r8,8,r8
	addi	r8,-1,r9
	andc	r9,r8,r8
	and	r8,r4,r4
	and	r8,r5,r5
#else
	shlri r8,1,r8
	nsb	r8,r8
	addi	r8,8,r8
	andi	r8,56,r8
	sub	r63,r8,r8
	shlrd	r4,r8,r4
	shlrd	r5,r8,r5
#endif
#ifdef __LITTLE_ENDIAN__
	byterev r4,r4
	byterev r5,r5
#endif
	cmpgtu	r4,r5,r6
	cmpgtu	r5,r4,r7
	sub	r6,r7,r2
	blink tr2,r63

#else /* ! __SHMEDIA__, i.e. SH 1..4 / SHcompact */

#ifdef __SH5__
#define STR1 r2
#define STR2 r3
#define RESULT r2
#define TMP r4
#else
! Entry: r4: string1
!        r5: string2
! Exit:  r0: result
!        r1-r2,r4-r5: clobbered
#define STR1 r4
#define STR2 r5
#define RESULT r0
#define TMP r2
#endif /* __SH5__ */

	mov     STR1,r0
	or      STR2,r0
	tst	#3,r0
	bf	L_setup_char_loop
	mov	#0,r0
#ifdef DELAYED_BRANCHES
	mov.l	@STR1+,r1
	.align  2
Longword_loop:
	mov.l	@STR2+,TMP
	cmp/str	r0,r1
	bt	Longword_loop_end
	cmp/eq	r1,TMP
	bt.s	Longword_loop
	mov.l	@STR1+,r1
	add #-4, STR1
Longword_loop_end:
	add #-4, STR1
	add #-4, STR2
L_setup_char_loop:
	mov.b	@STR1+,r0
	.align  2
L_char_loop:
	mov.b	@STR2+,r1
	tst	r0,r0
	bt	L_return
	cmp/eq	r0,r1
	bt.s L_char_loop
	mov.b	@STR1+,r0
	add	#-2,STR1
	mov.b	@STR1,r0
#else /* ! DELAYED_BRANCHES */
	.align  2
Longword_loop:
	mov.l	@r4+,r1
	mov.l	@r5+,r2
	cmp/str	r0,r1
	bt	Longword_loop_end
	cmp/eq	r1,r2
	bt	Longword_loop
Longword_loop_end:
	add #-4, r4
	add #-4, r5
	.align  2
L_setup_char_loop:
L_char_loop:
	mov.b	@r4+,r0
	mov.b	@r5+,r1
	tst	r0,r0
	bt	L_return
	cmp/eq	r0,r1
	bt L_char_loop
#endif
L_return:
	extu.b	r0,RESULT
	extu.b	r1,r1
	rts
	sub	r1,RESULT
#endif /* ! __SHMEDIA__ */
