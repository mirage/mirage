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

#ifndef _EXP2D2_H_
#define _EXP2D2_H_	1

#include <spu_intrinsics.h>


/*
 * FUNCTION
 *	vector double _exp2d2(vector double x)
 *
 * DESCRIPTION
 *	_exp2d2 computes 2 raised to the input x for each
 *	of the double word elements of x. Computation is 
 *	performed by observing the 2^(a+b) = 2^a * 2^b.
 *	We decompose x into a and b (above) by letting.
 *	a = ceil(x), b = x - a; 
 *
 *	2^a is easily computed by placing a into the exponent
 *	or a floating point number whose mantissa is all zeros.
 *
 *	2^b is computed using the polynomial approximation.
 *
 *             __13_
 *	       \
 *	        \ 
 *	2^x =   /     Ci*x^i
 *             /____
 *              i=0
 *
 *	for x in the range 0.0 to 1.0.
 *
 */
#define EXP_C00    1.0
#define EXP_C01    6.93147180559945286227e-01
#define EXP_C02    2.40226506959100694072e-01
#define EXP_C03    5.55041086648215761801e-02
#define EXP_C04    9.61812910762847687873e-03
#define EXP_C05    1.33335581464284411157e-03
#define EXP_C06    1.54035303933816060656e-04
#define EXP_C07    1.52527338040598376946e-05
#define EXP_C08    1.32154867901443052734e-06
#define EXP_C09    1.01780860092396959520e-07
#define EXP_C10    7.05491162080112087744e-09
#define EXP_C11    4.44553827187081007394e-10
#define EXP_C12    2.56784359934881958182e-11
#define EXP_C13    1.36914888539041240648e-12

static __inline vector double _exp2d2(vector double vx) 
{
  vec_int4 ix, exp;
  vec_uint4 overflow, underflow;
  vec_float4 vxf;
  vec_double2 p1, p2, x2, x4, x8;
  vec_double2 vy, vxw, out_of_range;

  /* Compute:  vxw = x - ceil(x)
   */
  vxw = spu_add(vx, spu_splats(0.5));
  vxf = spu_roundtf(vxw);
  ix  = spu_convts(vxf, 0);
  ix  = spu_add(ix, (vec_int4)spu_andc(spu_cmpgt(spu_splats(0.0f), vxf), spu_cmpeq(ix, spu_splats((int)0x80000000))));
  vxf = spu_convtf(ix, 0);
  vxw = spu_sub(vx, spu_extend(vxf));

  /* Detect overflow and underflow. If overflow, force the result
   * to infinity (at the end).
   */
  exp = spu_shuffle(ix, ix, ((vec_uchar16) { 0,1,2,3, 0,1,2,3, 8,9,10,11, 8,9,10,11 }));

  overflow = spu_cmpgt(exp, 1023);
  underflow = spu_cmpgt(exp, -1023);
  out_of_range = (vec_double2)spu_and(overflow, ((vec_uint4) { 0x7FF00000, 0, 0x7FF00000, 0 }));

  /* Calculate the result by evaluating the 13th order polynomial.
   * For efficiency, the polynomial is broken into two parts and
   * evaluate then using nested 
   *
   *  result = (((((c13*x + c12)*x + c11)*x + c10)*x + c9)*x + c8)*x^8 +
   *           ((((((c7*x + c6)*x + c5)*x + c4)*x + c3)*x + c2)*x + c1)*x + c0
   */
  p2 = spu_madd(spu_splats(EXP_C07), vxw, spu_splats(EXP_C06));
  p1 = spu_madd(spu_splats(EXP_C13), vxw, spu_splats(EXP_C12));
  x2 = spu_mul(vxw, vxw);
  p2 = spu_madd(vxw, p2, spu_splats(EXP_C05));
  p1 = spu_madd(vxw, p1, spu_splats(EXP_C11));
  x4 = spu_mul(x2, x2);
  p2 = spu_madd(vxw, p2, spu_splats(EXP_C04));
  p1 = spu_madd(vxw, p1, spu_splats(EXP_C10));
  p2 = spu_madd(vxw, p2, spu_splats(EXP_C03));
  p1 = spu_madd(vxw, p1, spu_splats(EXP_C09));
  x8 = spu_mul(x4, x4);
  p2 = spu_madd(vxw, p2, spu_splats(EXP_C02));
  p1 = spu_madd(vxw, p1, spu_splats(EXP_C08));
  p2 = spu_madd(vxw, p2, spu_splats(EXP_C01));
  p2 = spu_madd(vxw, p2, spu_splats(EXP_C00));
  vy = spu_madd(x8, p1, p2);

  /*  Align the integer integer portion of x with the exponent.
   */
  ix = spu_sl(ix, ((vec_uint4) { 20, 32, 20, 32 }));
  vy = (vec_double2)spu_add((vec_int4)vy, ix);
   
  /* Select the result if not overflow or underflow. Otherwise select the 
   * the out of range value.
   */
  return (spu_sel(vy, out_of_range, (vec_ullong2)spu_orc(overflow, underflow)));
}

#endif /* _EXP2D2_H_ */
#endif /* __SPU__ */
