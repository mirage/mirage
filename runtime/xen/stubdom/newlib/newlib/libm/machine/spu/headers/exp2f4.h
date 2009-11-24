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
#ifndef _EXP2F4_H_
#define _EXP2F4_H_	1


#include <spu_intrinsics.h>
#include "simdmath.h"

/*
 * FUNCTION
 *	vector float _exp2f4(vector float x)
 *
 * DESCRIPTION
 *	The _exp2f4 function computes 2 raised to the input vector x. 
 *      Computation is performed by observing the 2^(a+b) = 2^a * 2^b.
 *	We decompose x into a and b (above) by letting.
 *	a = ceil(x), b = x - a; 
 *
 *	2^a is easilty computed by placing a into the exponent
 *	or a floating point number whose mantissa is all zeros.
 *
 *	2^b is computed using the following polynomial approximation.
 *	(C. Hastings, Jr, 1955).
 *
 *                __7__
 *		  \
 *		   \ 
 *	2^(-x) =   /     Ci*x^i
 *                /____
 *                 i=1
 *
 *	for x in the range 0.0 to 1.0
 *
 *	C0 =  1.0
 *	C1 = -0.9999999995
 *	C2 =  0.4999999206
 *	C3 = -0.1666653019
 *	C4 =  0.0416573475
 *	C5 = -0.0083013598
 *	C6 =  0.0013298820
 *	C7 = -0.0001413161
 *
 */
static __inline vector float _exp2f4(vector float x)
{
  vector signed int ix;
  vector unsigned int overflow, underflow;
  vector float frac, frac2, frac4;
  vector float exp_int, exp_frac;
  vector float result;
  vector float hi, lo;

  vector float bias;
  /* Break in the input x into two parts ceil(x), x - ceil(x).
   */
  bias = (vector float)(spu_rlmaska((vector signed int)(x), -31));
  bias = (vector float)(spu_andc(spu_splats((unsigned int)0x3F7FFFFF), (vector unsigned int)bias));
  ix = spu_convts(spu_add(x, bias), 0);
  frac = spu_sub(spu_convtf(ix, 0), x);
  frac = spu_mul(frac, spu_splats((float)SM_LN2));

  overflow = spu_rlmask(spu_cmpgt(ix, 128), -1);
  underflow = spu_cmpgt(ix, -128);

  exp_int = (vector float)spu_and((vector unsigned int)spu_sl(spu_add(ix, 127), 23), underflow);

  /* Instruction counts can be reduced if the polynomial was
   * computed entirely from nested (dependent) fma's. However, 
   * to reduce the number of pipeline stalls, the polygon is evaluated 
   * in two halves (hi amd lo). 
   */
  frac2 = spu_mul(frac, frac);
  frac4 = spu_mul(frac2, frac2);

  hi = spu_madd(frac, spu_splats(-0.0001413161f), spu_splats(0.0013298820f));
  hi = spu_madd(frac, hi, spu_splats(-0.0083013598f));
  hi = spu_madd(frac, hi, spu_splats(0.0416573475f));
  lo = spu_madd(frac, spu_splats(-0.1666653019f), spu_splats(0.4999999206f));
  lo = spu_madd(frac, lo, spu_splats(-0.9999999995f));
  lo = spu_madd(frac, lo, spu_splats(1.0f));

  exp_frac = spu_madd(frac4, hi, lo);
  ix = spu_add(ix, spu_rlmask((vector signed int)(exp_frac), -23));
  result = spu_mul(exp_frac, exp_int);

  /* Handle overflow */
  result = spu_or(result, (vector float)overflow);

  return (result);

}

#endif /* _EXP2F4_H_ */
#endif /* __SPU__ */
