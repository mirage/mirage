	.file "memchr.S"

	.section .text
	.global _memchr
	.type	 _memchr,@function
_memchr:
	movm [d2,d3,a2,a3],(sp)
.Lend_of_prologue:
	mov d0,a0
	mov d1,d2
	mov (28,sp),a1
#ifndef __OPTIMIZE_SIZE__
	cmp 3,a1
	bls .L44
	mov a0,d3
	btst 3,d3
	bne .L44
	mov a0,a2
	mov 0,a3
	clr d1
	setlb
	mov a3,d0
	asl 8,d0
	mov d2,a3
	add d0,a3
	inc d1
	cmp 3,d1
	lls
	cmp 3,a1
	bls .L48
.L33:
	mov (a2),d0
	mov a3,d3
	xor d3,d0
	mov d0,d1
	not d1
	add -16843009,d0
	and d1,d0
	btst -2139062144,d0
	beq .L34
	mov a2,a0
	clr d1
	setlb
	movbu (a0),d0
	cmp d2,d0
	beq .Lepilogue
	inc a0
	inc d1
	cmp 3,d1
	lls
.L34:
	add -4,a1
	inc4 a2
	cmp 3,a1
	bhi .L33
.L48:
	mov a2,a0
.L44:
#endif
	cmp 0,a1
	beq .L50
	setlb
	movbu (a0),d0
	cmp d2,d0
	beq .Lepilogue
	inc a0
	sub 1,a1  
	lne
.L50:
	mov 0,a0
.Lepilogue:
	ret [d2,d3,a2,a3],16
.Lend_of_memchr:
	.size	 _memchr, .Lend_of_memchr - _memchr

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
	.4byte	 _memchr			# FDE initial location
	.4byte	 .Lend_of_memchr - _memchr	# FDE address range
	.byte	 0x4				# DW_CFA_advance_loc4
	.4byte	 .Lend_of_prologue - _memchr
	.byte	 0xe				# DW_CFA_def_cfa_offset
	.uleb128 0x4
	.byte	 0x87				# DW_CFA_offset, column 0x7
	.uleb128 0x1
	.align 2
.Lend_of_FDE:
