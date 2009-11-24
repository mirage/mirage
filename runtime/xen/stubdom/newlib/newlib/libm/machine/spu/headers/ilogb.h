/*
  (C) Copyright 2001,2006,
  International Business Machines Corporation,
  Sony Computer Entertainment, Incorporated,
  Toshiba Corporation,

  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
    * Neither the names of the copyright holders nor the names of their
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
  OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
#ifndef _ILOGB_H_
#define _ILOGB_H_	1

#include <spu_intrinsics.h>
#include "headers/vec_literal.h"
#include <limits.h>
#include <math.h>

/* ilogb returns the signed exponent in the floating-point
 * input. Special numbers include:
 *     Input     Output
 *     =====    =====================
 * 	INF     FP_ILOGBNAN (INT_MAX)
 * 	NAN     FP_ILOGBNAN (INT_MAX)
 *     denorm   exponent - leading zeros
 * 	 0      FP_ILOGB0 (INT_MIN)
 *      else	signed exponent
 */

static __inline int _ilogb(double x)
{
  vec_uint4 v, exp, exp_0, mant, mask, count;
  vec_uint4 flg_exp_0, flg_exp_max;

  mask = VEC_SPLAT_U32(0x7FF);

  /* Extract the exponent and mantissa.
   */
  v = (vec_uint4)spu_promote(x, 0);

  exp = spu_and(spu_rlmask(v, -20), mask);

  mant = spu_and(v, VEC_LITERAL(vec_uint4, 0x000FFFFF, 0xFFFFFFFF, 0, 0));

  /* Count the leading zeros in the mantissa for denorm handling
   * and zero identification.
   */
  count = spu_cntlz(mant);
  count = spu_add(count, spu_and(spu_rlqwbyte(count, 4), spu_cmpeq(count, 32)));

  flg_exp_0 = spu_cmpeq(exp, 0);
  flg_exp_max = spu_cmpeq(exp, mask);

  exp = spu_add(exp, -1023);

  /* Determine the exponent if the input is a denorm or zero.
   */
  exp_0 = spu_sel(spu_sub(spu_add(exp, 12), count), VEC_SPLAT_U32(FP_ILOGB0), spu_cmpeq(count, 64));

  exp = spu_sel(spu_sel(exp, VEC_SPLAT_U32(FP_ILOGBNAN), flg_exp_max), exp_0, flg_exp_0);

  return (spu_extract((vec_int4)(exp), 0));
}
#endif /* _ILOGB_H_ */
