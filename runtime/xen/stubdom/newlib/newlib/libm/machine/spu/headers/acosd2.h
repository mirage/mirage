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

#ifndef _ACOSD2_H_
#define _ACOSD2_H_	1

#include <spu_intrinsics.h>

#include "simdmath.h"
#include "sqrtd2.h"
#include "divd2.h"

/*
 * FUNCTION
 *	vector double _acosd2(vector double x)
 *
 * DESCRIPTION
 * 	Compute the arc cosine of the vector of double precision elements 
 * 	specified by x, returning the resulting angles in radians. The input
 *      elements are to be in the closed interval [-1, 1]. Values outside 
 *      this range result in a invalid operation execption being latched in 
 *	the FPSCR register and a NAN is returned.
 *
 * 	The basic algorithm computes the arc cosine using PI/2 - asind2(x). 
 *      However, as |x| approaches 1, there is a cancellation error in 
 *	subtracting asind2(x) from PI/2, so we simplify the evaluation
 *	instead of layering acosd2 on top of asind2.
 *
 * 	This yields the basic algorithm of:
 *
 *	   absx = (x < 0.0) ? -x : x;
 *	 
 *	   if (absx > 0.5) {
 *	     if (x < 0) {
 *	       addend = SM_PI;
 *	       multiplier = -2.0;
 *	     } else {
 *	       addend = 0.0;
 *	       multiplier = 2.0;
 *	     }
 *	
 *	     x = sqrt(-0.5 * absx + 0.5);
 *	   } else {
 *	     addend = SM_PI_2;
 *	     multiplier = -1.0;
 *	   }
 *	
 *	    x2 = x * x;
 *	    x3 = x2 * x;
 *
 *	    p = ((((P5 * x2 + P4)*x2 + P3)*x2 + P2)*x2 + P1)*x2 + P0;
 *	 
 *	    q = ((((Q5 * x2 + Q4)*x2 + Q3)*x2 + Q2)*x2 + Q1)*x2 + Q0;;
 *	
 *	    pq = p / q;
 *	
 *	    result = (x3*pq + x)*multiplier - addend;
 *
 *	Where P5-P0 and Q5-Q0 are the polynomial coeficients. See asind2 
 *	for additional details.
 */
static __inline vector double _acosd2(vector double x)
{
  vec_uint4   x_gt_half, x_eq_half;
  vec_double2 x_neg;			// input x is negative
  vec_double2 x_abs;			// absolute value of x
  vec_double2 x_trans;			// transformed x when |x| > 0.5
  vec_double2 x2, x3;			// x squared and x cubed, respectively.
  vec_double2 result;
  vec_double2 multiplier, addend; 
  vec_double2 p, q, pq;
  vec_double2 half = spu_splats(0.5);
  vec_double2 sign = (vec_double2)spu_splats(0x8000000000000000ULL);
  vec_uchar16 splat_hi = ((vec_uchar16){0,1,2,3, 0,1,2,3, 8,9,10,11, 8,9,10,11});
  
  // Compute the absolute value of x
  x_abs = spu_andc(x, sign);
  
  // Perform transformation for the case where |x| > 0.5. We rely on
  // sqrtd2 producing a NAN is |x| > 1.0.
  x_trans = _sqrtd2(spu_nmsub(x_abs, half, half));
  
  // Determine the correct addend and multiplier.
  x_neg = (vec_double2)spu_rlmaska((vec_int4)spu_shuffle(x, x, splat_hi), -31);

  x_gt_half = spu_cmpgt((vec_uint4)x_abs, (vec_uint4)half);
  x_eq_half = spu_cmpeq((vec_uint4)x_abs, (vec_uint4)half);
  x_gt_half = spu_or(x_gt_half, spu_and(x_eq_half, spu_rlqwbyte(x_gt_half, 4)));
  x_gt_half = spu_shuffle(x_gt_half, x_gt_half, splat_hi);

  addend = spu_sel(spu_splats(SM_PI_2), spu_and(spu_splats(SM_PI), x_neg), (vec_ullong2)x_gt_half);

  multiplier = spu_sel(spu_splats(-1.0), spu_sel(spu_splats(2.0), x, (vec_ullong2)sign), (vec_ullong2)x_gt_half);

  // Select whether to use the x or the transformed x for the polygon evaluation.
  // if |x| > 0.5 use x_trans
  // else         use x

  x = spu_sel(x, x_trans, (vec_ullong2)x_gt_half);

  // Compute the polynomials.

  x2 = spu_mul(x, x);
  x3 = spu_mul(x2, x);
  
  p = spu_madd(spu_splats(0.004253011369004428248960), x2, spu_splats(-0.6019598008014123785661));
  p = spu_madd(p, x2, spu_splats(5.444622390564711410273));
  p = spu_madd(p, x2, spu_splats(-16.26247967210700244449));
  p = spu_madd(p, x2, spu_splats(19.56261983317594739197));
  p = spu_madd(p, x2, spu_splats(-8.198089802484824371615));

  q = spu_add(x2, spu_splats(-14.74091372988853791896));
  q = spu_madd(q, x2, spu_splats(70.49610280856842141659));
  q = spu_madd(q, x2, spu_splats(-147.1791292232726029859));
  q = spu_madd(q, x2, spu_splats(139.5105614657485689735));
  q = spu_madd(q, x2, spu_splats(-49.18853881490881290097));
  
  // Compute the rational solution p/q and final multiplication and addend 
  // correction.
  pq = _divd2(p, q);

  result = spu_madd(spu_madd(x3, pq, x), multiplier, addend);

  return (result);
}

#endif /* _ACOSD2_H_ */
#endif /* __SPU__ */

