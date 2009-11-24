	.file "memset.S"

	.section .text
	.global  _memset
	.type	 _memset,@function
_memset:
	movm  [d2,d3,a2,a3], (sp)
.Lend_of_prologue:
	mov   d0, d3
	mov   d1, d2
	mov   (28, sp),a1
	mov   d3, a0
#ifndef __OPTIMIZE_SIZE__
	cmp   3, a1
	bls   .L41
	btst  3, d3
	bne   .L41
	extbu d2
	mov   d2, d1
	asl   8, d1
	or    d2, d1
	mov   d1, d0
	asl   16, d0
	or    d0, d1
	cmp   15, a1
	bls   .L36
	setlb
	mov   d1, (a0)
	inc4  a0
	mov   d1, (a0)
	inc4  a0
	mov   d1, (a0)
	inc4  a0
	mov   d1, (a0)
	inc4  a0
	add  -16, a1
	cmp   15, a1
	lhi
.L36:
	cmp   3, a1
	bls   .L41
	setlb
	mov   d1, (a0)
	inc4  a0
	add   -4, a1
	cmp   3, a1
	lhi
.L41:
#endif
	cmp   0, a1
	beq   .Lepilogue
	setlb
	movbu d2, (a0)
	inc   a0
	sub   1, a1
	lne
	mov d3,a0
.Lepilogue:
	ret [d2,d3,a2,a3], 16
.Lend_of_memset:
	.size	 _memset, .Lend_of_memset - _memset

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
	.4byte	 _memset			# FDE initial location
	.4byte	 .Lend_of_memset - _memset	# FDE address range
	.byte	 0x4				# DW_CFA_advance_loc4
	.4byte	 .Lend_of_prologue - _memset
	.byte	 0xe				# DW_CFA_def_cfa_offset
	.uleb128 0x4
	.byte	 0x87				# DW_CFA_offset, column 0x7
	.uleb128 0x1
	.align 2
.Lend_of_FDE:
