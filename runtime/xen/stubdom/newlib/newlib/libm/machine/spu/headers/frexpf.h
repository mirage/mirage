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
#ifndef _FREXPF_H_
#define _FREXPF_H_	1

#include <spu_intrinsics.h>
#include "headers/vec_literal.h"

/* Return the normalized fraction and exponent to the number x.
 */
static __inline float _frexpf(float x, int *pexp)
{
  vec_int4 exp;
  vec_uint4 mask;
  vec_uint4 exp_mask = VEC_SPLAT_U32(0x7F800000);
  vec_float4 half = VEC_SPLAT_F32(0.5f);
  vec_float4 in, mant;

  in = spu_promote(x, 0);

  /* Normalize the mantissa (fraction part).
   */
  mant = spu_sel(in, half, exp_mask);

  /* Zero the mantissa if the input is a denorm or zero
   */
  exp = spu_and(spu_rlmask((vec_int4)in, -23), 0xFF);
  mask = spu_cmpeq(exp, 0);
  mant = spu_andc(mant, (vec_float4)mask);

  /* Zero exponent if zero or denorm input. Otherwise, compute
   * exponent by removing the bias.
   */
  exp = spu_andc(spu_add(exp, -126), (vec_int4)mask);
  *pexp = spu_extract(exp, 0);

  return (spu_extract(mant, 0));
}
#endif /* _FREXPF_H_ */
