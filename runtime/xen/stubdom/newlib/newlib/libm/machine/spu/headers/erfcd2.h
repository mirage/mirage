/* --------------------------------------------------------------  */
/* (C)Copyright 2006,2007,                                         */
/* International Business Machines Corporation                     */
/* All Rights Reserved.                                            */
/*                                                                 */
/* Redistribution and use in source and binary forms, with or      */
/* without modification, are permitted provided that the           */
/* following conditions are met:                                   */
/*                                                                 */
/* - Redistributions of source code must retain the above copyright*/
/*   notice, this list of conditions and the following disclaimer. */
/*                                                                 */
/* - Redistributions in binary form must reproduce the above       */
/*   copyright notice, this list of conditions and the following   */
/*   disclaimer in the documentation and/or other materials        */
/*   provided with the distribution.                               */
/*                                                                 */
/* - Neither the name of IBM Corporation nor the names of its      */
/*   contributors may be used to endorse or promote products       */
/*   derived from this software without specific prior written     */
/*   permission.                                                   */
/* Redistributions of source code must retain the above copyright  */
/* notice, this list of conditions and the following disclaimer.   */
/*                                                                 */
/* Redistributions in binary form must reproduce the above         */
/* copyright notice, this list of conditions and the following     */
/* disclaimer in the documentation and/or other materials          */
/* provided with the distribution.                                 */
/*                                                                 */
/* Neither the name of IBM Corporation nor the names of its        */
/* contributors may be used to endorse or promote products         */
/* derived from this software without specific prior written       */
/* permission.                                                     */
/*                                                                 */
/* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND          */
/* CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,     */
/* INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF        */
/* MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE        */
/* DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR            */
/* CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,    */
/* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT    */
/* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;    */
/* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)        */
/* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN       */
/* CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR    */
/* OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,  */
/* EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.              */
/* --------------------------------------------------------------  */
/* PROLOG END TAG zYx                                              */
#ifdef __SPU__
#ifndef _ERFCD2_H_
#define _ERFCD2_H_	1

#include <spu_intrinsics.h>

#include "expd2.h"
#include "recipd2.h"
#include "divd2.h"
#include "erf_utils.h"

/*
 * FUNCTION
 *  vector double _erfcd2(vector double x)
 *
 * DESCRIPTION
 *  The erfcd2 function computes the complement error function of each element of x.
 *
 *  Accuracy Note: We would benefit from a rational approximation in the domain
 *  1.2 < x < 2.0 and also around x = 2.5.
 *
 *  C99 Special Cases:
 *  - erfc(+0) returns +1
 *  - erfc(-0) returns +1
 *  - erfc(+infinite) returns +0
 *  - erfc(-infinite) returns +2
 *
 *  Other Cases:
 *  - erfc(Nan) returns Nan
 *
 */

static __inline vector double _erfcd2(vector double x)
{
  vec_uchar16 dup_even  = ((vec_uchar16) { 0,1,2,3, 0,1,2,3, 8,9,10,11, 8,9,10,11 });
  vec_double2 onehalfd  = spu_splats(0.5);
  vec_double2 zerod     = spu_splats(0.0);
  vec_double2 oned      = spu_splats(1.0);
  vec_double2 twod      = spu_splats(2.0);
  vec_double2 sign_mask = spu_splats(-0.0);

  /* This is where we switch from near zero approx. */
  vec_float4 approx_point = spu_splats(1.71f);

  vec_double2 xabs, xsqu, xsign;
  vec_uint4 xhigh, xabshigh;
  vec_uint4 isnan, isneg;
  vec_double2 tresult, presult, result;

  xsign = spu_and(x, sign_mask);

  /* Force Denorms to 0 */
  x = spu_add(x, zerod);

  xabs = spu_andc(x, sign_mask);
  xsqu = spu_mul(x, x);

  /*
   * Use Taylor Series for x near 0
   * Preserve sign of x in result, since erf(-x) = -erf(x)
   * This approximation is for erf, so adjust for erfc.
   */
  TAYLOR_ERF(xabs, xsqu, tresult);
  tresult = spu_or(tresult, xsign);
  tresult = spu_sub(oned, tresult);

  /*
   * Now, use the Continued Fractions approximation away
   * from 0. If x < 0, use erfc(-x) = 2 - erfc(x)
   */
  CONTFRAC_ERFC(xabs, xsqu, presult);
  isneg = (vec_uint4)spu_shuffle(x, x, dup_even);
  isneg = spu_rlmaska(isneg, -32);
  presult = spu_sel(presult, spu_sub(twod, presult), (vec_ullong2)isneg);

  /*
   * Select the appropriate approximation.
   */
  vec_float4 xf = spu_roundtf(xabs);
  xf = spu_shuffle(xf, xf, dup_even);
  result = spu_sel(tresult, presult, (vec_ullong2)spu_cmpgt(xf, approx_point));

  /*
   * Special cases/errors.
   */
  xhigh = (vec_uint4)spu_shuffle(x, x, dup_even);
  xabshigh = (vec_uint4)spu_shuffle(xabs, xabs, dup_even);

  /* x = +/- infinite */
  result = spu_sel(result, zerod, (vec_ullong2)spu_cmpeq(xhigh, 0x7FF00000));
  result = spu_sel(result, twod,  (vec_ullong2)spu_cmpeq(xhigh, 0xFFF00000));

  /* x = nan, return x */
  isnan = spu_cmpgt(xabshigh, 0x7FF00000);
  result = spu_sel(result, x, (vec_ullong2)isnan);

  return result;
}

#endif /* _ERFCD2_H_ */
#endif /* __SPU__ */
