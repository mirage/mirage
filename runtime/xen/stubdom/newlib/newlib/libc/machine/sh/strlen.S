! Entry: arg0: string start address
! Exit:  result: length
!
! Copyright 2002 SuperH Ltd.

#include "asm.h"

ENTRY(strlen)

#if __SHMEDIA__

	ldlo.q r2,0,r3
	ptabs/l r18,tr0
	pta/l loop,tr1
	andi r2,-8,r0
	shlli r2,3,r1
	mcmpeq.b r3,r63,r3
	SHHI r3,r1,r4
	beqi/u r4,0,tr1 // loop
#ifdef __LITTLE_ENDIAN__
	movi -1,r2
	addi r3,-1,r4
	msad.ubq r3,r4,r2
#else
	shlri r3,1,r3
	nsb r3,r3
	shlri r3,3,r2
#endif
	blink tr0,r63

loop:
	ldlo.q r0,8,r3
	addi r0,8,r0
	ldlo.q r0,8,r63
	mcmpeq.b r3,r63,r3
	beqi/l r3,0,tr1 // loop
	sub r0,r2,r2
#ifdef __LITTLE_ENDIAN__
	addi r3,-1,r4
	addi r2,-1,r2
	msad.ubq r3,r4,r2
#else
	shlri r3,1,r3
	nsb r3,r3
	shlri r3,3,r3
	add r2,r3,r2
#endif
	blink tr0,r63

#else /* ! __SHMEDIA__, i.e. SH 1..4 / SHcompact */

#ifdef __SH5__
#define STR_INIT r2
#define STR_ORIG r0
#define STR_COPY STR_ORIG
#define MASK r1
#define TMP r3
#define RESULT r2
!        r0,r1,r3: clobbered
#else
#define STR_INIT r4
#define STR_ORIG STR_INIT
#define STR_COPY STR
#define MASK r1
#define TMP r3
#define RESULT r0
!        r1,r3: clobbered
#endif
#define STR RESULT

	mov #3,MASK
	and STR_INIT,MASK
	tst MASK,MASK
	SL(bf, L_char_loop, mov STR_INIT, STR_COPY)
L_word_loop:
	mov.l @STR+,TMP
	cmp/str MASK,TMP
	bf L_word_loop
	add #-4,STR
L_char_loop:
	mov.b @STR+,TMP
	tst TMP,TMP
	bf L_char_loop
	add #-1,STR
	rts
	sub STR_ORIG,STR
#endif /* ! __SHMEDIA__ */
