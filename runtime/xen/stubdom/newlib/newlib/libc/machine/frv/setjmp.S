# setjmp/longjmp for Frv.  The jmpbuf looks like this:
#	
# Register	jmpbuf offset
# R16-R31	0x0-0x03c
# R48-R63	0x40-0x7c
# FR16-FR31     0x80-0xbc
# FR48-FR63     0xc0-0xfc
# LR            0x100
# SP            0x104
# FP            0x108
#
# R8 contains the pointer to jmpbuf

#include <frv-asm.h>

	.text
	.global	EXT(setjmp)
	.type	EXT(setjmp),@function
EXT(setjmp):
	stdi	gr16, @(gr8,0)
	stdi	gr18, @(gr8,8)
	stdi 	gr20, @(gr8,16)
	stdi	gr22, @(gr8,24)
	stdi	gr24, @(gr8,32)
	stdi	gr26, @(gr8,40)
	stdi	gr28, @(gr8,48)
	stdi	gr30, @(gr8,56)
#if __FRV_GPR__ != 32
	stdi	gr48, @(gr8,64)
	stdi	gr50, @(gr8,72)
	stdi	gr52, @(gr8,80)
	stdi	gr54, @(gr8,88)
	stdi	gr56, @(gr8,96)
	stdi	gr58, @(gr8,104)
	stdi	gr60, @(gr8,112)
	stdi	gr62, @(gr8,120)
#endif

#if __FRV_FPR__ != 0
	stdfi	fr16, @(gr8,128)
	stdfi	fr18, @(gr8,136)
	stdfi 	fr20, @(gr8,144)
	stdfi	fr22, @(gr8,152)
	stdfi	fr24, @(gr8,160)
	stdfi	fr26, @(gr8,168)
	stdfi	fr28, @(gr8,176)
	stdfi	fr30, @(gr8,184)
#if __FRV_FPR__ != 32
	stdfi	fr48, @(gr8,192)
	stdfi	fr50, @(gr8,200)
	stdfi	fr52, @(gr8,208)
	stdfi	fr54, @(gr8,216)
	stdfi	fr56, @(gr8,224)
	stdfi	fr58, @(gr8,232)
	stdfi	fr60, @(gr8,240)
	stdfi	fr62, @(gr8,248)
#endif
#endif

        movsg	lr, gr4
	sti     gr4, @(gr8,256)
	sti     sp, @(gr8,260)
	sti     fp, @(gr8,264)
	
	mov     gr0,gr8
	ret
.Lend1:
	.size	EXT(setjmp),.Lend1-EXT(setjmp)

	.global	EXT(longjmp)
	.type	EXT(longjmp),@function
EXT(longjmp):
	lddi	@(gr8,0), gr16
	lddi	@(gr8,8), gr18
	lddi 	@(gr8,16), gr20
	lddi	@(gr8,24), gr22
	lddi	@(gr8,32), gr24
	lddi	@(gr8,40), gr26
	lddi	@(gr8,48), gr28
	lddi	@(gr8,56), gr30
#if __FRV_GPR__ != 32
	lddi	@(gr8,64), gr48
	lddi	@(gr8,72), gr50
	lddi	@(gr8,80), gr52
	lddi	@(gr8,88), gr54
	lddi	@(gr8,96), gr56
	lddi	@(gr8,104), gr58
	lddi	@(gr8,112), gr60
	lddi	@(gr8,120), gr62
#endif

#if __FRV_FPR__ != 0
	lddfi	@(gr8,128), fr16
	lddfi	@(gr8,136), fr18
	lddfi 	@(gr8,144), fr20
	lddfi	@(gr8,152), fr22
	lddfi	@(gr8,160), fr24
	lddfi	@(gr8,168), fr26
	lddfi	@(gr8,176), fr28
	lddfi	@(gr8,184), fr30
#if __FRV_FPR__ != 32
	lddfi	@(gr8,192), fr48
	lddfi	@(gr8,200), fr50
	lddfi	@(gr8,208), fr52
	lddfi	@(gr8,216), fr54
	lddfi	@(gr8,224), fr56
	lddfi	@(gr8,232), fr58
	lddfi	@(gr8,240), fr60
	lddfi	@(gr8,248), fr62
#endif
#endif

        ldi     @(gr8,256), gr4
	movgs   gr4,lr

        ldi     @(gr8,260), sp
        ldi     @(gr8,264), fp
	
# Value to return is in r9.  If zero, return 1
	cmp	gr9, gr0, icc0
	setlos	#1, gr8
	ckne	icc0, cc4
	cmov	gr9, gr8, cc4, 1
	ret
.Lend2:
	.size	EXT(longjmp),.Lend2-EXT(longjmp2)
