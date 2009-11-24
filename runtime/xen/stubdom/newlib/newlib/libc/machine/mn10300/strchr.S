	.file "strchr.S"

	.section .text
	.global _strchr
	.type	 _strchr,@function
_strchr:
	movm [d2,d3,a2,a3],(sp)
	add -12,sp
.Lend_of_prologue:
	mov d0,a1
	movbu d1,(7,sp)
#ifndef __OPTIMIZE_SIZE__
	btst 3,d0
	bne .L20
	clr d0
	setlb
	mov sp,a2
	mov d0,d3
	add d3,a2
	mov a2,a0
	add 12,a0
	movbu (7,sp),d3
	movbu d3,(-4,a0)
	inc d0
	cmp 3,d0
	lls
	mov a1,a0
	mov -16843009,a1
	mov (a0),d2
	mov a1,d1
	add d2,d1
	mov d2,d0
	not d0
	and d0,d1
	mov -2139062144,d3
	mov d3,(0,sp)
	btst -2139062144,d1
	bne .L27
	jmp .L38
.L28:
	inc4 a0
	mov (a0),d2
	mov a1,d1
	add d2,d1
	mov d2,d0
	not d0
	and d0,d1
	mov (0,sp),d3
	and d3,d1
	bne .L27
.L38:
	mov (8,sp),d0
	xor d2,d0
	mov a1,d1
	add d0,d1
	not d0
	and d0,d1
	and d3,d1
	beq .L28
.L27:
	mov a0,a1
.L20:
#endif
	movbu (a1),d0
	cmp 0,d0
	beq .L32
	movbu (7,sp),d1
	setlb
	cmp d1,d0
	beq .L36
	inc a1
	movbu (a1),d0
	cmp 0,d0
	lne
.L32:
	movbu (7,sp),d0
	movbu (a1),d3
	cmp d0,d3
	beq .L36
	mov 0,a0
	jmp .Lepilogue
.L36:
	mov a1,a0
.Lepilogue:
	ret [d2,d3,a2,a3],28
.Lend_of_strchr:
	.size	 _strchr, .Lend_of_strchr - _strchr

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
	.4byte	 _strchr			# FDE initial location
	.4byte	 .Lend_of_strchr - _strchr	# FDE address range
	.byte	 0x4				# DW_CFA_advance_loc4
	.4byte	 .Lend_of_prologue - _strchr
	.byte	 0xe				# DW_CFA_def_cfa_offset
	.uleb128 0x4
	.byte	 0x87				# DW_CFA_offset, column 0x7
	.uleb128 0x1
	.align 2
.Lend_of_FDE:
