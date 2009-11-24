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

#include "c99ppe.h"

	.text
	.align	4
	GLOBL	fscanf
fscanf:
	stqd	$0, 16($sp)		/* save caller address */
	il	$2, 2			/* number of fixed arguments */
	brsl	$0, __stack_reg_va	/* save register to the stack frame */

	brsl	$0, __check_init
	lqd	$3, 16*2($sp)		/* $3 <- saved FP on the stack frame */
	lqd	$2, 0($3)		/* FP = fp->_fp */
	rotqby	$2, $2, $3
	stqd	$2, 16*2($sp)		/* replace FP on the stack frame */

	il	$3, SPE_C99_SIGNALCODE
	il	$4, SPE_C99_VFSCANF
	ai	$5, $sp, 16*2		/* data ($3 save address) */
	brsl	$0, __send_to_ppe

	il	$2, 16*(SPE_STACK_REGS+2+2)
	a	$sp, $sp, $2
	lqd	$0, 16($sp)		/* load caller address */
	bi      $0			/* return to caller */
