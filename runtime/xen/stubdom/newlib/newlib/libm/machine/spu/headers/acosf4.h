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

#ifndef _ACOSF4_H_
#define _ACOSF4_H_	1

#include <spu_intrinsics.h>

#include "divf4.h"
#include "sqrtf4.h"

/*
 * FUNCTION
 *	vector float _acosf4(vector float x)
 *
 * DESCRIPTION
 *	The _acosf4 function computes the arc cosine for a vector of values x; 
 *      that is the values whose cosine is x. Results are undefined if x is
 *      outside the range [-1, 1]. 
 *
 * RETURNS
 *	The _acosf4 function returns the arc cosine in radians and the value is
 * 	mathematically defined to be in the range [0, pi].
 *
 */
static __inline vector float _acosf4(vector float x)
{
  vec_float4 zero = spu_splats(0.0f);
  vec_float4 half = spu_splats(0.5f);
  vec_float4 one = spu_splats(1.0f);
  vec_float4 two = spu_splats(2.0f);
  vec_float4 pi = spu_splats(3.1415925026e+00f);
  vec_float4 pio2_hi = spu_splats(1.5707962513e+00f);
  vec_float4 pio2_lo = spu_splats(7.5497894159e-08f);

  vec_float4 snan = (vec_float4)spu_splats((unsigned int)0x7FC00000);
  vec_uint4 denorm_threshold = spu_splats((unsigned int)0x23000000);
  vec_uint4 sign_mask = spu_splats((unsigned int)0x80000000);


  vec_float4 p0 = (vec_float4)spu_splats((unsigned int)0x3E2AAAAB);
  vec_float4 p1 = (vec_float4)spu_splats((unsigned int)0xBEA6B090);
  vec_float4 p2 = (vec_float4)spu_splats((unsigned int)0x3E4E0AA8);
  vec_float4 p3 = (vec_float4)spu_splats((unsigned int)0xBD241146);
  vec_float4 p4 = (vec_float4)spu_splats((unsigned int)0x3A4F7F04);
  vec_float4 p5 = (vec_float4)spu_splats((unsigned int)0x3811EF08);

  vec_float4 q1 = (vec_float4)spu_splats((unsigned int)0xC019D139);
  vec_float4 q2 = (vec_float4)spu_splats((unsigned int)0x4001572D);
  vec_float4 q3 = (vec_float4)spu_splats((unsigned int)0xBF303361);
  vec_float4 q4 = (vec_float4)spu_splats((unsigned int)0x3D9DC62E);
					  

  vec_uint4 x_abs = spu_andc((vec_uint4)x,sign_mask);
  vec_uint4 x_pos = spu_cmpgt(sign_mask,(vec_uint4)x);


  vec_uint4 almost_half = spu_splats((unsigned int)0x3EFFFFFF);
  vec_uint4 sel0 = spu_nand(spu_splats((unsigned int)0xFFFFFFFF),spu_cmpgt(x_abs,almost_half));
  vec_uint4 sel1 = spu_andc(x_pos,sel0); // pos

  vec_float4 za = spu_sel(spu_sel(spu_add(one,x),spu_sub(one,x),sel1) ,x,sel0);
  vec_float4 zb = spu_sel(half,x,sel0);
   
  vec_float4 z = spu_mul(za,zb);

  vec_float4 p;
  p = spu_madd(z,p5,p4);
  p = spu_madd(p,z,p3);
  p = spu_madd(p,z,p2);
  p = spu_madd(p,z,p1);
  p = spu_madd(p,z,p0);
  p = spu_mul(p,z);
  
  vec_float4 q;
  q = spu_madd(z,q4,q3);
  q = spu_madd(q,z,q2);
  q = spu_madd(q,z,q1);
  q = spu_madd(q,z,one);

  // Only used by secondaries
  vec_float4 s = _sqrtf4(z);

  vec_float4 r = _divf4(p,q);

  vec_float4 w1 = spu_msub(r,s,pio2_lo);


  vec_float4 df = (vec_float4)spu_and((vec_uint4)s,0xFFFFF000);
  vec_float4 c = _divf4(spu_nmsub(df,df,z),spu_add(s,df));
  vec_float4 w2 = spu_madd(r,s,c);

  vec_float4 result0 = spu_sub(pio2_hi,spu_sub(x,spu_nmsub(x,r,pio2_lo)));


  vec_float4 result1 = spu_mul(two,spu_add(df,w2));
  vec_float4 result2 = spu_nmsub(two,spu_add(s,w1),pi);


  vec_float4 result;

  result = spu_sel(result2,result1,sel1);
  result = spu_sel(result,result0,sel0);

  //  If |x|==1 then:
  //    if   x == 1, return 0
  //    else         return pi

  vec_uint4 abs_one = spu_cmpeq(x_abs,(vec_uint4)one);
  vec_uint4 out_of_bounds = spu_cmpgt(x_abs,(vec_uint4)one);
  vec_uint4 underflow = spu_cmpgt(denorm_threshold,x_abs);



  result = spu_sel(result,spu_sel(pi,zero,x_pos),abs_one);
  
  //  If 1 < |x| then return sNaN
  result = spu_sel(result,snan,out_of_bounds);

  //  If |x| < 2**-57, then return pi/2  (OFF BY 1 ULP)
  result = spu_sel(result,spu_add(pio2_hi,pio2_lo),underflow);
    
  return result;
}

#endif /* _ACOSF4_H_ */
#endif /* __SPU__ */


