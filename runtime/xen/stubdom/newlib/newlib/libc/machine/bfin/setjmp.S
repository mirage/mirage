/*
 * setjmp for the Blackfin processor
 *
 * Copyright (C) 2006 Analog Devices, Inc.
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


#define _ASM
#define _SETJMP_H

.text;
.align 4;
.globl _setjmp;
.type _setjmp, STT_FUNC;

_setjmp:
	[--SP] = P0;		/* Save P0 */
	P0 = R0;
	R0 = [SP++];	
	[P0 + 0x00] = R0;	/* Save saved P0 */
	[P0 + 0x04] = P1;
	[P0 + 0x08] = P2;
	[P0 + 0x0C] = P3;
	[P0 + 0x10] = P4;
	[P0 + 0x14] = P5;

	[P0 + 0x18] = FP;	/* Frame Pointer */
	[P0 + 0x1C] = SP;	/* Stack Pointer */

	[P0 + 0x20] = P0;	/* Data Registers */
	[P0 + 0x24] = R1;
	[P0 + 0x28] = R2;
	[P0 + 0x2C] = R3;
	[P0 + 0x30] = R4;
	[P0 + 0x34] = R5;
	[P0 + 0x38] = R6;
	[P0 + 0x3C] = R7;

	R0 = ASTAT;
	[P0 + 0x40] = R0;

	R0 = LC0;		/* Loop Counters */
	[P0 + 0x44] = R0;
	R0 = LC1;
	[P0 + 0x48] = R0;

	R0 = A0.W;		/* Accumulators */
	[P0 + 0x4C] = R0;
	R0 = A0.X;
	[P0 + 0x50] = R0;
	R0 = A1.W;
	[P0 + 0x54] = R0;
	R0 = A1.X;
	[P0 + 0x58] = R0;

	R0 = I0;		/* Index Registers */
	[P0 + 0x5C] = R0;
	R0 = I1;
	[P0 + 0x60] = R0;
	R0 = I2;
	[P0 + 0x64] = R0;
	R0 = I3;
	[P0 + 0x68] = R0;

	R0 = M0;		/* Modifier Registers */
	[P0 + 0x6C] = R0;
	R0 = M1;
	[P0 + 0x70] = R0;
	R0 = M2;
	[P0 + 0x74] = R0;
	R0 = M3;
	[P0 + 0x78] = R0;

	R0 = L0;		/* Length Registers */
	[P0 + 0x7c] = R0;
	R0 = L1;
	[P0 + 0x80] = R0;
	R0 = L2;
	[P0 + 0x84] = R0;
	R0 = L3;
	[P0 + 0x88] = R0;

	R0 = B0;		/* Base Registers */
	[P0 + 0x8C] = R0;
	R0 = B1;
	[P0 + 0x90] = R0;
	R0 = B2;
	[P0 + 0x94] = R0;
	R0 = B3;
	[P0 + 0x98] = R0;

	R0 = RETS;
	[P0 + 0x9C] = R0;

	R0 = 0;

	RTS;
.size _setjmp, .-_setjmp;
