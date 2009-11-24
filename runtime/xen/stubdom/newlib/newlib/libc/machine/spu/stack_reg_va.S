/*
  Copyright (c) 2007, Toshiba Corporation

  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
    * Neither the names of Toshiba nor the names of its
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.
 */
/*
 * This file contains code use to construct a PIC, spu side, syscall 
 * function with variable parameters in accordance with the CBE ABI.
 *
 * This function is equivalent to constructing a va_list structure and 
 * calling the va_list form of the function. Therefore, for example,
 * a printf function stack frame will look like this:
 *
 *             |   Stack    | high memory
 *             |   Parms    |
 *             |            |
 *             |------------|
 *             |  Link Reg  |
 *             |------------|
 *             | Back Chain |<-----. <---- input SP
 *             |------------|      |
 *             |  Reg 74    |      |
 *             |------------|      |
 *             |  Reg 73    |      |
 *             |------------|      |
 *             //   ...    //      |
 *             |------------|      |
 *             |  Reg  5    |      |
 *             |------------|      |
 *             |  Reg  4    |<--.  |
 *             |------------|   |  |
 *     va_list.| call_stack |------'
 *             |------------|   |   
 *     va_list.|  next_arg  |---'
 *             |------------| 
 *             | format (r3)| <---- start of parameters
 *             |------------|                   |------------|
 *             |    stack   |                   |            |
 *             |    code    |                   |(Back Chain)| <---- output SP
 *             | 1-3 qwords | <---- code_ptr    `------------'
 *             `------------'
 *                            low memory
 *
 * This was written in assembly so that it is smaller than what would
 * be produced by using va_start.
 */

#include "c99ppe.h"

#define parms		$2	/* Number of fixed arguments */

#define offset		$67
#define flag		$68
#define regdec		$69
#define link		$70

#define code_ptr	$71
#define ptr		$72
#define inst		$73
#define tmp		$74

	.text
	.global __stack_reg_va

__stack_reg_va:

	/* Save registers 69-74 explicitly so that we have some
	 * working registers. 
	 */
	stqd	$74, 16*(-1)($sp)
	stqd	$73, 16*(-2)($sp)
	stqd	$72, 16*(-3)($sp)
	stqd	$71, 16*(-4)($sp)
	stqd	$70, 16*(-5)($sp)
	stqd	$69, 16*(-6)($sp)

	/* Construct self-modifying stack code that saves the remaining
	 * volatile registers onto the stack.
	 */
	il	regdec, -1		/* for decrement register value in save instruction */
	shlqbyi	regdec, regdec, 12
	il	tmp, -(SPE_STACK_REGS+2+3)*16
	a	code_ptr, $sp, tmp
	lqr	tmp, save_regs_1	/* store stack code */
	stqd	tmp,  0(code_ptr)
	lqr	inst, save_regs_2
	ai	ptr, $sp, 16*(-6)
	sync
	bisl	link, code_ptr		/* branch to the constructed stack code */

	/* Adjust pointer so that it points to the first variable
	 * argument on the stack.
	 */
	ai	offset, parms, -1	/* offset = parms - 1 */
	mpyi	offset, offset, 16	/* offset = offset * 16 */
	a	ptr, ptr, offset	/* ptr = ptr + offset */

	/* Store the va_list to the parameter list.
	 */
	stqd	$sp, 16*(-1)(ptr)
	stqd	ptr, 16*(-2)(ptr)

	/* Make $3 store address.
	*/
	ai	offset, parms, 2	/* offset = parms + 2 */
	mpyi	offset, offset, -16	/* offset = offset * -16 */
	a	ptr, ptr, offset	/* ptr = ptr + offset */

	/* Save all the fixed (non-variable arguments on the stack)
	 */
	ceqi	flag, parms, 0x01	/* if(parms==1) flag=0xFFFFFFFF */
	brnz	flag, reg_3		/* if(flag!=0) jump */
	ceqi	flag, parms, 0x02	/* if(parms==2) flag=0xFFFFFFFF */
	brnz	flag, reg_4		/* if(flag!=0) jump */
	stqd	$5, 16*2(ptr)
reg_4:
	stqd	$4, 16*1(ptr)
reg_3:
	stqd	$3, 0(ptr)

	il	$3, -16*(SPE_STACK_REGS+2+2)
	stqx	$sp, $3, $sp		/* save back chain */
	a	$sp, $sp, $3
	bi      $0			/* return to caller */

/***************************** stack code *********************************************/
	
	/* The following code is copied into the stack for re-entract,
	 * self-modified, code execution. This code copies the volatile
	 * registers into a va_list parameter array.
	 */
	.balignl	16, 0
save_regs_1:
	stqd	inst, 16(code_ptr)	/* store instruction */
	sync
	a	inst, inst, regdec	/* decrement register number in the instruction */
	ceqbi	tmp, inst, 3		/* if (reg-num == 3) tmp = 0x000000FF 000..0 */
save_regs_2:	
	stqd	$68, -16(ptr)
	ai	ptr, ptr, -16
	brz	tmp, save_regs_1	/* if (tmp == 0) jump */
	bi	link			/* finish to make va_list */
