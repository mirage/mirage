/* convert psi to si inplace

Note that `fp' below isn't a segment register.
It's r6, the frame pointer.  */

#if __CODE__==32
#define RET prts
#else
#define RET rts
#endif

#define EXTPSISI_SN(r_msw,r_lsw,sp)		; \
	.global	__extpsisi##r_msw		; \
__extpsisi##r_msw:				; \
	mov	r_msw,r_lsw			; \
	stc	sp,r_msw			; \
	RET

	EXTPSISI_SN(r2,r3,dp)
	EXTPSISI_SN(r4,r5,ep)


#define ADDPSI_AR_RN(sr,an,r_msw,r_lsw)	\
	.global	__addpsi##an##r_msw ;	\
__addpsi##an##r_msw:		 ;	\
	stc	sr,@-sp		 ;	\
	add	an,r_lsw		 ;	\
	addx	@sp+,r_msw		 ;	\
	RET

	ADDPSI_AR_RN(dp,r2,r0,r1)
	ADDPSI_AR_RN(dp,r2,r3,r4)
	ADDPSI_AR_RN(ep,r4,r0,r1)
	ADDPSI_AR_RN(ep,r4,r1,r2)
	ADDPSI_AR_RN(ep,r4,r3,r4)
	ADDPSI_AR_RN(ep,r4,r5,fp)

	ADDPSI_AR_RN(tp,fp,r0,r1)

	
#define ADDPSI_RN_AR(r_msw,r_lsw,sr,an,t_msw,t_lsw)	\
	.global	__addpsi##r_msw##an		; \
__addpsi##r_msw##an:				; \
	mov.w	t_msw,@-sp			; \
	mov.w	t_lsw,@-sp			; \
	stc	sr,t_msw			; \
	mov	an,t_lsw			; \
	add	r_lsw,t_lsw			; \
	addx	r_msw,t_msw			; \
	ldc	t_msw,sr			; \
	mov.w	t_lsw,an			; \
	mov.w	@sp+,t_lsw			; \
	mov.w	@sp+,t_msw			; \
	RET	

	ADDPSI_RN_AR(r0,r1,dp,r2,r4,r5)
	ADDPSI_RN_AR(r0,r1,ep,r4,r2,r3)



#define EXTPSIHI_RN_RN(rm,r_msw,r_lsw)	; \
	.global	__extpsihi##rm##r_msw 	; \
__extpsihi##rm##r_msw:		   	; \
	mov	rm,r_lsw	   	; \
	clr.w	r_msw		   	; \
	RET

	EXTPSIHI_RN_RN(r3,r0,r1)
	EXTPSIHI_RN_RN(r4,r0,r1)
	EXTPSIHI_RN_RN(r5,r0,r1)
	EXTPSIHI_RN_RN(r2,r0,r1)



/* ifdefed out, because gcc doesn't like the # character in the above
   macro.  The macro expands into an assembly languange comment anyways,
   so it serves no useful purpose.  */
#if 0
#define EXTPSIHI_RN_SN(rm,r_msw,r_lsw)	; \
	.global	__extpsihi##rm##r_lsw 	; \
__extpsihi##rm##r_lsw:		   	; \
	mov	rm,r_lsw	   	; \
	ldc	\#0,r_msw	   	; \
	RET

	EXTPSIHI_RN_SN(r0,dp,r2)
	EXTPSIHI_RN_SN(r0,ep,r4)
	EXTPSIHI_RN_SN(r1,dp,r2)
	EXTPSIHI_RN_SN(r1,ep,r4)
	EXTPSIHI_RN_SN(r3,dp,r2)
	EXTPSIHI_RN_SN(r3,ep,r4)
	EXTPSIHI_RN_SN(r5,dp,r2)
	EXTPSIHI_RN_SN(r5,ep,r4)
	EXTPSIHI_RN_SN(r2,ep,r4)
#endif


#define EXTPSISI_RN(r_msw,r_lsw)		; \
	.global	__extpsisi##r_msw	 	; \
__extpsisi##r_msw:		   		; \
	RET

	EXTPSISI_RN(r0,r1)



#define ADDPSI_SA_SB(sa,ra,sb,rb)	; \
	.global	__addpsi##ra##rb	; \
__addpsi##ra##rb:			; \
	mov.w	r0,@-sp			; \
	mov.w	r1,@-sp			; \
	stc	sa,r0			; \
	stc	sb,r1			; \
	add.w	ra,rb			; \
	addx	r0,r1			; \
	ldc	r1,sb			; \
	mov.w	@sp+,r1			; \
	mov.w	@sp+,r0			; \
	RET		


	ADDPSI_SA_SB(dp,r2,ep,r4)
	ADDPSI_SA_SB(ep,r4,dp,r2)
	ADDPSI_SA_SB(tp,fp,dp,r2)
	ADDPSI_SA_SB(tp,fp,ep,r4)

	ADDPSI_SA_SB(dp,r2,dp,r2)



	.global	__addpsir0r0
__addpsir0r0:
	add.w	r1,r1
	addx	r0,r0
	RET

