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
#ifndef _EXPF4_H_
#define _EXPF4_H_	1


#include "floorf4.h"
#include "ldexpf4.h"

/*
 * FUNCTION
 *	vector float _expf4(vector float x)
 *
 * DESCRIPTION
 *	The _expf4 function computes e raised to the input x for
 *	each of the element of the float vector.
 *
 */
static __inline vector float _expf4(vector float x)
{

  //  log2(e)
  vec_float4 log2e = spu_splats(1.4426950408889634074f);

  // Extra precision for the ln2 multiply
  vec_float4 ln2_hi = spu_splats(0.693359375f);
  vec_float4 ln2_lo = spu_splats(-2.12194440E-4f);

  // Coefficents for the Taylor series
  vec_float4 f02 = spu_splats(5.0000000000000000E-1f); // 1/2!
  vec_float4 f03 = spu_splats(1.6666666666666667E-1f); // 1/3!
  vec_float4 f04 = spu_splats(4.1666666666666667E-2f); // 1/4!
  vec_float4 f05 = spu_splats(8.3333333333333333E-3f); // 1/5!
  vec_float4 f06 = spu_splats(1.3888888888888889E-3f); // 1/6!
  vec_float4 f07 = spu_splats(1.9841269841269841E-4f); // 1/7!

  //  Range reduce input, so that:
  //  e^x = e^z * 2^n
  //  e^x = e^z * e^(n * ln(2))
  //  e^x = e^(z + (n * ln(2)))

  vec_int4 n;  // exponent of reduction
  vec_float4 q;  // range reduced result

  vec_float4 z;
  vec_float4 r;  

  z = spu_madd(x,log2e,spu_splats(0.5f));
  z = _floorf4(z);
  r = spu_nmsub(z,ln2_hi,x);
  r = spu_nmsub(z,ln2_lo,r);
  n = spu_convts(z,0);
  z = spu_mul(r,r);

  //  Use Horner's method on the Taylor series
  q = spu_madd(r,f07,f06);
  q = spu_madd(q,r,f05);
  q = spu_madd(q,r,f04);
  q = spu_madd(q,r,f03);
  q = spu_madd(q,r,f02);
  q = spu_madd(q,z,r);
  q = spu_add(q,spu_splats(1.0f));

  //  Adjust the result by the range reduction
  r  = _ldexpf4( q, n );

  return(r);

}

#endif /* _EXPF4_H_ */
#endif /* __SPU__ */

