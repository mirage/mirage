/*
 * Done by Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com>
 * This code is mostly taken from FreeBSD.
 *
 ****************************************************************************
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */

#ifndef _IA64_FPU_H_
#define _IA64_FPU_H_

#include "os.h"

/*
 * Floating point status register bits.
 */
#define IA64_FPSR_TRAP_VD	UL_CONST(0x0000000000000001)
#define IA64_FPSR_TRAP_DD	UL_CONST(0x0000000000000002)
#define IA64_FPSR_TRAP_ZD	UL_CONST(0x0000000000000004)
#define IA64_FPSR_TRAP_OD	UL_CONST(0x0000000000000008)
#define IA64_FPSR_TRAP_UD	UL_CONST(0x0000000000000010)
#define IA64_FPSR_TRAP_ID	UL_CONST(0x0000000000000020)
#define IA64_FPSR_SF(i,v)	((v) << ((i)*13+6))

#define IA64_SF_FTZ		UL_CONST(0x0001)
#define IA64_SF_WRE		UL_CONST(0x0002)
#define IA64_SF_PC		UL_CONST(0x000c)
#define IA64_SF_PC_0		UL_CONST(0x0000)
#define IA64_SF_PC_1		UL_CONST(0x0004)
#define IA64_SF_PC_2		UL_CONST(0x0008)
#define IA64_SF_PC_3		UL_CONST(0x000c)
#define IA64_SF_RC		UL_CONST(0x0030)
#define IA64_SF_RC_NEAREST	UL_CONST(0x0000)
#define IA64_SF_RC_NEGINF	UL_CONST(0x0010)
#define IA64_SF_RC_POSINF	UL_CONST(0x0020)
#define IA64_SF_RC_TRUNC	UL_CONST(0x0030)
#define IA64_SF_TD		UL_CONST(0x0040)
#define IA64_SF_V		UL_CONST(0x0080)
#define IA64_SF_D		UL_CONST(0x0100)
#define IA64_SF_Z		UL_CONST(0x0200)
#define IA64_SF_O		UL_CONST(0x0400)
#define IA64_SF_U		UL_CONST(0x0800)
#define IA64_SF_I		UL_CONST(0x1000)

#define IA64_SF_DEFAULT	(IA64_SF_PC_3 | IA64_SF_RC_NEAREST)

#define IA64_FPSR_DEFAULT	(IA64_FPSR_TRAP_VD			\
				 | IA64_FPSR_TRAP_DD			\
				 | IA64_FPSR_TRAP_ZD			\
				 | IA64_FPSR_TRAP_OD			\
				 | IA64_FPSR_TRAP_UD			\
				 | IA64_FPSR_TRAP_ID			\
				 | IA64_FPSR_SF(0, IA64_SF_DEFAULT)	\
				 | IA64_FPSR_SF(1, (IA64_SF_DEFAULT	\
						    | IA64_SF_TD	\
						    | IA64_SF_WRE))	\
				 | IA64_FPSR_SF(2, (IA64_SF_DEFAULT	\
						    | IA64_SF_TD))	\
				 | IA64_FPSR_SF(3, (IA64_SF_DEFAULT	\
						    | IA64_SF_TD)))


#ifndef __ASSEMBLY__

	/* This is from sys/cdefs.h in FreeBSD */
#define __aligned(x)    __attribute__((__aligned__(x)))

	/* A single Floating Point register. */
struct ia64_fpreg
{
	uint8_t	fpr_bits[16];
} __aligned(16);

typedef struct ia64_fpreg ia64_fpreg_t;

#endif /* __ASSEMBLY__ */

#endif /* _IA64_FPU_H_ */
