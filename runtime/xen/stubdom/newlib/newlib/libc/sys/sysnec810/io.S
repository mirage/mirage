#	V800 Series Assembler Source File created by cxx732 
	.data
	.sdata
	.bss
	.sbss
	.text
	#@(#)V800 Series Assembly Code Improver E1.50c [16 Jul 93]
	#@(#)V800 Series Assembly Code Generator E1.00f'[25 Nov 93]
	#@(#)V800 Series Optic Optimizer E1.00e [13 Jul 93]
	#@(#)optimized at Wed May 11 13:37:07 1994
	#@(#)option:_R_xcedfgbhjqkn___s____T:
	#@(#)V800 Series Optic Inliner E1.00c [14 Jul 93]
	#@(#)V800 Series Optic Merger E1.00b [15 Jul 93]
	#@(#)V800 Series Optimizing C Compiler Frontend E1.00j [26 Feb 94]
	.file	"/sethra/death/sef/v810/devo/newlib/libc/sys/v810/io.c"
	#@(#) fsort : -N8192 -G512 -C1024 -q -e -a -d 
	.align	4
	.frame	__inb, .F2
	.globl	__inb
__inb:
	add	-.F2, sp
	in.b	[r6],r10
	andi	0xff, r10, r10
	add	.F2, sp
	jmp	[lp]
	.set	.F2, 0x8
	.set	.A2, 0x4
	.set	.T2, 0x0
	.align	4
	.frame	__outb, .F3
	.globl	__outb
__outb:
	andi	0xff, r7, r10
	out.b	r10,[r6]
	jmp	[lp]
	.set	.F3, 0x0
	.set	.A3, 0x0
	.set	.T3, 0x0
	.vline
	.vdebug
	.vdbstrtab
