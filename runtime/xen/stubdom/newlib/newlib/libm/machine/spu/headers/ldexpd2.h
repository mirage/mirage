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

#ifndef _LDEXPD2_H_
#define _LDEXPD2_H_	1

#include <spu_intrinsics.h>

/*
 * FUNCTION
 *      vector double _ldexpd2(vector double x, vector signed long long exp)
 *
 * DESCRIPTION
 *      The _ldexpd2 function Computes x * 2^exp for each of the two elements 
 *      of x using the corresponding elements of exp.
 *
 */
static __inline vector double _ldexpd2(vector double x, vector signed long long llexp)
{
  vec_uchar16 odd_to_even = ((vec_uchar16) { 4,5,6,7,     0x80,0x80,0x80,0x80, 
                                             12,13,14,15, 0x80,0x80,0x80,0x80 });
  vec_uchar16 dup_even = ((vec_uchar16) { 0,1,2,3,    0,1,2,3,
                                          8,9,10,11,  8,9,10,11});
  vec_int4 exp;
  vec_uint4 exphi;
  vec_int4 e1, e2;
  vec_int4 min = spu_splats(-2044);
  vec_int4 max = spu_splats(2046);
  vec_uint4 cmp_min, cmp_max;
  vec_uint4 shift = (vec_uint4) { 20, 32, 20, 32 };
  vec_double2 f1, f2;
  vec_double2 out;

  exp = (vec_int4)spu_shuffle(llexp, llexp, odd_to_even);

  exphi = (vec_uint4)spu_shuffle(llexp, llexp, dup_even);

  /* Clamp the specified exponent to the range -2044 to 2046.
   */

  cmp_min = spu_cmpgt(exp, min);
  cmp_max = spu_cmpgt(exp, max);
  exp = spu_sel(min, exp, cmp_min);
  exp = spu_sel(exp, max, cmp_max);

  /* Generate the factors f1 = 2^e1 and f2 = 2^e2
   */
  e1 = spu_rlmaska(exp, -1);
  e2 = spu_sub(exp, e1);

  f1 = (vec_double2)spu_sl(spu_add(e1, 1023), shift);
  f2 = (vec_double2)spu_sl(spu_add(e2, 1023), shift);

  /* Compute the product x * 2^e1 * 2^e2
   */
  out = spu_mul(spu_mul(x, f1), f2);

  return (out);
}

#endif /* _LDEXPD2_H_ */
#endif /* __SPU__ */

