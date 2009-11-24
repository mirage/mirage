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
#ifndef _TRUNCD2_H_
#define _TRUNCD2_H_	1

#include <spu_intrinsics.h>

/*
 * FUNCTION
 *      vector double _truncd2(vector double x)
 *
 * DESCRIPTION
 *      The _truncd2 function truncates the elements of the input vector
 *      downwards (towards zero) to the nearest integer.
 *
 */
static __inline vector double _truncd2(vector double in)
{
  vec_uchar16 splat_hi = (vec_uchar16) { 0,1,2,3,0,1,2,3, 8,9,10,11, 8,9,10,11 };
  vec_int4 exp, shift;
  vec_uint4 sign = (vec_uint4) { 0x80000000, 0, 0x80000000, 0 };
  vec_uint4 or_mask, and_mask, mask;
  vec_double2 in_hi, out;

  /* Construct a mask to remove the fraction bits. The mask
   * depends on the exponent of the floating point
   * input value.
   */
  in_hi = spu_shuffle(in, in, splat_hi);
  exp = spu_and(spu_rlmask((vec_int4)in_hi, -20), 0x7FF);

  shift = spu_sub(((vec_int4) { 1023, 1043, 1023, 1043 }), exp);
  or_mask = spu_andc(spu_cmpgt(shift, 0), sign);

  and_mask = spu_rlmask(((vec_uint4) { 0xFFFFF, -1, 0xFFFFF, -1 }), shift);
  mask = spu_or(spu_and(and_mask, spu_cmpgt(shift, -32)), or_mask);

  /* Apply the mask and return the result.
   */
  out = spu_andc(in, (vec_double2)(mask));

  return (out);
}


#endif /* _TRUNCD2_H_ */
#endif /* __SPU__ */
