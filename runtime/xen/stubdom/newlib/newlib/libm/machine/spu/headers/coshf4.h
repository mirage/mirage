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
#ifndef _COSHF4_H_
#define _COSHF4_H_ 1

#include <spu_intrinsics.h>

#include "expf4.h"
#include "recipf4.h"


/*
 * FUNCTION
 *	vector float _coshf4(vector float x)
 *
 * DESCRIPTION
 *	The _coshf4 function computes the hyperbolic cosines of a vector of 
 *      angles (expressed in radians) to an accuracy of a single precision 
 *      floating point.
 *
 */
static __inline vector float _coshf4(vector float x)
{
  //  1.0000  (above this number, use sinh(x) = 0.5 * (e^x - e^-x)
  vec_uint4 threshold = (vec_uint4)spu_splats(0x3F800000);

  vec_uint4 sign_mask = (vec_uint4)spu_splats(0x80000000);

  // Coefficents for the Taylor series
  vec_float4 f02 = spu_splats(5.0000000000000000E-1f);  // 1/2!
  vec_float4 f04 = spu_splats(4.1666666666666667E-2f);  // 1/4!
  vec_float4 f06 = spu_splats(1.3888888888888889E-3f);  // 1/6!
  vec_float4 f08 = spu_splats(2.4801587301587302E-5f);  // 1/8!
  vec_float4 f10 = spu_splats(2.7557319223985891E-7f);  // 1/10!
  vec_float4 f12 = spu_splats(2.0876756987868099E-9f);  // 1/12!

  // Perform the calculation as a Taylor series
  vec_float4 result;
  vector float x2 = spu_mul(x,x);
  result = spu_madd(x2,f12,f10);
  result = spu_madd(x2,result,f08);
  result = spu_madd(x2,result,f06);
  result = spu_madd(x2,result,f04);
  result = spu_madd(x2,result,f02);
  result = spu_madd(x2,result,spu_splats(1.0f));


  //  Perform calculation as a function of 0.5 * (e^x - e^-x)
  vec_float4 ex = _expf4(x);
  vec_float4 ex_inv = _recipf4(ex);

  vec_float4 r2= spu_add(ex,ex_inv);
  r2 = spu_mul(r2,f02);  // we can reused f02 here

  vec_uint4 xabs = spu_andc((vec_uint4)x,sign_mask);
  vec_uint4 use_exp = spu_cmpgt(xabs,threshold);

  //  Select either the Taylor or exp version
  result = spu_sel(result,r2,use_exp);

  return result;
}
#endif /* _COSHF4_H_ */
#endif /* __SPU__ */
