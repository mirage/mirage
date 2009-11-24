	.text
	.global	_start
	.type	_start,@function
	.stabs	"crt0.S",100,0,0,_start
	.stabs	"int:t(0,1)=r(0,1);-32768;32767;",128,0,0,0
	.stabs	"_start:F(0,1)",36,0,1,_start

_start:

; R14 always contains memory base address (0)

	ldi	r14,0

; Set the USER and SYSTEM stack pointers.

	ldi	r0, 0		; zero arguments
	ldi	r1, 0
	mvtc	r0, psw		; select SPI and set it
	ldi	sp, _stack
	ldi	r10, 0x8000	; select SPU/FP and set it
	mvtc r10, psw || ldi r11, 0;  clear stack frame
	ldi	sp, _stack - 0x200
	ldi	r13, 0

; Clear the BSS.  Do it in two parts for efficiency: longwords first
; for most of it, then the remaining 0 to 3 bytes.

	ldi	r2, __bss_start	; R2 = start of BSS
	ldi	r3, _end	; R3 = end of BSS + 1
	sub	r3, r2		; R3 = BSS size in bytes
	mv	r4, r3
	srli	r4, 2		; R4 = BSS size in longwords (rounded down)
loop1:
	cmpeqi	r4, 0		; more longords to zero out?
	brf0t.s	endloop1	; nope
	st2w	r0, @r2+	; yep, zero out another longword
	subi	r4, 1		; decrement count
	bra.l	loop1		; go do some more

endloop1:
	and3	r4, r3, 3	; get no. of remaining BSS bytes to clear
loop2:
	cmpeqi	r4, 0		; more bytes to zero out?
	brf0t.s	endloop2	; nope
	stb	r0, @r2		; yep, zero out another byte
	addi	r2, 1		; bump address
	subi	r4, 1		; decrement count
	bra.s	loop2		; go do some more
endloop2:
; Call main, then stop simulator
	st r11, @-sp
	st r13, @-sp
	mv r11, sp

	bl	main
	bl	exit
	stop
.Lstart:
	.size	_start,.Lstart-_start
	.stabs	"",36,0,0,.Lstart-_start

	.section .stack
_stack:	.long	1
