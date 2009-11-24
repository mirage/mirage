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
#ifndef _SINHF4_H_
#define _SINHF4_H_ 1

#include <spu_intrinsics.h>

#include "expf4.h"
#include "recipf4.h"


/*
 * FUNCTION
 *	vector float _sinhf4(vector float angle)
 *
 * DESCRIPTION
 *	The _sinhf4 function computes the hyperbolic sine of a vector of 
 *      angles (expressed in radians) to an accuracy of a single precision 
 *      floating point.
 *
 */
static __inline vector float _sinhf4(vector float x)
{
  //  1.0000  (above this number, use sinh(x) = 0.5 * (e^x - e^-x)
  vec_uint4 threshold = (vec_uint4)spu_splats(0x3F800000);

  vec_uint4 sign_mask = (vec_uint4)spu_splats(0x80000000);

  // Coefficents for the Taylor series
  vec_float4 f03 = spu_splats(1.6666666666666667E-1f); // 1/3!
  vec_float4 f05 = spu_splats(8.3333333333333333E-3f); // 1/5!
  vec_float4 f07 = spu_splats(1.9841269841269841E-4f); // 1/7!
  vec_float4 f09 = spu_splats(2.7557319223985891E-6f); // 1/9!
  vec_float4 f11 = spu_splats(2.5052108385441719E-8f); // 1/11!


  // Perform the calculation as a Taylor series
  vec_float4 result;
  vec_float4 x2 = spu_mul(x,x);
  result = spu_madd(x2,f11,f09);
  result = spu_madd(x2,result,f07);
  result = spu_madd(x2,result,f05);
  result = spu_madd(x2,result,f03);
  result = spu_madd(x2,result,spu_splats(1.0f));
  result = spu_mul(x,result);


  //  Perform calculation as a function of 0.5 * (e^x - e^-x)
  vec_float4 ex =_expf4(x);
  vec_float4 ex_inv = _recipf4(ex);

  vec_float4 r2= spu_sub(ex,ex_inv);
  r2 = spu_mul(r2,spu_splats(0.5f));

  vec_uint4 xabs = spu_andc((vec_uint4)x,sign_mask);
  vec_uint4 use_exp = spu_cmpgt(xabs,threshold);

  //  Select either the Taylor or exp version
  result = spu_sel(result,r2,use_exp);

  //  Flip the sign if needed
  result = (vec_float4)spu_or((vec_uint4)result,spu_and((vec_uint4)x,sign_mask));

  return result;  

}
#endif /* _SINHF4_H_ */
#endif /* __SPU__ */
