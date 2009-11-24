/* The interrupt table.
 *
 * Copyright (c) 2006 CodeSourcery Inc
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */

	.macro SLOT,n,prefix=,suffix=
	.long __\prefix\n\suffix
	.endm

	.macro ISR n
	SLOT \n,interrupt,
	.endm

	.macro TRAP n
	SLOT \n,trap,
	.endm

	.macro FP n
	SLOT \n,fp_,
	.endm

	.macro UNIMP_OPCODE n
	SLOT \n,unimplemented_,_opcode
	.endm

	.macro BREAKPOINT_DEBUG n
	SLOT \n,,_breakpoint_debug_interrupt
	.endm

	.section .interrupt_vector,"a"

	.globl __interrupt_vector
__interrupt_vector:
	
	.long __stack 				/* 0 */
	.long __reset				/* 1 */
	.long __access_error			/* 2 */
	.long __address_error			/* 3 */
	.long __illegal_instruction		/* 4 */
	.long __divide_by_zero			/* 5 */
	ISR 6
	ISR 7
	.long __privilege_violation		/* 8 */
	.long __trace				/* 9 */
	UNIMP_OPCODE line_a			/* 10 */
	UNIMP_OPCODE line_f			/* 11 */
	BREAKPOINT_DEBUG non_pc			/* 12 */
	BREAKPOINT_DEBUG pc			/* 13 */
	.long __format_error			/* 14 */
	.irp N,15,16,17,18,19,20,21,22,23
	ISR \N					/* [15,24) */
	.endr
	.long __spurious_interrupt		/* 24 */
	.irp N,25,26,27,28,29,30,31
	ISR \N					/* [25,32) */
	.endr
	.irp N,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
	TRAP \N					/* [32,48) */
	.endr
	FP branch_unordered			/* 48 */
	FP inexact_result			/* 49 */
	FP divide_by_zero			/* 50 */
	FP underflow				/* 51 */
	FP operand_error			/* 52 */
	FP overflow				/* 53 */
	FP input_not_a_number			/* 54 */
	FP input_denormalized_number		/* 55 */
	.irp N,56,57,58,59,60
	ISR \N					/* [56,61) */
	.endr
	.long __unsupported_instruction		/* 61 */
	.irp N,62,63
	ISR \N					/* [62,64) */
	.endr
	.irp N,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79
	ISR \N			/* [64,80) */
	.endr
	.irp N,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95
	ISR \N			/* [80,96) */
	.endr
	.irp N,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111
	ISR \N			/* [96,112) */
	.endr
	.irp N,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127
	ISR \N			/* [112,128) */
	.endr
	.irp N,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143
	ISR \N			/* [128,144) */
	.endr
	.irp N,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159
	ISR \N			/* [144,160) */
	.endr
	.irp N,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175
	ISR \N			/* [160,176) */
	.endr
	.irp N,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191
	ISR \N			/* [176,192) */
	.endr
	.irp N,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207
	ISR \N			/* [192,208) */
	.endr
	.irp N,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223
	ISR \N			/* [208,224) */
	.endr
	.irp N,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239
	ISR \N			/* [224,240) */
	.endr
	.irp N,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255
	ISR \N			/* [240,256) */
	.endr
