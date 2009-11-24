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
#ifndef _SQRTF4_H_
#define _SQRTF4_H_	1

#include <spu_intrinsics.h>

/*
 * FUNCTION
 *      vector float _sqrtf4(vector float in)
 *
 * DESCRIPTION
 *      The _sqrtf4 function computes the square root of the vector input "in" 
 *and returns the result. 
 *
 */
static __inline vector float _sqrtf4(vector float in) 
{
  vec_uint4 exp, valid;
  vec_uint4 mask = spu_splats((unsigned int)0xFF000000);
  vec_uint4 half = spu_splats((unsigned int)0x00800000);
  vec_float4 one = spu_splats(1.0f);
  vec_float4 three = spu_splats(3.0f);
  vec_float4 x, y0, y1, y1_n1, y1_p1, y1_p2, y1_p3;
  vec_float4 mant, err, err_p1, err_p2, err_p3;
  vec_float4 out;

  /* Compute the mantissa of the result seperately from 
   * the exponent to assure complete accuracy over the allowable
   * input range. The mantissa is computed for inputs in the 
   * range [0.5, 2.0).
   */
  x = spu_sel(in, one, mask);
  y0 = spu_rsqrte(x);
  
  /* Perform one iteration of the Newton-Raphsom method in single precision
   * arithmetic.
   */
  y1 = spu_mul(spu_nmsub(x, spu_mul(y0, y0), three), 
	       spu_mul(y0, (vec_float4)(spu_sub((vec_uint4)(x), half))));

  /* Correct the result for possible error. The range of error is -3 to +1.
   * Identify the extent of the error and correct for it.
   */
  y1_p3 = (vec_float4)spu_add((vec_uint4)(y1), 3);
  y1_p2 = (vec_float4)spu_add((vec_uint4)(y1), 2);
  y1_p1 = (vec_float4)spu_add((vec_uint4)(y1), 1);
  y1_n1 = (vec_float4)spu_add((vec_uint4)(y1), -1);

  err    = spu_nmsub(y1,    y1,    x);
  err_p1 = spu_nmsub(y1_p1, y1_p1, x);
  err_p2 = spu_nmsub(y1_p2, y1_p2, x);
  err_p3 = spu_nmsub(y1_p3, y1_p3, x);

  mant = spu_sel(y1_n1, y1,    spu_cmpgt((vec_int4)(err),    -1));
  mant = spu_sel(mant,  y1_p1, spu_cmpgt((vec_int4)(err_p1), -1));
  mant = spu_sel(mant,  y1_p2, spu_cmpgt((vec_int4)(err_p2), -1));
  mant = spu_sel(mant,  y1_p3, spu_cmpgt((vec_int4)(err_p3), -1));

  /* Compute the expected exponent. If the exponent is zero or the input is
   * negative, then set the result to zero.
   */
  exp = spu_rlmask(spu_add((vec_uint4)(in), (vec_uint4)(one)), -1);

  valid = spu_cmpgt(spu_and((vec_int4)(in), (vec_int4)(mask)), 0);
    
  /* Merge the computed exponent and mantissa.
   */
  out = spu_and(spu_sel(mant, (vec_float4)(exp), spu_splats(0xFF800000)), (vec_float4)(valid));


  return (out);

}

#endif /* _SQRTF4_H_ */
#endif /* __SPU__ */
