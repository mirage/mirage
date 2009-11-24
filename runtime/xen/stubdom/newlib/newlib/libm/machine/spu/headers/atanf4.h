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

#ifndef _ATANF4_H_
#define _ATANF4_H_	1

#include <spu_intrinsics.h>

#include "simdmath.h"
#include "recipf4.h"

/*
 * FUNCTION
 *	vector float _atanf4(vector float x)
 *
 * DESCRIPTION
 *	The _atanf4 function computes the arc tangent of a vector of values x; 
 *      that is the values whose tangent is x.
 *
 *	The _atanf4 function returns the arc tangents in radians and the value 
 *      is mathematically defined to be in the range -PI/2 to PI/2.
 *
 *	The arc tangent function is computed using a polynomial approximation
 *	(B. Carlson, M. Goldstein, Los Alamos Scientific Laboratory, 1955).
 *                __8__
 *		  \
 *		   \ 
 *	atan(x) =  /    Ci*x^(2*i+1)
 *                /____
 *                 i=0
 *
 *	for x in the range -1 to 1. The remaining regions are defined to be:
 *
 *	[1, infinity]   :  PI/2 + atanf(-1/x)
 *	[-infinity, -1] : -PI/2 + atanf(-1/x)
 *
 */
static __inline vector float _atanf4(vector float x)
{
  vector float bias;
  vector float x2, x3, x4, x8, x9;
  vector float hi, lo;
  vector float result;
  vector float inv_x;
  vector unsigned int sign;
  vector unsigned int select;

  sign = spu_sl(spu_rlmask((vector unsigned int)x, -31), 31);
  inv_x = _recipf4(x);
  inv_x = (vector float)spu_xor((vector unsigned int)inv_x, spu_splats(0x80000000));

  select = (vector unsigned int)spu_cmpabsgt(x, spu_splats(1.0f));
  bias = (vector float)spu_or(sign, (vector unsigned int)(spu_splats((float)SM_PI_2)));
  bias = (vector float)spu_and((vector unsigned int)bias, select);

  x = spu_sel(x, inv_x, select);

  /* Instruction counts can be reduced if the polynomial was
   * computed entirely from nested (dependent) fma's. However, 
   * to reduce the number of pipeline stalls, the polygon is evaluated 
   * in two halves(hi and lo).
   */
  bias = spu_add(bias, x);
  x2 = spu_mul(x, x);
  x3 = spu_mul(x2, x);
  x4 = spu_mul(x2, x2);
  x8 = spu_mul(x4, x4);
  x9 = spu_mul(x8, x);
  hi = spu_madd(spu_splats(0.0028662257f), x2, spu_splats(-0.0161657367f));
  hi = spu_madd(hi, x2, spu_splats(0.0429096138f));
  hi = spu_madd(hi, x2, spu_splats(-0.0752896400f));
  hi = spu_madd(hi, x2, spu_splats(0.1065626393f));
  lo = spu_madd(spu_splats(-0.1420889944f), x2, spu_splats(0.1999355085f));
  lo = spu_madd(lo, x2, spu_splats(-0.3333314528f));
  lo = spu_madd(lo, x3, bias);
  
  result = spu_madd(hi, x9, lo);

  return (result);
}

#endif /* _ATANF4_H_ */
#endif /* __SPU__ */


