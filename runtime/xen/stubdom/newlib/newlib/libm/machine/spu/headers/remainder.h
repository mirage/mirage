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
#ifndef _REMAINDER_H_
#define _REMAINDER_H_	1

#include <spu_intrinsics.h>
#include "headers/vec_literal.h"

static __inline double _remainder(double x, double y)
{
  int n, shift;
  vec_uchar16 swap_words = VEC_LITERAL(vec_uchar16, 4,5,6,7, 0,1,2,3, 12,13,14,15, 8,9,10,11);
  vec_uchar16 propagate = VEC_LITERAL(vec_uchar16, 4,5,6,7, 192,192,192,192, 12,13,14,15, 192,192,192,192);
  vec_uchar16 splat_hi = VEC_LITERAL(vec_uchar16, 0,1,2,3,0,1,2,3, 8,9,10,11, 8,9,10,11);
  vec_uchar16 splat_lo = VEC_LITERAL(vec_uchar16, 4,5,6,7,4,5,6,7, 12,13,14,15, 12,13,14,15);
  vec_uint4 vx, vy, z;
  vec_uint4 x_hi, y_hi, y_lo;
  vec_uint4 abs_x, abs_y, abs_2x, abs_2y;
  vec_uint4 exp_x, exp_y;
  vec_uint4 zero_x, zero_y;
  vec_uint4 logb_x, logb_y;
  vec_uint4 mant_x, mant_y;
  vec_uint4 normal, norm, denorm;
  vec_uint4 gt, eq, bias, y2_hi;
  vec_uint4 nan_out;
  vec_uint4 result, result0, resultx, cnt, sign, borrow;
  vec_uint4 exp_special = VEC_SPLAT_U32(0x7FF00000);
  vec_uint4 half_smax = VEC_SPLAT_U32(0x7FEFFFFF);
  vec_uint4 lsb       = (vec_uint4)(VEC_SPLAT_U64(0x0000000000000001ULL));
  vec_uint4 sign_mask = (vec_uint4)(VEC_SPLAT_U64(0x8000000000000000ULL));
  vec_uint4 implied_1 = (vec_uint4)(VEC_SPLAT_U64(0x0010000000000000ULL));
  vec_uint4 mant_mask = (vec_uint4)(VEC_SPLAT_U64(0x000FFFFFFFFFFFFFULL));

  vx = (vec_uint4)spu_promote(x, 0);
  vy = (vec_uint4)spu_promote(y, 0);

  abs_x = spu_andc(vx, sign_mask);
  abs_y = spu_andc(vy, sign_mask);

  abs_2y = spu_add(abs_y, implied_1);

  sign = spu_and(vx, sign_mask);


  /* Compute abs_x = fmodf(abs_x, 2*abs_y). If y is greater than 0.5*SMAX (SMAX is the maximum
   * representable float), then return abs_x.
   */
  {
    x_hi = spu_shuffle(abs_x, abs_x, splat_hi);
    y_lo = spu_shuffle(abs_y, abs_y, splat_lo);
    y_hi = spu_shuffle(abs_y, abs_y, splat_hi);
    y2_hi = spu_shuffle(abs_2y, abs_2y, splat_hi);

    /* Force a NaN output if (1) abs_x is infinity or NaN or (2)
     * abs_y is a NaN.
     */
    nan_out = spu_or(spu_cmpgt(x_hi, half_smax),
                     spu_or(spu_cmpgt(y_hi, exp_special),
                            spu_and(spu_cmpeq(y_hi, exp_special),
                                    spu_cmpgt(y_lo, 0))));

    /* Determine ilogb of abs_x and abs_y and
     * extract the mantissas (mant_x, mant_y)
     */
    exp_x  = spu_rlmask(x_hi, -20);
    exp_y  = spu_rlmask(y2_hi, -20);

    resultx = spu_or(spu_cmpgt(y2_hi, x_hi), spu_cmpgt(y_hi, half_smax));

    zero_x = spu_cmpeq(exp_x, 0);
    zero_y = spu_cmpeq(exp_y, 0);

    logb_x = spu_add(exp_x, -1023);
    logb_y = spu_add(exp_y, -1023);

    mant_x = spu_andc(spu_sel(implied_1, abs_x, mant_mask), zero_x);
    mant_y = spu_andc(spu_sel(implied_1, abs_2y, mant_mask), zero_y);

    /* Compute fixed point fmod of mant_x and mant_y. Set the flag,
     * result0, to all ones if we detect that the final result is
     * ever 0.
     */
    result0 = spu_or(zero_x, zero_y);

    n = spu_extract(spu_sub(logb_x, logb_y), 0);

    while (n-- > 0) {
      borrow = spu_genb(mant_x, mant_y);
      borrow = spu_shuffle(borrow, borrow, propagate);
      z = spu_subx(mant_x, mant_y, borrow);

      result0 = spu_or(spu_cmpeq(spu_or(z, spu_shuffle(z, z, swap_words)), 0), result0);

      mant_x = spu_sel(spu_slqw(mant_x, 1), spu_andc(spu_slqw(z, 1), lsb), spu_cmpgt((vec_int4)spu_shuffle(z, z, splat_hi), -1));
    }


    borrow = spu_genb(mant_x, mant_y);
    borrow = spu_shuffle(borrow, borrow, propagate);
    z = spu_subx(mant_x, mant_y, borrow);

    mant_x = spu_sel(mant_x, z, spu_cmpgt((vec_int4)spu_shuffle(z, z, splat_hi), -1));
    mant_x = spu_andc(mant_x, VEC_LITERAL(vec_uint4, 0,0,-1,-1));

    result0 = spu_or(spu_cmpeq(spu_or(mant_x, spu_shuffle(mant_x, mant_x, swap_words)), 0), result0);

    /* Convert the result back to floating point and restore
     * the sign. If we flagged the result to be zero (result0),
     * zero it. If we flagged the result to equal its input x,
     * (resultx) then return x.
     *
     * Double precision generates a denorm for an output.
     */
    cnt = spu_cntlz(mant_x);
    cnt = spu_add(cnt, spu_and(spu_rlqwbyte(cnt, 4), spu_cmpeq(cnt, 32)));
    cnt = spu_add(spu_shuffle(cnt, cnt, splat_hi), -11);

    shift = spu_extract(exp_y, 0) - 1;
    denorm = spu_slqwbytebc(spu_slqw(mant_x, shift), shift);

    exp_y = spu_sub(exp_y, cnt);

    normal = spu_cmpgt((vec_int4)exp_y, 0);

    /* Normalize normal results, denormalize denorm results.
     */
    shift = spu_extract(cnt, 0);
    norm = spu_slqwbytebc(spu_slqw(spu_andc(mant_x, VEC_LITERAL(vec_uint4, 0x00100000, 0, -1, -1)), shift), shift);

    mant_x = spu_sel(denorm, norm, normal);

    exp_y = spu_and(spu_rl(exp_y, 20), normal);

    result = spu_sel(exp_y, mant_x, mant_mask);

    abs_x = spu_sel(spu_andc(result, spu_rlmask(result0, -1)), abs_x, resultx);

  }

  /* if (2*x > y)
   *     x -= y
   *     if (2*x >= y) x -= y
   */
  abs_2x = spu_and(spu_add(abs_x, implied_1), normal);

  gt = spu_cmpgt(abs_2x, abs_y);
  eq = spu_cmpeq(abs_2x, abs_y);
  bias = spu_or(gt, spu_and(eq, spu_rlqwbyte(gt, 4)));
  bias = spu_shuffle(bias, bias, splat_hi);
  abs_x = spu_sel(abs_x, (vec_uint4)spu_sub((vec_double2)abs_x, (vec_double2)abs_y), bias);

  bias = spu_andc(bias, spu_rlmaska((vec_uint4)spu_msub((vec_double2)abs_x, VEC_SPLAT_F64(2.0), (vec_double2)abs_y), -31));
  bias = spu_shuffle(bias, bias, splat_hi);
  abs_x = spu_sel(abs_x, (vec_uint4)spu_sub((vec_double2)abs_x, (vec_double2)abs_y), bias);

  /* Generate a correct final sign
   */
  result = spu_sel(spu_xor(abs_x, sign), exp_special, nan_out);

  return (spu_extract((vec_double2)result, 0));
}
#endif /* _REMAINDER_H_ */
