	.file "memcpy.S"

	.section .text
	.global _memcpy
	.type	 _memcpy,@function
_memcpy:
	movm [d2,d3,a2,a3],(sp)
.Lend_of_prologue:
	mov d0,d2
	mov d1,a0
	mov d2,a1
	mov (28,sp),d1
#ifndef __OPTIMIZE_SIZE__
	mov a0,d0
	or d2,d0
	btst 3,d0
	bne .L37
	cmp 15,d1
	bls .L34
	setlb
	mov (a0),d0
	mov d0,(a1)
	inc4 a0
	inc4 a1
	mov (a0),d0
	mov d0,(a1)
	inc4 a0
	inc4 a1
	mov (a0),d0
	mov d0,(a1)
	inc4 a0
	inc4 a1
	mov (a0),d0
	mov d0,(a1)
	inc4 a0
	inc4 a1
	add -16,d1
	cmp 15,d1
	lhi
.L34:
	cmp 3,d1
	bls .L37
	setlb
	mov (a0),d0
	mov d0,(a1)
	inc4 a0
	inc4 a1
	add -4,d1
	cmp 3,d1
	lhi
.L37:
#endif
	cmp 0,d1
	beq .L36
	setlb
	movbu (a0),d0
	movbu d0,(a1)
	inc a0
	inc a1
	sub 1,d1
	lne
.L36:
	mov d2,a0
.Lepilogue:
	ret [d2,d3,a2,a3],16
.Lend_of_memcpy:
	.size	 _memcpy, .Lend_of_memcpy - _memcpy

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
	.4byte	 _memcpy			# FDE initial location
	.4byte	 .Lend_of_memcpy - _memcpy	# FDE address range
	.byte	 0x4				# DW_CFA_advance_loc4
	.4byte	 .Lend_of_prologue - _memcpy
	.byte	 0xe				# DW_CFA_def_cfa_offset
	.uleb128 0x4
	.byte	 0x87				# DW_CFA_offset, column 0x7
	.uleb128 0x1
	.align 2
.Lend_of_FDE:
