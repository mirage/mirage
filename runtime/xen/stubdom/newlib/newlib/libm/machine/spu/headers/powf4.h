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
#ifndef _POWF4_H_
#define _POWF4_H_	1

#include <spu_intrinsics.h>
#include <vec_types.h>

#include "exp2f4.h"
#include "log2f4.h"

/*
 * FUNCTION
 *	vector float _powf4(vector float x, vector float y)
 *
 * DESCRIPTION
 *	The _powf4 function computes x raised to the power y for the set of 
 *	vectors. The powf4 function is computed as by decomposing 
 *	the problem into:
 *
 *		x^y = 2^(y*log2(x))
 *
 */
static __inline vector float _powf4(vector float x, vector float y)
{
  vec_uint4  y_exp;
  vec_uint4  y_mantissa;
  vec_uint4  mant_shift;
  vec_uint4  y_is_int;
  vec_uint4  y_is_odd;
  vec_uint4  x_sign_bit;
  vec_uint4  zero   = (vec_uint4)spu_splats(0);
  vec_uint4  bit0   = (vec_uint4)spu_splats(0x80000000);
  vec_int4   error = spu_splats(-1);
  vec_float4 out;

  y_exp = spu_and(spu_rlmask((vec_uint4)y, -23), 0x000000FF);

  /* Need the implied bit in the mantissa to catch 
   * y = 1 case later
   */
  y_mantissa = spu_or(spu_sl((vec_uint4)y, (unsigned int)8), bit0);

  x_sign_bit = spu_and((vec_uint4)x, bit0);

  /* We are going to shift the mantissa over enough to 
   * determine if we have an integer.
   */
  mant_shift = spu_add(y_exp, -127);


  /* Leave the lowest-order integer bit of mantissa on the 
   * high end so we can see if the integer is odd.
   */
  y_mantissa  = spu_sl(y_mantissa, mant_shift);

  y_is_int = spu_cmpeq(spu_andc(y_mantissa, bit0), 0);
  y_is_int = spu_and(y_is_int, spu_cmpgt(y_exp, 126));

  y_is_odd = spu_and(spu_cmpeq(y_mantissa, bit0), y_is_int);

  out = _exp2f4(spu_mul(y, _log2f4(spu_andc(x, (vec_float4)bit0))));

  /* x < 0 is only ok when y integer 
   */
  out = spu_sel(out, (vec_float4)error, 
				  spu_andc(spu_cmpeq(x_sign_bit, bit0), y_is_int));

  /* Preserve the sign of x if y is an odd integer
   */
  out = spu_sel(out, spu_or(out, (vec_float4)x_sign_bit), y_is_odd);

  /* x = anything, y = +/- 0, returns 1
   */
  out = spu_sel(out, spu_splats(1.0f), spu_cmpabseq(y, (vec_float4)zero));

  return(out);
}

#endif /* _POWF4_H_ */
#endif /* __SPU__ */
