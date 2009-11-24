	.file "strlen.S"

	.section .text
	.global _strlen
	.type	 _strlen,@function
_strlen:
	movm [d2,d3,a2,a3],(sp)
.Lend_of_prologue:
	mov d0,a0
	mov a0,a2
#ifndef __OPTIMIZE_SIZE__
	btst 3,d0
	bne .L21
	mov (a0),d0
	mov -16843009,a1
	mov a1,d1
	add d0,d1
	not d0
	and d0,d1
	mov -2139062144,d2
	btst -2139062144,d1
	bne .L21
	setlb
	inc4 a0
	mov (a0),d0
	mov a1,d1
	add d0,d1
	not d0
	and d0,d1
	and d2,d1
	leq
	jmp .L21
#endif
.L19:
	inc a0
.L21:
	movbu (a0),d3
	cmp 0,d3
	bne .L19
	sub a2,a0
	mov a0,d0
.Lepilogue:
	ret [d2,d3,a2,a3],16
.Lend_of_strlen:
	.size	 _strlen, .Lend_of_strlen - _strlen

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
	.4byte	 _strlen			# FDE initial location
	.4byte	 .Lend_of_strlen - _strlen	# FDE address range
	.byte	 0x4				# DW_CFA_advance_loc4
	.4byte	 .Lend_of_prologue - _strlen
	.byte	 0xe				# DW_CFA_def_cfa_offset
	.uleb128 0x4
	.byte	 0x87				# DW_CFA_offset, column 0x7
	.uleb128 0x1
	.align 2
.Lend_of_FDE:
