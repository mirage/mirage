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
#ifndef _FLOORF4_H_
#define _FLOORF4_H_	1

#include <spu_intrinsics.h>


/*
 * FUNCTION
 *	vector float _floorf4(vector float value)
 *
 * DESCRIPTION
 *	The _floorf4 routine rounds a vector of input values "value" downwards
 *	to their nearest integer returning the result as a vector of floats. 
 *
 *	The full range form (default) provides floor computation on 
 *	all IEEE floating point values. The floor of NANs remain NANs.
 *	The floor of denorms results in zero.
 *
 */
static __inline vector float _floorf4(vector float value)
{

  /* FULL FLOATING-POINT RANGE 
   */
  vec_int4 exp, shift;
  vec_uint4 mask, frac_mask, addend, insert, pos;
  vec_float4 out;

  /* This function generates the following component
   * based upon the inputs.
   *
   *   mask = bits of the input that need to be replaced.
   *   insert = value of the bits that need to be replaced
   *   addend = value to be added to perform function.
   *
   * These are applied as follows:.
   *
   *   out = ((in & mask) | insert) + addend
   */
  pos = spu_cmpgt((vec_int4)value, -1);
  exp = spu_and(spu_rlmask((vec_int4)value, -23), 0xFF);

  shift = spu_sub(127, exp);

  frac_mask = spu_and(spu_rlmask(spu_splats((unsigned int)0x7FFFFF), shift),
		      spu_cmpgt((vec_int4)shift, -31));

  mask = spu_orc(frac_mask, spu_cmpgt(exp, 126));

  addend = spu_andc(spu_andc(spu_add(mask, 1), pos), spu_cmpeq(spu_and((vec_uint4)value, mask), 0));
  
  insert = spu_andc(spu_andc(spu_splats((unsigned int)0xBF800000), pos), 
		    spu_cmpgt((vec_uint4)spu_add(exp, -1), 126));

  out = (vec_float4)spu_add(spu_sel((vec_uint4)value, insert, mask), addend);

  /* Preserve orignal sign bit (for -0 case)
   */
  out = spu_sel(out, value, spu_splats((unsigned int)0x80000000));

  return (out);
}
#endif /* _FLOORF4_H_ */
#endif /* __SPU__ */
