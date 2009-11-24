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
#ifndef _POWD2_H_
#define _POWD2_H_	1

#include "exp2d2.h"
#include "log2d2.h"

/*
 * FUNCTION
 *	vector double _powd2(vector double x, vector double y)
 *
 * DESCRIPTION
 *	The _powd2 function computes x raised to the power y for the set of 
 *	vectors. The powd2 function is computed as by decomposing 
 *	the problem into:
 *
 *		x^y = 2^(y*log2(x))
 *
 *
 */
static __inline vector double _powd2(vector double x, vector double y)
{
  vec_uchar16 splat_hi = (vec_uchar16) { 0,1,2,3,0,1,2,3, 8,9,10,11, 8,9,10,11 };
  vec_int4 exp, shift;
  vec_uint4 sign = (vec_uint4) { 0x80000000, 0, 0x80000000, 0 };
  vec_uint4 or_mask, and_mask, evenmask, intmask;
  vec_double2 in_hi;
  vector double signmask = spu_splats(-0.0);
  vector signed int error = spu_splats(-1);
  vector double zero = spu_splats(0.0);
  vector unsigned int y_is_int, y_is_odd, y_is_even;
  vector unsigned int x_is_neg;
  vector double xabs, xsign;
  vector double out;


  xsign = spu_and(x, signmask);
  xabs  = spu_andc(x, signmask);
  x_is_neg = (vec_uint4)spu_cmpgt(zero, x);


  /* First we solve assuming x was non-negative */
  out = _exp2d2(spu_mul(y, _log2d2(xabs)));

  in_hi = spu_shuffle(y, y, splat_hi);
  exp = spu_and(spu_rlmask((vec_int4)in_hi, -20), 0x7FF);

  /* Determine if y is an integer */
  shift = spu_sub(((vec_int4) { 1023, 1043, 1023, 1043 }), exp);
  or_mask = spu_andc(spu_cmpgt(shift, 0), sign);
  and_mask = spu_rlmask(((vec_uint4) { 0xFFFFF, -1, 0xFFFFF, -1 }), shift);
  intmask = spu_or(spu_and(and_mask, spu_cmpgt(shift, -32)), or_mask);
  y_is_int = (vec_uint4)spu_cmpeq(y, spu_andc(y, (vec_double2)(intmask)));

  /* Determine if y is an even integer */
  shift = spu_sub(((vec_int4) { 1024, 1044, 1024, 1044 }), exp);
  or_mask = spu_andc(spu_cmpgt(shift, 0), sign);
  and_mask = spu_rlmask(((vec_uint4) { 0xFFFFF, -1, 0xFFFFF, -1 }), shift);
  evenmask = spu_or(spu_and(and_mask, spu_cmpgt(shift, -32)), or_mask);
  y_is_even = (vec_uint4)spu_cmpeq(y, spu_andc(y, (vec_double2)(evenmask)));

  y_is_odd = spu_andc(y_is_int, y_is_even);


  /* Special Cases
   */

  /* x < 0 is only ok when y integer */
  out = spu_sel(out, (vec_double2)error, (vec_ullong2)spu_andc(x_is_neg, y_is_int));

  /* Preserve the sign of x if y is an odd integer */
  out = spu_sel(out, spu_or(out, xsign), (vec_ullong2)y_is_odd);

  /* x = anything, y = +/- 0, returns 1 */
  out = spu_sel(out, spu_splats(1.0), spu_cmpabseq(y, zero));

  return(out);
}

#endif /* _POWD2_H_ */
#endif /* __SPU__ */
