
#ifdef __SH5__
	.section .data,"aw"
	.global ___data
___data:

	.section .rodata,"a"
	.global ___rodata
___rodata:

#if __SH5__ == 64
	.section .text,"ax"
#define LOAD_ADDR(sym, reg) \
	movi	(sym >> 48) & 65535, reg; \
	shori	(sym >> 32) & 65535, reg; \
	shori	(sym >> 16) & 65535, reg; \
	shori	sym & 65535, reg
#else
	.mode	SHmedia
	.section .text..SHmedia32,"ax"
#define LOAD_ADDR(sym, reg) \
	movi	(sym >> 16) & 65535, reg; \
	shori	sym & 65535, reg
#endif
	.global start
start:
	LOAD_ADDR (_stack, r15)

	pt/l	zero_bss_loop, tr0
	pt/l	_atexit, tr1
	pt/l	_init, tr5
	pt/l	_main, tr6
	pt/l	_exit, tr7

	! zero out bss
	LOAD_ADDR (_edata, r0)
	LOAD_ADDR (_end, r1)
zero_bss_loop:
	stx.q	r0, r63, r63
	addi	r0, 8, r0
	bgt/l	r1, r0, tr0

	LOAD_ADDR (___data, r26)
	LOAD_ADDR (___rodata, r27)

#if ! __SH4_NOFPU__
	getcon	cr0, r0
	movi	1, r1
	shlli	r1, 15, r1
	or	r1, r0, r0
	putcon	r0, cr0
#endif

	! arrange for exit to call fini
	LOAD_ADDR (_fini, r2)
	blink	tr1, r18

	! call init
	blink	tr5, r18

	! call the mainline
	blink	tr6, r18

	! call exit
	blink	tr7, r18
#else
	.section .text
	.global	start
start:
	mov.l	stack_k,r15

	! zero out bss
	mov.l	edata_k,r0
	mov.l	end_k,r1
	mov	#0,r2
start_l:
	 mov.l	r2,@r0
	add	#4,r0
	cmp/ge	r0,r1
	bt	start_l

#ifndef __SH2A_NOFPU__
#if defined (__SH3E__) || defined(__SH4_SINGLE__) || defined(__SH4__) || defined(__SH4_SINGLE_ONLY) || defined(__SH2A__)
	mov.l set_fpscr_k, r1
	jsr @r1
	mov #0,r4
	lds r3,fpscr
#endif /*  defined (__SH3E__) || defined(__SH4_SINGLE__) || defined(__SH4__) || defined(__SH4_SINGLE_ONLY__) || defined(__SH2A__) */
#endif /* !__SH2A_NOFPU__ */

	! call the mainline	
	mov.l	main_k,r0
	jsr	@r0
	or	r0,r0

	! call exit
	mov	r0,r4
	mov.l	exit_k,r0
	jsr	@r0
	or	r0,r0

	.align 2
#ifndef __SH2A_NOFPU__
#if defined (__SH3E__) || defined(__SH4_SINGLE__) || defined(__SH4__) || defined(__SH4_SINGLE_ONLY__) || defined(__SH2A__)
set_fpscr_k:
	.long	___set_fpscr
#endif /*  defined (__SH3E__) || defined(__SH4_SINGLE__) || defined(__SH4__) || defined(SH4_SINGLE_ONLY) || defined(__SH2A__) */
#endif /* !__SH2A_NOFPU__ */
stack_k:
	.long	_stack	
edata_k:
	.long	_edata
end_k:
	.long	_end
main_k:
	.long	_main
exit_k:
	.long	_exit
#endif
