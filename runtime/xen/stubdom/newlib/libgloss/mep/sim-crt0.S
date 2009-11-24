# Copyright (c) 2003  Red Hat, Inc. All rights reserved.
#
# This copyrighted material is made available to anyone wishing to use, modify,
# copy, or redistribute it subject to the terms and conditions of the BSD 
# License.   This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY expressed or implied, including the implied 
# warranties of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  A copy of
# this license is available at http://www.opensource.org/licenses. Any Red Hat 
# trademarks that are incorporated in the source code or documentation are not
# subject to the BSD License and may only be used or replicated with the express
# permission of Red Hat, Inc.
#
# Toshiba Media Processor startup file (crt0.S)
#
# Designed for user programs running in the 0-2Mb startup section.
# Designed for the simulator by default.
#
# Exception/Interrupt Handler Locations	
# CFG.EVM  CFG.EVA  CFG.IVA   Exception     INTn
## 0         -        -        0x0000_0000  0x0000_0030 rom
## 1         0        0        0x0020_0000  0x0020_0030 local RAM / local RAM
## 1         1        0        0x0080_0000  0x0020_0000 ext RAM / local RAM
## 1         0        1        0x0020_0000  0x0080_0000 local RAM / ext RAM
## 1         1        1        0x0080_0000  0x0080_0030 ext RAM / ext RAM
#
# Exceptions		
# Reset 0x0000_0000
# NMI	0x0000_0000+4
# RI	(Base Address) +0x08
# ZDIV	(Base Address) +0x0C
# BRK	(Base Address) +0x10
# SWI	(Base Address) +0x14
# DSP	(Base Address) +0x1C
# COP	(Base Address) +0x20

	.set _local_ram_base, 0x00200000
	.set _ext_ram_base, 0x00800000
	.set _int_base_offset, 0x30

#include "syscall.h"

.macro  if_bitfield_zero reg, start, length, label
	ldc	$0, \reg
	srl	$0, \start
	and3	$0, $0, (1 << \length) - 1
	beqz	$0,\label
.endm

.macro  if_bitfield_notN reg, start, length, N, label
	ldc	$0, \reg
	srl	$0, \start
	and3	$0, $0, (1 << \length) - 1
	bnei	$0,\N, \label
.endm
	
.macro  if_bitfield_eqN reg, start, length, N, label
	ldc	$0, \reg
	srl	$0, \start
	and3	$0, $0, (1 << \length) - 1
	beqi	$0,\N, \label
.endm

.macro  if_bitfield_ltN reg, start, length, N, label
	ldc	$0, \reg
	srl	$0, \start
	and3	$0, $0, (1 << \length) - 1
	blti	$0,\N, \label
.endm

	.section  .hwinit, "ax"
	# CCFG.ICSZ
	if_bitfield_zero reg=$ccfg, start=16, length=7, label=.Lend_enable_icache
__enable_icache:
	# set ICE(cfg[1])
	ldc	$1,$cfg
	or3	$1,$1,2
	stc	$1,$cfg
	nop
	nop
	nop
	nop
	nop
.Lend_enable_icache:
	ret

__enable_dcache:
	# CCFG.DCSZ
	if_bitfield_zero reg=$ccfg, start=0, length=7, label=.Lend_enable_dcache
	# set DCE(cfg[0])
	ldc	$1,$cfg
	or3	$1,$1,1
	stc	$1,$cfg
	nop
	nop
	nop
	nop
	nop
	ret
.Lend_enable_dcache:		

	.text

#ifdef NOVEC
	.global	_reset
_reset:
#endif

	.global	_start
_start:
	mov	$fp, 0			# for unwinding

	# $sp set
	movh	$sp, %uhi(__stack_table)
	or3	$sp, $sp, %lo(__stack_table)

#ifndef NOVEC
	# copy exception vector table

	# RCFG.IRSZ
	if_bitfield_zero reg=$rcfg, start=16, length=7, label=.Lend_ev_imem
	# handle imem
	movh	$11,%uhi(_local_ram_base)
	or3	$11,$11,%lo(_local_ram_base)
	# clear CFG.EVA ([23])
	ldc	$0,$cfg
	movh	$1, %uhi(0xff7fffff)
	or3	$1, $1, %lo(0xff7fffff)
	and	$0,$1
	stc	$0,$cfg
	bra	.Ldo_repeat_ev
.Lend_ev_imem:	
#ifdef     UseSDRAM
	movh	$11,%uhi(_ext_ram_base)
	or3	$11,$11,%lo(_ext_ram_base)
	# set CFG.EVA ([23])
	ldc	$0,$cfg
	movh	$1,%uhi(1<<23)
	or3	$1,$1,%lo(1<<23)
	or	$0,$1
	stc	$0,$cfg
#else
	# handle ROM
	bra     .Lend_ev
#endif
.Ldo_repeat_ev:	
	# set CFG.EVM ([4])
	ldc	$0,$cfg
	or3	$0,$0,(1<<4)
	stc	$0,$cfg
	# copy _exception_table to $11
	movh	$12,%uhi(_exception_table)
	or3	$12,$12,%lo(_exception_table)
	mov	$13,8
	repeat	$13,.Lrepeat_ev
	lw	$1,0($12)
	add	$12,4
.Lrepeat_ev:
	sw	$1,0($11)
	add	$11,4
.Lend_ev:	

	# copy interrupt vector table
	# RCFG.IRSZ
	if_bitfield_zero reg=$rcfg, start=16, length=7, label=.Lend_iv_imem
	# handle imem
	movh	$11,%uhi(_local_ram_base)
	or3	$11,$11,%lo(_int_base_offset)
	# clear CFG.IVA ([22])
	ldc	$0,$cfg
	movh	$1,%uhi(0xffbfffff)  # ~(1<<22)
	or3	$1,$1,%lo(0xffbfffff)
	and	$0,$1
	stc	$0,$cfg
	bra	.Ldo_repeat_iv
.Lend_iv_imem:	
#ifdef UseSDRAM
	movh	$11,%uhi(_ext_ram_base)
	or3	$11,$11,%lo(_int_base_offset)
	# set CFG. IVA ([22])
	ldc	$0,$cfg
	movh	$1,%uhi(1<<22)
	or3	$1,$1,%lo(1<<22)
	or	$0,$1
	stc	$0,$cfg
#else
	# handle ROM
	bra     .Lend_iv
#endif
.Ldo_repeat_iv:
	# set CFG.IVM ([3])
	ldc	$0,$cfg
	or3	$0,$0,(1<<3)
	stc	$0,$cfg
	# copy _interrupt_table to $11
	movh	$12,%uhi(_interrupt_table)
	or3	$12,$12,%lo(_interrupt_table)
	mov	$13,32
	add	$13,-1
	and3	$13,$13,127
	repeat	$13,.Lrepeat_iv
	lw	$1,0($12)
	add	$12,4
.Lrepeat_iv:
	sw	$1,0($11)
	add	$11,4
.Lend_iv:	

	# initialize instruction cache
	# Icache Size CCFG.ICSZ ([22..16]) KByte
	if_bitfield_zero reg=$ccfg, start=16, length=7, label=.Lend_ic
	mov	$3,$0			# cache size in KB
	# ID.ID
	if_bitfield_ltN reg=$ID, start=8, length=8, N=3, label=.Lend_mepc3_ic
	# Line Size CCFG.ICSZ ([26..24]) Byte
	if_bitfield_ltN reg=$ccfg, start=24, length=3, N=2, label=.Lend_ic
	bgei	$0,5,.Lend_ic

	add3	$1,$0,3			# bit width of line size
	mov	$0,$3
	# clear tag
	mov	$2,10
	sub	$2,$1
	sll	$0,$2			# *KByte/(line size)	
	add	$0,-1
	mov	$2,1
	sll	$2,$1			# line size
	bra	.Ldo_repeat_icache
.Lend_mepc3_ic:
	# ICache: $0 KByte
	mov	$0,$3
	# clear tag
	sll	$0,(10-5)		# *KByte/(32byte=linesize)
	add	$0,-1
	mov	$2,32
.Ldo_repeat_icache:	
	mov	$1,0
	bra	0f
	# Align this code on an 8 byte boundary in order to keep the repeat
	# loop entirely within the instruction fetch buffer.
	.p2align 3
0:
	movh	$3,%hi(0x00310000)	# for tag
	repeat	$0,.Lrepeat_icache
	add	$0,-1
.Lrepeat_icache:
	sw	$1,0($3)
	add3	$3,$3,$2
.Lenable_icache:
	movh	$1,%hi(__enable_icache)
	add3	$1,$1,%lo(__enable_icache)
	jsr	$1
.Lend_ic:

	# initialize data cache
	# Dcache Size CCFG.DCSZ ([6..0]) KByte
	if_bitfield_zero reg=$ccfg, start=0, length=7, label=.Lend_dc
	mov	$3,$0			# cache size in KB
	# ID.ID
	if_bitfield_ltN reg=$ID, start=8, length=8, N=3, label=.Lend_mepc3_dc
	# Line Size CCFG.DCSZ ([10..8]) Byte
	if_bitfield_ltN reg=$ccfg, start=8, length=3, N=2, label=.Lend_dc
	bgei	$0,5,.Lend_dc

	add3	$1,$0,3			# bit width of line size
	mov	$0,$3
	# clear tag
	mov	$2,10
	sub	$2,$1
	sll	$0,$2			# *KByte/(line size)	
	add	$0,-1
	mov	$2,1
	sll	$2,$1			# line size
	bra	.Ldo_repeat_dcache
.Lend_mepc3_dc:	
	# DCache: $0 KByte
	mov	$0,$3
	# clear tag
	sll	$0,(10-5)		# *KByte/(32byte=linesize)
	add	$0,-1
	mov	$2,32
.Ldo_repeat_dcache:
	mov	$1,0
	movh	$3,%hi(0x00330000)		# for tag

	repeat	$0,.Lrepeat_dcache
	add	$0,-1
.Lrepeat_dcache:
	sw	$1,0($3)
	add3	$3,$3,$2
.Lenable_dcache:
	movh	$1,%hi(__enable_dcache)
	add3	$1,$1,%lo(__enable_dcache)
	jsr		$1
.Lend_dc:	
	# NOVEC	
#endif
	# initialize sp, gp, tp
	# get CPU ID
	ldc	$0, $id
	srl	$0, 16

	# load ID-specific stack pointer	
	sl2ad3	$0, $0, $sp              # $0 = ($0 << 2) + $sp
	lw	$sp,($0)                 # $sp = *($0)
	mov	$0, 0
	
	movh	$gp, %uhi(__sdabase)
	or3	$gp, $gp, %lo(__sdabase)

	movh	$tp, %uhi(__tpbase)
	or3	$tp, $tp, %lo(__tpbase)

	# zero out BSS
	movh	$1, %uhi(__bss_start)
	or3	$1, $1, %lo(__bss_start)
	mov	$2, 0
	movh	$3, %uhi(_end)
	or3	$3, $3, %lo(_end)
	sub	$3, $1
	bsr	memset

	movh	$1, %uhi(__sbss_start)
	or3	$1, $1, %lo(__sbss_start)
	mov	$2, 0
	movh	$3, %uhi(__sbss_end)
	or3	$3, $3, %lo(__sbss_end)
	sub	$3, $1
	bsr	memset

	movh	$1, %uhi(__farbss_start)
	or3	$1, $1, %lo(__farbss_start)
	mov	$2, 0
	movh	$3, %uhi(__farbss_end)
	or3	$3, $3, %lo(__farbss_end)
	sub	$3, $1
	bsr	memset

    # enable interrupts
    ei

    # construct global class variables
	bsr	__invoke_init_section

    # invoke main
	mov	$1, 0			# argc, argv, envp
	mov	$2, 0
	mov	$3, 0
	bsr	main
	mov	$1, $0
	bsr	exit

	.global	_exit
_exit:
	# Prevent _exit recursion
	movh	$3, %uhi(_exit_in_progress)
	or3	$3, $3, %lo(_exit_in_progress)
	lw	$5, ($3)
	bnez	$5, _skip_fini
	mov	$5, 1	
	sw	$5, ($3)
	
	# We don't need to preserve $5 because we're going to exit anyway.
	mov	$5,$1

    # destruct global class variables
	bsr	__invoke_fini_section
	mov	$1,$5

_skip_fini:

#ifdef NOSIM
_exit_loop:
	bra	_exit_loop
#else
	.2byte 0x7800 | ((SYS_exit & 0xe) << 7) | ((SYS_exit & 1) << 4)
	ret
#endif

	.data
_exit_in_progress:	.word 0

		
	
# For these two, the epilogue is in crtn.S

	.section	.init
__invoke_init_section:
	add	$sp, -4
	ldc	$0, $lp
	sw	$0, ($sp)

	.section .fini
__invoke_fini_section:
	add	$sp, -4
	ldc	$0, $lp
	sw	$0, ($sp)

#ifndef NOVEC
        .section .vec, "ax"
        .core
        .org 0x0, 0
    .global _exception_table
.type   _exception_table,@function	
_exception_table:	
	.p2align 2
    .org 0x0000, 0
	.global _reset
_reset:
        jmp  _handler_RESET
    .org 0x0004, 0
        jmp  _handler_NMI
    .org 0x0008, 0
        jmp  _handler_RI
    .org 0x000c, 0
        jmp  _handler_ZDIV
    .org 0x0010, 0
        jmp  _handler_BRK
    .org 0x0014, 0
        jmp  _handler_SWI
    .org 0x0018, 0
        jmp  _handler_DEBUG
    .org 0x001c, 0
        jmp  _handler_DSP
    .org 0x0020, 0
        jmp  _handler_COP

        .org 0x30, 0
	.global	_interrupt_table
.type   _interrupt_table,@function	
_interrupt_table:		
    .org 0x0030
        jmp  _handler_INT0
    .org 0x0034
        jmp  _handler_INT1
    .org 0x0038
        jmp  _handler_INT2
    .org 0x003c
        jmp  _handler_INT3
    .org 0x0040
        jmp  _handler_INT4
    .org 0x0044
        jmp  _handler_INT5
    .org 0x0048
        jmp  _handler_INT6
    .org 0x004c
        jmp  _handler_INT7
    .org 0x0050
        jmp  _handler_INT8
    .org 0x0054
        jmp  _handler_INT9
    .org 0x0058
        jmp  _handler_INT10
    .org 0x005c
        jmp  _handler_INT11
    .org 0x0060
        jmp  _handler_INT12
    .org 0x0064
        jmp  _handler_INT13
    .org 0x0068
        jmp  _handler_INT14
    .org 0x006c
        jmp  _handler_INT15
    .org 0x0070
        jmp  _handler_INT16
    .org 0x0074
        jmp  _handler_INT17
    .org 0x0078
        jmp  _handler_INT18
    .org 0x007c
        jmp  _handler_INT19
    .org 0x0080
        jmp  _handler_INT20
    .org 0x0084
        jmp  _handler_INT21
    .org 0x0088
        jmp  _handler_INT22
    .org 0x008c
        jmp  _handler_INT23
    .org 0x0090
        jmp  _handler_INT24
    .org 0x0094
        jmp  _handler_INT25
    .org 0x0098
        jmp  _handler_INT26
    .org 0x009c
        jmp  _handler_INT27
    .org 0x00a0
        jmp  _handler_INT28
    .org 0x00a4
        jmp  _handler_INT29
    .org 0x00a8
        jmp  _handler_INT30
    .org 0x00ac
        jmp  _handler_INT31
	# NOVEC	
#endif
