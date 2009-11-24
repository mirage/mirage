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
#ifndef _FMOD_H_
#define _FMOD_H_	1

#include <spu_intrinsics.h>
#include <errno.h>
#include "headers/vec_literal.h"

/* This implementation returns zero if y is a denorm or zero.
 */
static __inline double _fmod(double x, double y)
{
  int n, shift;
  vec_uchar16 swap_words = VEC_LITERAL(vec_uchar16, 4,5,6,7, 0,1,2,3, 12,13,14,15, 8,9,10,11);
  vec_uchar16 propagate = VEC_LITERAL(vec_uchar16, 4,5,6,7, 192,192,192,192, 12,13,14,15, 192,192,192,192);
  vec_uchar16 splat_hi = VEC_LITERAL(vec_uchar16, 0,1,2,3,0,1,2,3, 8,9,10,11, 8,9,10,11);
  vec_uint4 vx, vy, z;
  vec_uint4 x_hi, y_hi;
  vec_uint4 abs_x, abs_y;
  vec_uint4 exp_x, exp_y;
  vec_uint4 zero_x, zero_y;
  vec_uint4 logb_x, logb_y;
  vec_uint4 mant_x, mant_y;
  vec_uint4 normal, norm, denorm;
  vec_uint4 result, result0, resultx, cnt, sign, borrow;
  vec_uint4 lsb       = (vec_uint4)(VEC_SPLAT_U64(0x0000000000000001ULL));
  vec_uint4 sign_mask = (vec_uint4)(VEC_SPLAT_U64(0x8000000000000000ULL));
  vec_uint4 implied_1 = (vec_uint4)(VEC_SPLAT_U64(0x0010000000000000ULL));
  vec_uint4 mant_mask = (vec_uint4)(VEC_SPLAT_U64(0x000FFFFFFFFFFFFFULL));
  vec_ullong2 domain;
  vec_int4 verrno;
  vec_double2 vc = { 0.0, 0.0 };
  vec_int4 fail = { EDOM, EDOM, EDOM, EDOM };

  vx = (vec_uint4)spu_promote(x, 0);
  vy = (vec_uint4)spu_promote(y, 0);

  abs_x = spu_andc(vx, sign_mask);
  abs_y = spu_andc(vy, sign_mask);

  sign = spu_and(vx, sign_mask);

  x_hi = spu_shuffle(abs_x, abs_x, splat_hi);
  y_hi = spu_shuffle(abs_y, abs_y, splat_hi);

  /* Determine ilogb of abs_x and abs_y and
   * extract the mantissas (mant_x, mant_y)
   */
  exp_x  = spu_rlmask(x_hi, -20);
  exp_y  = spu_rlmask(y_hi, -20);

  resultx = spu_cmpgt(y_hi, x_hi);

  zero_x = spu_cmpeq(exp_x, 0);
  zero_y = spu_cmpeq(exp_y, 0);

  logb_x = spu_add(exp_x, -1023);
  logb_y = spu_add(exp_y, -1023);

  mant_x = spu_andc(spu_sel(implied_1, abs_x, mant_mask), zero_x);
  mant_y = spu_andc(spu_sel(implied_1, abs_y, mant_mask), zero_y);

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

    mant_x = spu_sel(spu_slqw(mant_x, 1), spu_andc(spu_slqw(z, 1), lsb),
                     spu_cmpgt((vec_int4)spu_shuffle(z, z, splat_hi), -1));
  }

  borrow = spu_genb(mant_x, mant_y);
  borrow = spu_shuffle(borrow, borrow, propagate);
  z = spu_subx(mant_x, mant_y, borrow);

  mant_x = spu_sel(mant_x, z,
                   spu_cmpgt((vec_int4)spu_shuffle(z, z, splat_hi), -1));
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

  result = spu_sel(exp_y, spu_or(sign, mant_x), VEC_LITERAL(vec_uint4, 0x800FFFFF, -1, 0x800FFFFF, -1));

  result = spu_sel(spu_andc(result, spu_rlmask(result0, -1)), vx,
                   resultx);

#ifndef _IEEE_LIBM
  /*
   * If y is zero, set errno to EDOM
   */
  domain = spu_cmpeq(vc, (vec_double2) vy);
  verrno = spu_splats(errno);
  errno = spu_extract(spu_sel(verrno, fail, (vector unsigned int) domain), 0);
#endif

  return (spu_extract((vec_double2)result, 0));
}
#endif /* _FMOD_H_ */
