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
#ifndef _SQRT_H_
#define _SQRT_H_	1

/*
 * FUNCTION
 *   double _sqrt(double in)
 *
 * DESCRIPTION
 *   _sqrt computes the square root of the input "in" and returns the
 *   result.
 */
#include <spu_intrinsics.h>
#include "headers/vec_literal.h"
#include "headers/dom_chkd_less_than.h"

static __inline double _sqrt(double in)
{
  vec_int4 bias_exp;
  vec_uint4 exp;
  vec_float4 fx, fg, fy, fd, fe, fy2, fhalf;
  vec_ullong2 nochange;
  vec_ullong2 mask = VEC_SPLAT_U64(0x7FE0000000000000ULL);
  vec_double2 x, dx, de, dd, dy, dg, dy2, dhalf;
  vec_double2 denorm, neg;
  vec_double2 vc = { 0.0, 0.0 };

  fhalf = VEC_SPLAT_F32(0.5f);
  dhalf = VEC_SPLAT_F64(0.5);

  /* Coerce the input, in, into the argument reduced space [0.5, 2.0).
   */
  x = spu_promote(in, 0);
  dx = spu_sel(x, dhalf, mask);

  /* Compute an initial single precision guess for the square root (fg)
   * and half reciprocal (fy2).
   */
  fx = spu_roundtf(dx);

  fy2 = spu_rsqrte(fx);
  fy = spu_mul(fy2, fhalf);
  fg = spu_mul(fy2, fx); /* 12-bit approximation to sqrt(cx) */

  /* Perform one single precision Newton-Raphson iteration to improve
   * accuracy to about 22 bits.
   */
  fe = spu_nmsub(fy, fg, fhalf);
  fd = spu_nmsub(fg, fg, fx);

  fy = spu_madd(fy2, fe, fy);
  fg = spu_madd(fy, fd, fg); /* 22-bit approximation */

  dy = spu_extend(fy);
  dg = spu_extend(fg);

  /* Perform two double precision Newton-Raphson iteration to improve
   * accuracy to about 44 and 88 bits repectively.
   */
  dy2 = spu_add(dy, dy);
  de = spu_nmsub(dy, dg, dhalf);
  dd = spu_nmsub(dg, dg, dx);
  dy = spu_madd(dy2, de, dy);
  dg = spu_madd(dy, dd, dg); /* 44 bit approximation */

  dd = spu_nmsub(dg, dg, dx);
  dg = spu_madd(dy, dd, dg); /* full double precision approximation */


  /* Compute the expected exponent assuming that it is not a special value.
   * See special value handling below.
   */
  bias_exp = spu_rlmaska(spu_sub((vec_int4)spu_and((vec_ullong2)x, mask),
                                 (vec_int4)VEC_SPLAT_U64(0x3FE0000000000000ULL)), -1);
  dg = (vec_double2)spu_add((vec_int4)dg, bias_exp);


  /* Handle special inputs. These include:
   *
   *   input      output
   * =========    =========
   *    -0           -0
   * +infinity    +infinity
   *    NaN         NaN
   *    <0          NaN
   *   denorm       zero
   */
  exp = (vec_uint4)spu_and((vec_ullong2)x, VEC_SPLAT_U64(0xFFF0000000000000ULL));
  exp = spu_shuffle(exp, exp, VEC_LITERAL(vec_uchar16, 0,1,2,3,0,1,2,3, 8,9,10,11,8,9,10,11));

  neg = (vec_double2)spu_rlmaska((vec_int4)exp, -31);
  denorm = (vec_double2)spu_rlmask(spu_cmpeq(spu_sl(exp, 1), 0), VEC_LITERAL(vec_int4, -1,0,-1,0));

  nochange = (vec_ullong2)spu_cmpeq(exp, 0x7FF00000);

  dg = spu_sel(spu_andc(spu_or(dg, neg), denorm), x, nochange);

#ifndef _IEEE_LIBM
  dom_chkd_less_than(spu_splats(in), vc);
#endif
  return (spu_extract(dg, 0));
}
#endif /* _SQRT_H_ */
