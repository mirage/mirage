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
#ifndef _ERFF4_H_
#define _ERFF4_H_	1

#include <spu_intrinsics.h>

#include "expf4.h"
#include "recipf4.h"
#include "divf4.h"
#include "erf_utils.h"

/*
 * FUNCTION
 *  vector float _erff4(vector float x)
 *
 * DESCRIPTION
 *  The erff4 function computes the error function of each element of x.
 *
 *  C99 Special Cases:
 *  - erf(+0) returns +0
 *  - erf(-0) returns -0
 *  - erf(+infinite) returns +1
 *  - erf(-infinite) returns -1
 *
 */

static __inline vector float _erff4(vector float x)
{
  vector float onehalff  = spu_splats(0.5f);
  vector float zerof     = spu_splats(0.0f);
  vector float onef      = spu_splats(1.0f);
  vector float sign_mask = spu_splats(-0.0f);

  /* This is where we switch from Taylor Series to Continued Fraction approximation */
  vec_float4 approx_point = spu_splats(0.89f);

  vec_float4 xabs, xsqu, xsign;
  vec_uint4 isinf;
  vec_float4 tresult, presult, result;

  xsign = spu_and(x, sign_mask);

  /* Force Denorms to 0 */
  x = spu_add(x, zerof);

  xabs = spu_andc(x, sign_mask);
  xsqu = spu_mul(x, x);

  /*
   * Taylor Series Expansion near Zero
   */
  TAYLOR_ERFF4(xabs, xsqu, tresult);

  /*
   * Continued Fraction Approximation of Erfc().
   * erf = 1 - erfc 
   */
  CONTFRAC_ERFCF4(xabs, xsqu, presult);
  presult = spu_sub(onef, presult);

  /*
   * Select the appropriate approximation.
   */
  result = spu_sel(tresult, presult, spu_cmpgt(xabs, approx_point));

  /*
   * Special cases/errors.
   */

  /* x = +/- infinite, return +/-1 */
  isinf = spu_cmpeq((vec_uint4)xabs, 0x7F800000);
  result = spu_sel(result, onef, isinf);

  /*
   * Preserve sign in result, since erf(-x) = -erf(x)
   */
  result = spu_or(result, xsign);

  return result;
}

#endif /* _ERFF4_H_ */
#endif /* __SPU__ */
