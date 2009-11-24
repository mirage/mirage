/*
 * longjmp for the Blackfin processor
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
.globl _longjmp;
.type _longjmp, STT_FUNC;
_longjmp:
	P0 = R0;
	R0 = [P0 + 0x00];
	[--SP] = R0;		/* Put P0 on the stack */
	
	P1 = [P0 + 0x04];
	P2 = [P0 + 0x08];
	P3 = [P0 + 0x0C];
	P4 = [P0 + 0x10];
	P5 = [P0 + 0x14];
	
	FP = [P0 + 0x18];
	R0 = [SP++];		/* Grab P0 from old stack */
	SP = [P0 + 0x1C];	/* Update Stack Pointer */
	[--SP] = R0;		/* Put P0 on new stack */
	[--SP] = R1;		/* Put VAL arg on new stack */

	R0 = [P0 + 0x20];	/* Data Registers */
	R1 = [P0 + 0x24];
	R2 = [P0 + 0x28];
	R3 = [P0 + 0x2C];
	R4 = [P0 + 0x30];
	R5 = [P0 + 0x34];
	R6 = [P0 + 0x38];
	R7 = [P0 + 0x3C];

	R0 = [P0 + 0x40];
	ASTAT = R0;

	R0 = [P0 + 0x44];	/* Loop Counters */
	LC0 = R0;
	R0 = [P0 + 0x48];
	LC1 = R0;

	R0 = [P0 + 0x4C];	/* Accumulators */
	A0.W = R0;
	R0 = [P0 + 0x50];
	A0.X = R0;
	R0 = [P0 + 0x54];
	A1.W = R0;
	R0 = [P0 + 0x58];
	A1.X = R0;

	R0 = [P0 + 0x5C];	/* Index Registers */
	I0 = R0;
	R0 = [P0 + 0x60];
	I1 = R0;
	R0 = [P0 + 0x64];
	I2 = R0;
	R0 = [P0 + 0x68];
	I3 = R0;

	R0 = [P0 + 0x6C];	/* Modifier Registers */
	M0 = R0;
	R0 = [P0 + 0x70];
	M1 = R0;
	R0 = [P0 + 0x74];
	M2 = R0;
	R0 = [P0 + 0x78];
	M3 = R0;

	R0 = [P0 + 0x7C];	/* Length Registers */
	L0 = R0;
	R0 = [P0 + 0x80];
	L1 = R0;
	R0 = [P0 + 0x84];
	L2 = R0;
	R0 = [P0 + 0x88];
	L3 = R0;

	R0 = [P0 + 0x8C];	/* Base Registers */
	B0 = R0;
	R0 = [P0 + 0x90];
	B1 = R0;
	R0 = [P0 + 0x94];
	B2 = R0;
	R0 = [P0 + 0x98];
	B3 = R0;

	R0 = [P0 + 0x9C];	/* Return Address (PC) */
	RETS = R0;
	
	R0 = [SP++];
	P0 = [SP++];

	CC = R0 == 0;
	IF !CC JUMP 1f;
	R0 = 1;
1:
	RTS;
.size _longjmp, .-_longjmp;
