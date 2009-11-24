	.file	"strcmp.S"

	.section .text
	.global _strcmp
	.type	 _strcmp,@function
_strcmp:
	movm [d2,d3,a2,a3],(sp)
.Lend_of_prologue:
	mov d0,a0
	mov d1,a1
#ifndef __OPTIMIZE_SIZE__
	or d1,d0
	btst 3,d0
	bne .L11
	mov (a0),d1
	mov (a1),d0
	cmp d0,d1
	bne .L11
	mov -16843009,d3
	setlb
	mov (a0),d0
	mov d3,d1
	add d0,d1
	not d0
	and d0,d1
	and -2139062144,d1
	beq .L6
	clr d0
	jmp .Lepilogue
.L6:
	inc4 a0
	inc4 a1
	mov (a0),d1
	mov (a1),d0
	cmp d0,d1
	leq
.L11:
#endif
	setlb
	movbu (a1),d2
	movbu (a0),d0
	cmp 0,d0
	beq .L9
	cmp d2,d0
	bne .L9
	inc a0
	inc a1
	lra
.L9:
	sub d2,d0
.Lepilogue:
	ret [d2,d3,a2,a3],16
.Lend_of_strcmp:
	.size	 _strcmp, .Lend_of_strcmp - _strcmp

	.section	.debug_frame,"",@progbits
.Lstart_of_debug_frame:
	# Common Information Entry (CIE)
	.4byte	.Lend_of_CIE - .Lstart_of_CIE	# CIE Length
.Lstart_of_CIE:
	.4byte	 0xffffffff			# CIE Identifier Tag
	.byte	 0x1				# CIE Version
	.ascii   "\0"				# CIE Augmentation
	.uleb128 0x1				# CIE Code Alignment Factor
	.sleb128 -4				# CIE Data Alignment Factor
	.byte	 0x32				# CIE RA Column
	.byte	 0xc				# DW_CFA_def_cfa
	.uleb128 0x9
	.uleb128 0x0
	.byte	 0xb2				# DW_CFA_offset, column 0x32
	.uleb128 0x0
	.align   2
.Lend_of_CIE:
	
	# Frame Description Entry (FDE)
	.4byte	.Lend_of_FDE - .Lstart_of_FDE	# FDE Length
.Lstart_of_FDE:
	.4byte	 .Lstart_of_debug_frame		# FDE CIE offset
	.4byte	 _strcmp			# FDE initial location
	.4byte	 .Lend_of_strcmp - _strcmp	# FDE address range
	.byte	 0x4				# DW_CFA_advance_loc4
	.4byte	 .Lend_of_prologue - _strcmp
	.byte	 0xe				# DW_CFA_def_cfa_offset
	.uleb128 0x4
	.byte	 0x87				# DW_CFA_offset, column 0x7
	.uleb128 0x1
	.align 2
.Lend_of_FDE:
