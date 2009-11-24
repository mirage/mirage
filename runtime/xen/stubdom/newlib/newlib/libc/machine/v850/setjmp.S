	.file "setjmp.S"

	.section .text
	.align 1
	.global _setjmp
_setjmp:
	st.w r1,0[r6]
	st.w r3,4[r6]
	st.w r4,8[r6]
	st.w r20,12[r6]
	st.w r21,16[r6]
	st.w r22,20[r6]
	st.w r23,24[r6]
	st.w r24,28[r6]
	st.w r25,32[r6]
	st.w r26,36[r6]
	st.w r27,40[r6]
	st.w r28,44[r6]
	st.w r29,48[r6]
	st.w r30,52[r6]
	st.w r31,56[r6]
	mov r0, r10
	jmp [r31]

	.global _longjmp
_longjmp:
	ld.w 0[r6],r1
	ld.w 4[r6],r3
	ld.w 8[r6],r4
	ld.w 12[r6],r20
	ld.w 16[r6],r21
	ld.w 20[r6],r22
	ld.w 24[r6],r23
	ld.w 28[r6],r24
	ld.w 32[r6],r25
	ld.w 36[r6],r26
	ld.w 40[r6],r27
	ld.w 44[r6],r28
	ld.w 48[r6],r29
	ld.w 52[r6],r30
	ld.w 56[r6],r31
	cmp r7, r0
	jne 1f
	mov 1,r7
1:
	mov r7, r10
	jmp [r31]
