/* We want to pretend we're in SHmedia mode, even when assembling for
   SHcompact.  */
#if __SH5__ == 32 && ! __SHMEDIA__
# undef __SHMEDIA__
# define __SHMEDIA__ 1
#endif

#if __SHMEDIA__
	.mode	SHmedia
#endif

#include "asm.h"

ENTRY(setjmp)
#if __SH5__
	ptabs	r18, tr0
	gettr	tr5, r5
	gettr	tr6, r6
	gettr	tr7, r7
	st.q	r2,  0*8, r18
	st.q	r2,  1*8, r10
	st.q	r2,  2*8, r11
	st.q	r2,  3*8, r12
	st.q	r2,  4*8, r13
	st.q	r2,  5*8, r14
	st.q	r2,  6*8, r15
	st.q	r2,  7*8, r28
	st.q	r2,  8*8, r29
	st.q	r2,  9*8, r30
	st.q	r2, 10*8, r31
	st.q	r2, 11*8, r32
	st.q	r2, 12*8, r33
	st.q	r2, 13*8, r34
	st.q	r2, 14*8, r35
	st.q	r2, 15*8, r44
	st.q	r2, 16*8, r45
	st.q	r2, 17*8, r46
	st.q	r2, 18*8, r47
	st.q	r2, 19*8, r48
	st.q	r2, 20*8, r49
	st.q	r2, 21*8, r50
	st.q	r2, 22*8, r51
	st.q	r2, 23*8, r52
	st.q	r2, 24*8, r53
	st.q	r2, 25*8, r54
	st.q	r2, 26*8, r55
	st.q	r2, 27*8, r56
	st.q	r2, 28*8, r57
	st.q	r2, 29*8, r58
	st.q	r2, 30*8, r59
	st.q	r2, 31*8, r5
	st.q	r2, 32*8, r6
	st.q	r2, 33*8, r7
#if ! __SH4_NOFPU__
	fst.d	r2, 34*8, dr12
	fst.d	r2, 35*8, dr14
	fst.d	r2, 36*8, dr36
	fst.d	r2, 37*8, dr38
	fst.d	r2, 38*8, dr40
	fst.d	r2, 39*8, dr42
	fst.d	r2, 40*8, dr44
	fst.d	r2, 41*8, dr46
	fst.d	r2, 42*8, dr48
	fst.d	r2, 43*8, dr50
	fst.d	r2, 44*8, dr52
	fst.d	r2, 45*8, dr54
	fst.d	r2, 46*8, dr56
	fst.d	r2, 47*8, dr58
	fst.d	r2, 48*8, dr60
	fst.d	r2, 49*8, dr62
#endif
	movi	0, r2
	blink	tr0, r63
#else
#if defined (__SH2E__) || defined (__SH3E__) || defined(__SH4_SINGLE__) || defined(__SH4__) || defined(__SH4_SINGLE_ONLY__)
	add	#(13*4),r4
#else
	add	#(9*4),r4
#endif

	sts.l	pr,@-r4

#if defined (__SH2E__) || defined (__SH3E__) || defined(__SH4_SINGLE__) || defined(__SH4__) || defined(__SH4_SINGLE_ONLY__)
	fmov.s	fr15,@-r4	! call saved floating point registers
	fmov.s	fr14,@-r4
	fmov.s	fr13,@-r4
	fmov.s	fr12,@-r4
#endif

	mov.l	r15,@-r4	! call saved integer registers
	mov.l	r14,@-r4
	mov.l	r13,@-r4
	mov.l	r12,@-r4

	mov.l	r11,@-r4
	mov.l	r10,@-r4
	mov.l	r9,@-r4
	mov.l	r8,@-r4

	rts
	mov    #0,r0
#endif /* __SH5__ */

ENTRY(longjmp)
#if __SH5__
	ld.q	r2,  0*8, r18
	ptabs	r18, tr0
	ld.q	r2,  1*8, r10
	ld.q	r2,  2*8, r11
	ld.q	r2,  3*8, r12
	ld.q	r2,  4*8, r13
	ld.q	r2,  5*8, r14
	ld.q	r2,  6*8, r15
	ld.q	r2,  7*8, r28
	ld.q	r2,  8*8, r29
	ld.q	r2,  9*8, r30
	ld.q	r2, 10*8, r31
	ld.q	r2, 11*8, r32
	ld.q	r2, 12*8, r33
	ld.q	r2, 13*8, r34
	ld.q	r2, 14*8, r35
	ld.q	r2, 15*8, r44
	ld.q	r2, 16*8, r45
	ld.q	r2, 17*8, r46
	ld.q	r2, 18*8, r47
	ld.q	r2, 19*8, r48
	ld.q	r2, 20*8, r49
	ld.q	r2, 21*8, r50
	ld.q	r2, 22*8, r51
	ld.q	r2, 23*8, r52
	ld.q	r2, 24*8, r53
	ld.q	r2, 25*8, r54
	ld.q	r2, 26*8, r55
	ld.q	r2, 27*8, r56
	ld.q	r2, 28*8, r57
	ld.q	r2, 29*8, r58
	ld.q	r2, 30*8, r59
	ld.q	r2, 31*8, r5
	ld.q	r2, 32*8, r6
	ld.q	r2, 33*8, r7
	ptabs	r5, tr5
	ptabs	r6, tr6
	ptabs	r7, tr7
#if ! __SH4_NOFPU__
	fld.d	r2, 34*8, dr12
	fld.d	r2, 35*8, dr14
	fld.d	r2, 36*8, dr36
	fld.d	r2, 37*8, dr38
	fld.d	r2, 38*8, dr40
	fld.d	r2, 39*8, dr42
	fld.d	r2, 40*8, dr44
	fld.d	r2, 41*8, dr46
	fld.d	r2, 42*8, dr48
	fld.d	r2, 43*8, dr50
	fld.d	r2, 44*8, dr52
	fld.d	r2, 45*8, dr54
	fld.d	r2, 46*8, dr56
	fld.d	r2, 47*8, dr58
	fld.d	r2, 48*8, dr60
	fld.d	r2, 49*8, dr62
#endif
	movi	1, r2
	cmvne	r3, r3, r2
	blink	tr0, r63
#else
	mov.l	@r4+,r8
	mov.l	@r4+,r9
	mov.l	@r4+,r10
	mov.l	@r4+,r11

	mov.l	@r4+,r12
	mov.l	@r4+,r13
	mov.l	@r4+,r14
	mov.l	@r4+,r15

#if defined (__SH2E__) || defined (__SH3E__) || defined(__SH4_SINGLE__) || defined(__SH4__) || defined(__SH4_SINGLE_ONLY__)
	fmov.s	@r4+,fr12	! call saved floating point registers
	fmov.s	@r4+,fr13
	fmov.s	@r4+,fr14
	fmov.s	@r4+,fr15
#endif

	lds.l	@r4+,pr

	mov	r5,r0
	tst	r0,r0
	bf	retr4
	movt	r0
retr4:	rts
	nop
#endif /* __SH5__ */
