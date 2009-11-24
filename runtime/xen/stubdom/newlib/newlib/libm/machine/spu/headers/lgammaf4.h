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

#ifndef _LGAMMAF4_H_
#define _LGAMMAF4_H_	1

#include <spu_intrinsics.h>
#include "lgammad2.h"
#include "recipf4.h"
#include "logf4.h"
#include "sinf4.h"
#include "truncf4.h"

/*
 * FUNCTION
 *	vector float _lgammaf4(vector float x) - Natural Log of Gamma Function
 *
 * DESCRIPTION
 *	_lgammaf4 calculates the natural logarithm of the absolute value of the gamma
 *	function for the corresponding elements of the input vector.
 *
 * C99 Special Cases:
 *	lgamma(0) returns +infinite 
 *	lgamma(1) returns +0
 *	lgamma(2) returns +0
 *	lgamma(negative integer) returns +infinite 
 *	lgamma(+infinite) returns +infinite
 *	lgamma(-infinite) returns +infinite
 *
 * Other Cases:
 *  lgamma(Nan) returns Nan
 *  lgamma(Denorm) treated as lgamma(0) and returns +infinite
 *
 */


static __inline vector float _lgammaf4(vector float x) 
{
  vec_float4 inff       = (vec_float4)spu_splats(0x7F800000);
  vec_float4 zerof      = spu_splats(0.0f);
  vec_float4 pi         = spu_splats((float)PI);
  vec_float4 sign_maskf = spu_splats(-0.0f);

  vector unsigned int gt0;

  /* This is where we switch from near zero approx. */
  vec_float4 mac_switch = spu_splats(0.16f);
  vec_float4 shift_switch = spu_splats(6.0f);

  vec_float4 inv_x, inv_xsqu;                  
  vec_float4 xtrunc, xstirling;
  vec_float4 sum, xabs;
  vec_uint4  isnaninf, isshifted;
  vec_float4 result, stresult, shresult, mresult, nresult;


  /* Force Denorms to 0 */
  x = spu_add(x, zerof);

  xabs = spu_andc(x, sign_maskf);

  gt0    = spu_cmpgt(x, zerof);
  xtrunc = _truncf4(x);

  /*
   * For 0 < x <= 0.16.
   * Approximation Near Zero
   *
   * Use Maclaurin Expansion of lgamma()
   *
   * lgamma(z) = -ln(z) - z * EulerMascheroni + Sum[(-1)^n * z^n * Zeta(n)/n]
   */
  mresult = spu_madd(xabs, spu_splats((float)ZETA_06_DIV_06), spu_splats((float)ZETA_05_DIV_05));
  mresult = spu_madd(xabs, mresult, spu_splats((float)ZETA_04_DIV_04));
  mresult = spu_madd(xabs, mresult, spu_splats((float)ZETA_03_DIV_03));
  mresult = spu_madd(xabs, mresult, spu_splats((float)ZETA_02_DIV_02));
  mresult = spu_mul(xabs, spu_mul(xabs, mresult));
  mresult = spu_sub(mresult, spu_add(_logf4(xabs), spu_mul(xabs, spu_splats((float)EULER_MASCHERONI))));


  /*
   * For 0.16 < x <= 6.0, we are going to push value
   * out to an area where Stirling's approximation is
   * accurate. Let's use a constant of 6.
   *
   * Use the recurrence relation:
   *    lgamma(x + 1) = ln(x) + lgamma(x)
   * 
   * Note that we shift x here, before Stirling's calculation,
   * then after Stirling's, we adjust the result.
   *
   */

  isshifted = spu_cmpgt(shift_switch, x);
  xstirling = spu_sel(xabs, spu_add(xabs, spu_splats(6.0f)), isshifted);
  inv_x    = _recipf4(xstirling);            
  inv_xsqu = spu_mul(inv_x, inv_x);            

  /*
   * For 6.0 < x < infinite
   *
   * Use Stirling's Series.
   *
   *              1                    1                1      1        1
   * lgamma(x) = --- ln (2*pi) + (z - ---) ln(x) - x + --- - ----- + ------ ...
   *              2                    2               12x   360x^3  1260x^5
   *
   *
   */
  sum = spu_madd(inv_xsqu, spu_splats((float)STIRLING_10), spu_splats((float)STIRLING_09));
  sum = spu_madd(sum, inv_xsqu, spu_splats((float)STIRLING_08));
  sum = spu_madd(sum, inv_xsqu, spu_splats((float)STIRLING_07));
  sum = spu_madd(sum, inv_xsqu, spu_splats((float)STIRLING_06));
  sum = spu_madd(sum, inv_xsqu, spu_splats((float)STIRLING_05));
  sum = spu_madd(sum, inv_xsqu, spu_splats((float)STIRLING_04));
  sum = spu_madd(sum, inv_xsqu, spu_splats((float)STIRLING_03));
  sum = spu_madd(sum, inv_xsqu, spu_splats((float)STIRLING_02));
  sum = spu_madd(sum, inv_xsqu, spu_splats((float)STIRLING_01));
  sum = spu_mul(sum, inv_x);

  stresult = spu_madd(spu_sub(xstirling, spu_splats(0.5f)), _logf4(xstirling), spu_splats((float)HALFLOG2PI));
  stresult = spu_sub(stresult, xstirling);
  stresult = spu_add(stresult, sum);

  /*
   * Adjust result if we shifted x into Stirling range.
   *
   * lgamma(x) = lgamma(x + n) - ln(x(x+1)(x+2)...(x+n-1)
   *
   */
  shresult = spu_mul(xabs, spu_add(xabs, spu_splats(1.0f)));
  shresult = spu_mul(shresult, spu_add(xabs, spu_splats(2.0f)));
  shresult = spu_mul(shresult, spu_add(xabs, spu_splats(3.0f)));
  shresult = spu_mul(shresult, spu_add(xabs, spu_splats(4.0f)));
  shresult = spu_mul(shresult, spu_add(xabs, spu_splats(5.0f)));
  shresult = _logf4(shresult);
  shresult = spu_sub(stresult, shresult);
  stresult = spu_sel(stresult, shresult, isshifted);


  /*
   * Select either Maclaurin or Stirling result before Negative X calc.
   */
  vec_uint4 useStirlings = spu_cmpgt(xabs, mac_switch);
  result = spu_sel(mresult, stresult, useStirlings);

  /*
   * Approximation for Negative X
   *
   * Use reflection relation:
   *
   * gamma(x) * gamma(-x) = -pi/(x sin(pi x))
   *
   * lgamma(x) = log(pi/(-x sin(pi x))) - lgamma(-x)
   *           
   */
  nresult = spu_mul(x, _sinf4(spu_mul(x, pi)));
  nresult = spu_andc(nresult, sign_maskf);
  nresult = spu_sub(_logf4(pi), spu_add(result, _logf4(nresult)));


  /*
   * Select between the negative or positive x approximations.
   */
  result = spu_sel(nresult, result, gt0);

  /*
   * Finally, special cases/errors.
   */

  /*
   * x = non-positive integer, return infinity.
   */
  result = spu_sel(result, inff, spu_andc(spu_cmpeq(x, xtrunc), gt0));

  /* x = +/- infinite or nan, return |x| */
  isnaninf = spu_cmpgt((vec_uint4)xabs, 0x7FEFFFFF);
  result   = spu_sel(result, xabs, isnaninf);

  return result;
}

#endif /* _LGAMMAF4_H_ */
#endif /* __SPU__ */
