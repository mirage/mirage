; setjmp/longjmp for D30V.

	.text
	.globl	setjmp
	.type	setjmp,@function
	.stabs	"setjmp.S",100,0,0,setjmp
	.stabs	"int:t(0,1)=r(0,1);-2147483648;2147483647;",128,0,0,0
	.stabs	"setjmp:F(0,1)",36,0,1,setjmp

setjmp:
; Address of jmpbuf is passed in R2.  Save the appropriate registers.
	st2w	r26, @(r2+,r0)
	st2w	r28, @(r2+,r0)
	st2w	r30, @(r2+,r0)
	st2w	r32, @(r2+,r0)
	st2w	r34, @(r2+,r0)
	st2w	r36, @(r2+,r0)
	st2w	r38, @(r2+,r0)
	st2w	r40, @(r2+,r0)
	st2w	r42, @(r2+,r0)
	st2w	r44, @(r2+,r0)
	st2w	r46, @(r2+,r0)
	st2w	r48, @(r2+,r0)
	st2w	r50, @(r2+,r0)
	st2w	r52, @(r2+,r0)
	st2w	r54, @(r2+,r0)
	st2w	r56, @(r2+,r0)
	st2w	r58, @(r2+,r0)
	st2w	r60, @(r2+,r0)
	st2w	r62, @(r2+,r0)

	mvfacc	r4, a1, 16
	mvfacc	r5, a1, 0
	st2w	r4, @(r2+,r0)

	mvfsys	r4, psw
	mvfsys	r5, rpt_c
	st2w	r4, @(r2+,r0)

	mvfsys	r4, rpt_s
	mvfsys	r5, rpt_e
	st2w	r4, @(r2+,r0)

	mvfsys	r4, mod_s
	mvfsys	r5, mod_e
	st2w	r4, @(r2+,r0)

; Return 0 to caller
	add	r2, r0, r0
	jmp	link
.Lsetjmp:
	.size	setjmp,.Lsetjmp-setjmp
	.stabs	"",36,0,0,.Lsetjmp-setjmp

	.globl	longjmp
	.type	longjmp,@function
	.stabs	"longjmp:F(0,1)",36,0,1,longjmp
longjmp:
; Address of jmpbuf is in R2.  Restore the registers.
	ld2w	r26, @(r2+,r0)
	ld2w	r28, @(r2+,r0)
	ld2w	r30, @(r2+,r0)
	ld2w	r32, @(r2+,r0)
	ld2w	r34, @(r2+,r0)
	ld2w	r36, @(r2+,r0)
	ld2w	r38, @(r2+,r0)
	ld2w	r40, @(r2+,r0)
	ld2w	r42, @(r2+,r0)
	ld2w	r44, @(r2+,r0)
	ld2w	r46, @(r2+,r0)
	ld2w	r48, @(r2+,r0)
	ld2w	r50, @(r2+,r0)
	ld2w	r52, @(r2+,r0)
	ld2w	r54, @(r2+,r0)
	ld2w	r56, @(r2+,r0)
	ld2w	r58, @(r2+,r0)
	ld2w	r60, @(r2+,r0)
	ld2w	r62, @(r2+,r0)

	ld2w	r4, @(r2+,r0)
	mvtacc	a1, r4, r5

	mvfsys	r6, psw
	ld2w	r4, @(r2+,r0)		/* psw, rpt_c */
	and	r6, r6, 0xfcff		/* set rp, md bits from setjmp, leave */
	and	r4, r4, 0x0300		/* all other psw bits the same */
	or	r4, r4, r6
	mvtsys	psw, r4
	mvtsys	rpt_c, r5

	ld2w	r4, @(r2+,r0)
	mvtsys	rpt_s, r4
	mvtsys	rpt_e, r5

	ld2w	r4, @(r2+,r0)
	mvtsys	mod_s, r4
	mvtsys	mod_e, r5

; Value to return to caller is in R3.  If caller attemped to return 0,
; return 1 instead.

	cmpeq	f0, r3, 0	|| 	add	r2, r3, r0
	jmp	link		||	add/tx	r2, r2, 1
.Llongjmp:
	.size	longjmp,.Llongjmp-longjmp
	.stabs	"",36,0,0,.Llongjmp-longjmp
