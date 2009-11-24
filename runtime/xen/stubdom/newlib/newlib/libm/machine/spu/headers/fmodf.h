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
#ifndef _FMODF_H_
#define _FMODF_H_	1

#include <errno.h>
#include <spu_intrinsics.h>
#include "headers/vec_literal.h"

#include "fabsf.h"

/*
 * FUNCTION
 *	float _fmodf(float x, float y)
 *
 * DESCRIPTION
 *	The _fmodf subroutine computes the remainder of
 *	dividing x by y. The return value is x - n*y, where n is
 *	the quotient of x/y, rounded towards zero.
 *
 *	The full range form (default) provides fmod computation on
 *	all IEEE floating point values (excluding floating overflow
 *	or underflow).
 *
 *	The limited range form (selected by defining FMODF_INTEGER_RANGE)
 *	compute fmod of all floating-point x/y values in the 32-bit
 *	signed integer range. Values outside this range get clamped.
 */

static __inline float _fmodf(float x, float y)
{
#ifdef FMODF_INTEGER_RANGE
  /* 32-BIT INTEGER DYNAMIC RANGE
   */
  float abs_y;
  float quotient;

  abs_y = _fabsf(y);
  quotient = x/abs_y;

  return (abs_y*(quotient - ((float)((int)quotient))));

#else /* !FMODF_INTEGER_RANGE */
  /* FULL FLOATING-POINT RANGE
   */
  int n;
  vec_uint4 vx, vy, z;
  vec_uint4 abs_x, abs_y;
  vec_uint4 exp_x, exp_y;
  vec_uint4 zero_x, zero_y;
  vec_uint4 logb_x, logb_y;
  vec_uint4 mant_x, mant_y;
  vec_uint4 result, result0, resultx, cnt, sign;
  vec_uint4 sign_mask = VEC_SPLAT_U32(0x80000000);
  vec_uint4 implied_1 = VEC_SPLAT_U32(0x00800000);
  vec_uint4 mant_mask = VEC_SPLAT_U32(0x007FFFFF);
  vec_uint4 domain;
  vec_int4 verrno;
  vec_float4 vc = { 0.0, 0.0, 0.0, 0.0 };
  vec_int4 fail = { EDOM, EDOM, EDOM, EDOM };

  vx = (vec_uint4)spu_promote(x, 0);
  vy = (vec_uint4)spu_promote(y, 0);

  abs_x = spu_andc(vx, sign_mask);
  abs_y = spu_andc(vy, sign_mask);

  sign = spu_and(vx, sign_mask);

  /* Determine ilogb of abs_x and abs_y and
   * extract the mantissas (mant_x, mant_y)
   */
  exp_x  = spu_rlmask(abs_x, -23);
  exp_y  = spu_rlmask(abs_y, -23);

  resultx = spu_cmpgt(abs_y, abs_x);

  zero_x = spu_cmpeq(exp_x, 0);
  zero_y = spu_cmpeq(exp_y, 0);

  logb_x = spu_add(exp_x, -127);
  logb_y = spu_add(exp_y, -127);

  mant_x = spu_andc(spu_sel(implied_1, abs_x, mant_mask), zero_x);
  mant_y = spu_andc(spu_sel(implied_1, abs_y, mant_mask), zero_y);

  /* Compute fixed point fmod of mant_x and mant_y. Set the flag,
   * result0, to all ones if we detect that the final result is
   * ever 0.
   */
  result0 = spu_or(zero_x, zero_y);

  n = spu_extract(spu_sub(logb_x, logb_y), 0);

  while (n-- > 0) {
    z = spu_sub(mant_x, mant_y);

    result0 = spu_or(spu_cmpeq(z, 0), result0);

    mant_x = spu_sel(spu_add(mant_x, mant_x), spu_add(z, z),
                     spu_cmpgt((vec_int4)z, -1));
  }

  z = spu_sub(mant_x, mant_y);
  mant_x = spu_sel(mant_x, z, spu_cmpgt((vec_int4)z, -1));

  result0 = spu_or(spu_cmpeq(mant_x, 0), result0);

  /* Convert the result back to floating point and restore
   * the sign. If we flagged the result to be zero (result0),
   * zero it. If we flagged the result to equal its input x,
   * (resultx) then return x.
   */
  cnt = spu_add(spu_cntlz(mant_x), -8);

  mant_x = spu_rl(spu_andc(mant_x, implied_1), (vec_int4)cnt);

  exp_y = spu_sub(exp_y, cnt);
  result0 = spu_orc(result0, spu_cmpgt((vec_int4)exp_y, 0)); /* zero denorm results */
  exp_y = spu_rl(exp_y, 23);


  result = spu_sel(exp_y, spu_or(sign, mant_x), VEC_SPLAT_U32(0x807FFFFF));

  result = spu_sel(spu_andc(result, spu_rlmask(result0, -1)), vx,
                   resultx);

#ifndef _IEEE_LIBM
  /*
   * If y is zero, set errno to EDOM
   */
  domain = spu_cmpeq(vc, (vec_float4) vy);
  verrno = spu_splats(errno);
  errno = spu_extract(spu_sel(verrno, fail, (vector unsigned int) domain), 0);
#endif

  return (spu_extract((vec_float4)result, 0));
#endif /* FMODF_INTEGER_RANGE */
}
#endif /* _FMODF_H_ */
