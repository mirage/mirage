/* --------------------------------------------------------------  */
/* (C)Copyright 2006,2007,                                         */
/* International Business Machines Corporation,                    */
/* Sony Computer Entertainment, Incorporated,                      */
/* Toshiba Corporation,                                            */
/*                                                                 */
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

#ifndef _ASINF4_H_
#define _ASINF4_H_	1

#include <spu_intrinsics.h>

#include "divf4.h"
#include "sqrtf4.h"

/*
 * FUNCTION
 *	vector float _asinf4(vector float x)
 *
 * DESCRIPTION
 *	The _asinf4 function computes the arc sine for a vector of values x; 
 *      that is the values whose sine is x. Results are undefined if x is 
 *      outside the range [-1, 1]. 
 *
 */
static __inline vector float _asinf4(vector float x)
{
  /* The arcsin is computed using two different algorithms, depending
   * upon the absolute value of the input. For inputs in the range 
   * [0, PI/4], it is computed as the ratio of two polynomials.
   *
   *	asin(x) = p/q;
   *
   *    where p = P11*x^11 + P09*x^9 + P07*x^7 + P05*x^5 + P03*x3 + x
   *          q = Q08*x^8  + Q06*x^6 + Q04*x^4 + Q02*x^2 + Q00
   *
   * For the range of value [PI/4, 1], the arcsin is computed using:
   *
   *    asin = PI/2 - sqrt(1 - x) * r;
   *
   *    where r = C07*x^7 + C06*x^6 + C05*x^5 + C04*x^4 + C03*x^3 + C02*x^2
   *              C01*x   + C00;
   */
  vector float r, r1, r2, r_hi, r_lo;
  vector float xabs, x2, x4, x6;
  vector float p, p_hi, p_lo;
  vector float q, q_hi, q_lo;
  vector float pi_over_2 = spu_splats(1.5707963267949f);
  vector float pi_over_4 = spu_splats(0.7853981633974f);
  vector unsigned int msb = spu_splats(0x80000000);


  x2 = spu_mul(x, x);
  x4 = spu_mul(x2, x2);
  x6 = spu_mul(x4, x2);

  xabs = spu_andc(x, (vector float)msb);

  /* Compute arc-sin for values in the range [0, PI/4]
   */
  p_hi = spu_madd(spu_splats(0.0000347933107596021167570f), x2,
		  spu_splats(0.000791534994289814532176f));
  p_hi = spu_madd(p_hi, x2, spu_splats(-0.0400555345006794114027f));

  p_lo = spu_madd(spu_splats(0.201212532134862925881f), x2,
		  spu_splats(-0.325565818622400915405f));
  p_lo = spu_madd(p_lo, x2, spu_splats(0.166666666666666657415f));
  
  p = spu_madd(p_hi, x6, p_lo);

  q_hi = spu_madd(spu_splats(0.0770381505559019352791f), x2,
		  spu_splats(-0.688283971605453293030f));
  q_hi = spu_madd(q_hi, x2, spu_splats(2.02094576023350569471f));

  q_lo = spu_madd(spu_splats(-2.40339491173441421878f), x2, 
		  spu_splats(1.0f));

  q = spu_madd(q_hi, x4, q_lo);

  r1 = spu_madd(_divf4(p, q), spu_mul(xabs, x2), xabs);

  /* Compute arc-sin for values in the range [PI/4, 1]
   */
  r_hi = spu_madd(spu_splats(-0.0012624911f), xabs,
		  spu_splats(0.0066700901f));
  r_hi = spu_madd(r_hi, xabs, spu_splats(-0.0170881256f));
  r_hi = spu_madd(r_hi, xabs, spu_splats(0.0308918810f));

  r_lo = spu_madd(spu_splats(-0.0501743046f), xabs,
		  spu_splats(0.0889789874f));
  r_lo = spu_madd(r_lo, xabs, spu_splats(-0.2145988016f));
  r_lo = spu_madd(r_lo, xabs, pi_over_2);

  r = spu_madd(r_hi, x4, r_lo);
  
  r2 = spu_nmsub(r, _sqrtf4(spu_sub(spu_splats(1.0f), xabs)), 
		 pi_over_2);

  /* Select the result depending upon the input value. Correct the
   * sign of the result.
   */
  return (spu_sel(spu_sel(r1, r2, spu_cmpgt(xabs, pi_over_4)), 
		  x, msb));
}

#endif /* _ASINF4_H_ */
#endif /* __SPU__ */


