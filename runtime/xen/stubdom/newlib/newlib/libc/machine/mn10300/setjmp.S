	.file "setjmp.S"

	.section .text
	.align 1
	.global _setjmp
#ifdef __AM33__
#ifdef __AM33_2__
	.am33_2
#else
	.am33
#endif
#endif
_setjmp:
        mov d0,a0
        mov d2,(0,a0)
        mov d3,(4,a0)
	mov mdr,d1
	mov d1,(8,a0)
        mov a2,(12,a0)
        mov a3,(16,a0)
	mov sp,a1
	mov a1,(20,a0)
#ifdef __AM33__
	add 24,a0
	mov r4,(a0+)
	mov r5,(a0+)
	mov r6,(a0+)
	mov r7,(a0+)
#ifdef __AM33_2__
	fmov fs4,(a0+)
	fmov fs5,(a0+)
	fmov fs6,(a0+)
	fmov fs7,(a0+)
	fmov fs8,(a0+)
	fmov fs9,(a0+)
	fmov fs10,(a0+)
	fmov fs11,(a0+)
	fmov fs12,(a0+)
	fmov fs13,(a0+)
	fmov fs14,(a0+)
	fmov fs15,(a0+)
	fmov fs16,(a0+)
	fmov fs17,(a0+)
	fmov fs18,(a0+)
	fmov fs19,(a0+)
#endif
#endif
        sub d0,d0
	rets

	.global _longjmp
_longjmp:
	mov d0,a0
	mov (8,a0),d2
	mov d2,mdr
        mov (0,a0),d2
        mov (4,a0),d3
        mov (12,a0),a2
        mov (16,a0),a3
	mov (20,a0),a1
	mov a1,sp
#ifdef __AM33__
	add 24,a0
	mov (a0+),r4
	mov (a0+),r5
	mov (a0+),r6
	mov (a0+),r7
#ifdef __AM33_2__
	fmov (a0+),fs4
	fmov (a0+),fs5
	fmov (a0+),fs6
	fmov (a0+),fs7
	fmov (a0+),fs8
	fmov (a0+),fs9
	fmov (a0+),fs10
	fmov (a0+),fs11
	fmov (a0+),fs12
	fmov (a0+),fs13
	fmov (a0+),fs14
	fmov (a0+),fs15
	fmov (a0+),fs16
	fmov (a0+),fs17
	fmov (a0+),fs18
	fmov (a0+),fs19
#endif
#endif
	cmp 0,d1
	bne L1
	mov 1,d1
L1: 
	mov d1,d0
	retf [],0
