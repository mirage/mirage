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

#ifndef _LGAMMAD2_H_
#define _LGAMMAD2_H_	1

#include <spu_intrinsics.h>
#include "divd2.h"
#include "recipd2.h"
#include "logd2.h"
#include "sind2.h"
#include "truncd2.h"


/*
 * FUNCTION
 *	vector double _lgammad2(vector double x) - Natural Log of Gamma Function
 *
 * DESCRIPTION
 *	_lgammad2 calculates the natural logarithm of the absolute value of the gamma
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

#define PI                  3.1415926535897932384626433832795028841971693993751058209749445923078164
#define HALFLOG2PI          9.1893853320467274178032973640561763986139747363778341281715154048276570E-1

#define EULER_MASCHERONI    0.5772156649015328606065

/*
 * Zeta constants for Maclaurin approx. near zero
 */
#define ZETA_02_DIV_02       8.2246703342411321823620758332301E-1
#define ZETA_03_DIV_03      -4.0068563438653142846657938717048E-1
#define ZETA_04_DIV_04       2.7058080842778454787900092413529E-1
#define ZETA_05_DIV_05      -2.0738555102867398526627309729141E-1
#define ZETA_06_DIV_06       1.6955717699740818995241965496515E-1

/*
 *  More Maclaurin coefficients
 */
/*
#define ZETA_07_DIV_07      -1.4404989676884611811997107854997E-1
#define ZETA_08_DIV_08       1.2550966952474304242233565481358E-1
#define ZETA_09_DIV_09      -1.1133426586956469049087252991471E-1
#define ZETA_10_DIV_10       1.0009945751278180853371459589003E-1
#define ZETA_11_DIV_11      -9.0954017145829042232609298411497E-2
#define ZETA_12_DIV_12       8.3353840546109004024886499837312E-2
#define ZETA_13_DIV_13      -7.6932516411352191472827064348181E-2
#define ZETA_14_DIV_14       7.1432946295361336059232753221795E-2
#define ZETA_15_DIV_15      -6.6668705882420468032903448567376E-2
#define ZETA_16_DIV_16       6.2500955141213040741983285717977E-2
#define ZETA_17_DIV_17      -5.8823978658684582338957270605504E-2
#define ZETA_18_DIV_18       5.5555767627403611102214247869146E-2
#define ZETA_19_DIV_19      -5.2631679379616660733627666155673E-2
#define ZETA_20_DIV_20       5.0000047698101693639805657601934E-2
 */

/*
 * Coefficients for Stirling's Series for Lgamma()
 */
#define STIRLING_01    8.3333333333333333333333333333333333333333333333333333333333333333333333E-2
#define STIRLING_02   -2.7777777777777777777777777777777777777777777777777777777777777777777778E-3
#define STIRLING_03    7.9365079365079365079365079365079365079365079365079365079365079365079365E-4
#define STIRLING_04   -5.9523809523809523809523809523809523809523809523809523809523809523809524E-4
#define STIRLING_05    8.4175084175084175084175084175084175084175084175084175084175084175084175E-4
#define STIRLING_06   -1.9175269175269175269175269175269175269175269175269175269175269175269175E-3
#define STIRLING_07    6.4102564102564102564102564102564102564102564102564102564102564102564103E-3
#define STIRLING_08   -2.9550653594771241830065359477124183006535947712418300653594771241830065E-2
#define STIRLING_09    1.7964437236883057316493849001588939669435025472177174963552672531000704E-1
#define STIRLING_10   -1.3924322169059011164274322169059011164274322169059011164274322169059011E0
#define STIRLING_11    1.3402864044168391994478951000690131124913733609385783298826777087646653E1
#define STIRLING_12   -1.5684828462600201730636513245208897382810426288687158252375643679991506E2
#define STIRLING_13    2.1931033333333333333333333333333333333333333333333333333333333333333333E3
#define STIRLING_14   -3.6108771253724989357173265219242230736483610046828437633035334184759472E4
#define STIRLING_15    6.9147226885131306710839525077567346755333407168779805042318946657100161E5
/*
 *  More Stirling's coefficients
 */
/*
#define STIRLING_16   -1.5238221539407416192283364958886780518659076533839342188488298545224541E7
#define STIRLING_17    3.8290075139141414141414141414141414141414141414141414141414141414141414E8
#define STIRLING_18   -1.0882266035784391089015149165525105374729434879810819660443720594096534E10
#define STIRLING_19    3.4732028376500225225225225225225225225225225225225225225225225225225225E11
#define STIRLING_20   -1.2369602142269274454251710349271324881080978641954251710349271324881081E13
#define STIRLING_21    4.8878806479307933507581516251802290210847053890567382180703629532735764E14
*/


static __inline vector double _lgammad2(vector double x) 
{
  vec_uchar16 dup_even  = ((vec_uchar16) { 0,1,2,3, 0,1,2,3,  8, 9,10,11,  8, 9,10,11 });
  vec_uchar16 dup_odd   = ((vec_uchar16) { 4,5,6,7, 4,5,6,7, 12,13,14,15, 12,13,14,15 });
  vec_uchar16 swap_word = ((vec_uchar16) { 4,5,6,7, 0,1,2,3, 12,13,14,15,  8, 9,10,11  });
  vec_double2 infinited = (vec_double2)spu_splats(0x7FF0000000000000ull);
  vec_double2 zerod     = spu_splats(0.0);
  vec_double2 oned      = spu_splats(1.0);
  vec_double2 twod      = spu_splats(2.0);
  vec_double2 pi        = spu_splats(PI);
  vec_double2 sign_maskd = spu_splats(-0.0);

  /* This is where we switch from near zero approx. */
  vec_float4 zero_switch = spu_splats(0.001f);
  vec_float4 shift_switch = spu_splats(6.0f);

  vec_float4 xf;
  vec_double2 inv_x, inv_xsqu;                  
  vec_double2 xtrunc, xstirling;
  vec_double2 sum, xabs;
  vec_uint4 xhigh, xlow, xthigh, xtlow;
  vec_uint4 x1, isnaninf, isnposint, iszero, isint, isneg, isshifted, is1, is2;
  vec_double2 result, stresult, shresult, mresult, nresult;


  /* Force Denorms to 0 */
  x = spu_add(x, zerod);

  xabs = spu_andc(x, sign_maskd);
  xf = spu_roundtf(xabs);
  xf = spu_shuffle(xf, xf, dup_even);


  /*
   * For 0 < x <= 0.001.
   * Approximation Near Zero
   *
   * Use Maclaurin Expansion of lgamma()
   *
   * lgamma(z) = -ln(z) - z * EulerMascheroni + Sum[(-1)^n * z^n * Zeta(n)/n]
   */
  mresult = spu_madd(xabs, spu_splats(ZETA_06_DIV_06), spu_splats(ZETA_05_DIV_05));
  mresult = spu_madd(xabs, mresult, spu_splats(ZETA_04_DIV_04));
  mresult = spu_madd(xabs, mresult, spu_splats(ZETA_03_DIV_03));
  mresult = spu_madd(xabs, mresult, spu_splats(ZETA_02_DIV_02));
  mresult = spu_mul(xabs, spu_mul(xabs, mresult));
  mresult = spu_sub(mresult, spu_add(_logd2(xabs), spu_mul(xabs, spu_splats(EULER_MASCHERONI))));


  /*
   * For 0.001 < x <= 6.0, we are going to push value
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

  isshifted = spu_cmpgt(shift_switch, xf);
  xstirling = spu_sel(xabs, spu_add(xabs, spu_splats(6.0)), (vec_ullong2)isshifted);
  inv_x    = _recipd2(xstirling);            
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
   * Taking 10 terms of the sum gives good results for x > 6.0
   *
   */
  sum = spu_madd(inv_xsqu, spu_splats(STIRLING_15), spu_splats(STIRLING_14));
  sum = spu_madd(sum, inv_xsqu, spu_splats(STIRLING_13));
  sum = spu_madd(sum, inv_xsqu, spu_splats(STIRLING_12));
  sum = spu_madd(sum, inv_xsqu, spu_splats(STIRLING_11));
  sum = spu_madd(sum, inv_xsqu, spu_splats(STIRLING_10));
  sum = spu_madd(sum, inv_xsqu, spu_splats(STIRLING_09));
  sum = spu_madd(sum, inv_xsqu, spu_splats(STIRLING_08));
  sum = spu_madd(sum, inv_xsqu, spu_splats(STIRLING_07));
  sum = spu_madd(sum, inv_xsqu, spu_splats(STIRLING_06));
  sum = spu_madd(sum, inv_xsqu, spu_splats(STIRLING_05));
  sum = spu_madd(sum, inv_xsqu, spu_splats(STIRLING_04));
  sum = spu_madd(sum, inv_xsqu, spu_splats(STIRLING_03));
  sum = spu_madd(sum, inv_xsqu, spu_splats(STIRLING_02));
  sum = spu_madd(sum, inv_xsqu, spu_splats(STIRLING_01));
  sum = spu_mul(sum, inv_x);

  stresult = spu_madd(spu_sub(xstirling, spu_splats(0.5)), _logd2(xstirling), spu_splats(HALFLOG2PI));
  stresult = spu_sub(stresult, xstirling);
  stresult = spu_add(stresult, sum);

  /*
   * Adjust result if we shifted x into Stirling range.
   *
   * lgamma(x) = lgamma(x + n) - ln(x(x+1)(x+2)...(x+n-1)
   *
   */
  shresult = spu_mul(xabs, spu_add(xabs, spu_splats(1.0)));
  shresult = spu_mul(shresult, spu_add(xabs, spu_splats(2.0)));
  shresult = spu_mul(shresult, spu_add(xabs, spu_splats(3.0)));
  shresult = spu_mul(shresult, spu_add(xabs, spu_splats(4.0)));
  shresult = spu_mul(shresult, spu_add(xabs, spu_splats(5.0)));
  shresult = _logd2(shresult);
  shresult = spu_sub(stresult, shresult);
  stresult = spu_sel(stresult, shresult, (vec_ullong2)isshifted);


  /*
   * Select either Maclaurin or Stirling result before Negative X calc.
   */
  xf = spu_shuffle(xf, xf, dup_even);
  vec_uint4 useStirlings = spu_cmpgt(xf, zero_switch);
  result = spu_sel(mresult, stresult, (vec_ullong2)useStirlings);


  /*
   * Approximation for Negative X
   *
   * Use reflection relation
   *
   * gamma(x) * gamma(-x) = -pi/(x sin(pi x))
   *
   * lgamma(x) = log(pi/(-x sin(pi x))) - lgamma(-x)
   *           
   */
  nresult = spu_mul(x, _sind2(spu_mul(x, pi)));
  nresult = spu_andc(nresult, sign_maskd);
  nresult = _logd2(_divd2(pi, nresult));
  nresult = spu_sub(nresult, result);


  /*
   * Select between the negative or positive x approximations.
   */
  isneg = (vec_uint4)spu_shuffle(x, x, dup_even);
  isneg = spu_rlmaska(isneg, -32);
  result = spu_sel(result, nresult, (vec_ullong2)isneg);


  /*
   * Finally, special cases/errors.
   */
  xhigh = (vec_uint4)spu_shuffle(xabs, xabs, dup_even);
  xlow  = (vec_uint4)spu_shuffle(xabs, xabs, dup_odd);

  /* x = zero, return infinite */
  x1 = spu_or(xhigh, xlow);
  iszero = spu_cmpeq(x1, 0);

  /* x = negative integer, return infinite */
  xtrunc = _truncd2(xabs);
  xthigh = (vec_uint4)spu_shuffle(xtrunc, xtrunc, dup_even);
  xtlow  = (vec_uint4)spu_shuffle(xtrunc, xtrunc, dup_odd);
  isint = spu_and(spu_cmpeq(xthigh, xhigh), spu_cmpeq(xtlow, xlow));
  isnposint = spu_or(spu_and(isint, isneg), iszero);
  result = spu_sel(result, infinited, (vec_ullong2)isnposint);

  /* x = 1.0 or 2.0, return 0.0 */
  is1 = spu_cmpeq((vec_uint4)x, (vec_uint4)oned);
  is1 = spu_and(is1, spu_shuffle(is1, is1, swap_word));
  is2 = spu_cmpeq((vec_uint4)x, (vec_uint4)twod);
  is2 = spu_and(is2, spu_shuffle(is2, is2, swap_word));
  result = spu_sel(result, zerod, (vec_ullong2)spu_or(is1,is2));

  /* x = +/- infinite or nan, return |x| */
  isnaninf = spu_cmpgt(xhigh, 0x7FEFFFFF);
  result = spu_sel(result, xabs, (vec_ullong2)isnaninf);

  return result;
}

#endif /* _LGAMMAD2_H_ */
#endif /* __SPU__ */
