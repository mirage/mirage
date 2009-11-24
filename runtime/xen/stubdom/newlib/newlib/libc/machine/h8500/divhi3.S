	.title "H8/500 DIVIDE"
!! 2 byte integer Divide code for the H8/500
!!
!! Steve Chamberlain
!! sac@cygnus.com
!!
!!

!! args in r1 and r4, result in r0/r1

#if __CODE__==32
#define RET prts
#else
#define RET rts
#endif
	.global	__divmodhi4

		
__divmodhi4:
	clr.w	r0	
	tst.w	r1	! neg arg1
	bpl	PU	


	neg.w   r1	
NU:	tst.w	r4	
	bmi	NN

NP:	divxu.w	r4,r0
	neg.w	r0
	neg.w	r1
	RET

NN:	neg.w	r4
	divxu.w	r4,r0
	neg.w	r0	! get rem sign right
	RET


PU:
	tst.w	r4
	bpl	PP
	

PN:	neg.w	r4
	divxu.w	r4,r0
	neg.w	r1
	RET

PP:	divxu.w	r4,r0	! rem in r0, q in r1
	RET

	
	
