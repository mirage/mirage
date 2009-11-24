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
#ifndef _TANF4_H_
#define _TANF4_H_	1

#include <spu_intrinsics.h>

#include "cos_sin.h"
#include "divf4.h"

/*
 * FUNCTION
 *	vector float _tanf4(vector float angle)
 *
 * DESCRIPTION
 *	The _tanf4 function computes the tangent of a vector of "angle"s 
 *      (expressed in radians) to an accuracy of single precision floating 
 *      point.
 *
 */
static __inline vector float _tanf4(vector float angle)
{
  vec_int4   octant;
  vec_uint4  select;
  vec_float4 cos, sin;
  vec_float4 num, den;
  vec_float4 toggle_sign, answer;

  /* Range reduce the input angle x into the range -PI/4 to PI/4
   * by performing simple modulus.
   */
  MOD_PI_OVER_FOUR_F(angle, octant);

  /* Compute the cosine and sine of the range reduced input.
   */
  COMPUTE_COS_SIN_F(angle, cos, sin);

  /* For each SIMD element, select the numerator, denominator, and sign
   * correction depending upon the octant of the original angle.
   *
   *   octants      angles     numerator denominator sign toggle 
   *   -------   ------------  --------- ----------- -----------
   *     0          0 to 45      sin        cos          no      
   *    1,2        45 to 135     cos        sin         no,yes
   *    3,4       135 to 225     sin        cos         yes,no
   *    5,6       225 to 315     cos        sin         no,yes
   *     7        315 to 360     sin        cos          yes
   */ 
  toggle_sign = (vec_float4)spu_sl(spu_and(octant, 2), 30);

  select = spu_cmpeq(spu_and(octant, 2), 0);
  num = spu_sel(cos, sin, select);
  den = spu_sel(sin, cos, select);

  answer = spu_xor(_divf4(num, den), toggle_sign);

  return (answer);
}

#endif /* _TANF4_H_ */
#endif /* __SPU__ */
