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

#ifndef _LOGBF4_H_
#define _LOGBF4_H_	1

#include <spu_intrinsics.h>
#include <vec_types.h>

/*
 * FUNCTION
 *	vector float _scalbnf4(vector float x, vector signed int exp)
 *
 * DESCRIPTION
 *      The _scalbnf4 function returns a vector containing each element of x 
 *      multiplied by 2^n computed efficiently.  This function is computed 
 *      without the assistance of any floating point operations and as such 
 *      does not set any floating point exceptions.
 *
 *      Special Cases:
 *	  - if the exponent is 0, then x is either 0 or a subnormal, and the 
 *          result will be returned as 0.
 *        - if the result if underflows, it will be returned as 0.
 *        - if the result overflows, it will be returned as FLT_MAX.
 *
 */
static __inline vector float _logbf4(vector float x)
{
  vec_uint4 lzero     = (vector unsigned int) {0, 0, 0, 0};
  vec_uint4 exp_mask  = (vector unsigned int) {0xFF, 0xFF, 0xFF, 0xFF};
  vec_int4  exp_shift = (vector signed int) { -23,  -23,  -23,  -23};
  vec_int4  exp_bias  = (vector signed int) {-127, -127, -127, -127};
  vec_uint4 sign_mask = (vector unsigned int) {0x80000000, 0x80000000,
		                                       0x80000000, 0x80000000};
  vec_uint4 linf      = (vector unsigned int) {0x7F800000, 0x7F800000,
		                                       0x7F800000, 0x7F800000};
  vec_uint4 lminf     = (vector unsigned int) {0xFF800000, 0xFF800000,
		                                       0xFF800000, 0xFF800000};
  vec_uint4 exp;
  vec_uint4 xabs;
  vec_float4 exp_unbias;


  xabs = spu_andc((vec_uint4)x, sign_mask);

  exp  = spu_and(spu_rlmask((vec_uint4)x, exp_shift), exp_mask);
  exp_unbias = spu_convtf(spu_add((vec_int4)exp, exp_bias), 0);

  /* Zero */
  exp_unbias = spu_sel(exp_unbias, (vec_float4)lminf, (vec_uint4)spu_cmpeq(xabs, lzero));

  /* NaN */
  exp_unbias = spu_sel(exp_unbias, x, (vec_uint4)spu_cmpgt(xabs, linf));

  /* Infinite */
  exp_unbias = spu_sel(exp_unbias, (vec_float4)linf, (vec_uint4)spu_cmpeq(xabs, linf));

  return (exp_unbias);
}

#endif /* _LOGBF4_H_ */

#endif /* __SPU__ */
