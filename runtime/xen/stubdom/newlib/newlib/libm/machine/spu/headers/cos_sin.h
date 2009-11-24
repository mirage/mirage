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
#ifndef _COS_SIN_H_
#define _COS_SIN_H_	1

#define M_PI_OVER_4_HI_32 0x3fe921fb

#define M_PI_OVER_4	0.78539816339744827900
#define M_FOUR_OVER_PI 	1.27323954478442180616

#define M_PI_OVER_2	1.57079632679489655800
#define M_PI_OVER_2_HI 	1.57079632673412561417
#define M_PI_OVER_2_LO 	0.0000000000607710050650619224932

#define M_PI_OVER_2F_HI   1.570312500000000000
#define M_PI_OVER_2F_LO	  0.000483826794896558

/* The following coefficients correspond to the Taylor series
 * coefficients for cos and sin.
 */
#define COS_14 -0.00000000001138218794258068723867
#define COS_12  0.000000002087614008917893178252
#define COS_10 -0.0000002755731724204127572108
#define COS_08  0.00002480158729870839541888
#define COS_06 -0.001388888888888735934799
#define COS_04  0.04166666666666666534980
#define COS_02 -0.5000000000000000000000
#define COS_00  1.0

#define SIN_15 -0.00000000000076471637318198164759
#define SIN_13  0.00000000016059043836821614599
#define SIN_11 -0.000000025052108385441718775
#define SIN_09  0.0000027557319223985890653
#define SIN_07 -0.0001984126984126984127
#define SIN_05  0.008333333333333333333
#define SIN_03 -0.16666666666666666666
#define SIN_01  1.0


/* Compute the following for each floating point element of x. 
 * 	x  = fmod(x, PI/4); 
 *  	ix = (int)x * PI/4;
 * This allows one to compute cos / sin over the limited range
 * and select the sign and correct result based upon the octant
 * of the original angle (as defined by the ix result).
 *
 * Expected Inputs Types: 
 * 	x  = vec_float4
 *	ix = vec_int4
 */
#define MOD_PI_OVER_FOUR_F(_x, _ix) {					\
    vec_float4 fx;							\
									\
    _ix = spu_convts(spu_mul(_x, spu_splats((float)M_FOUR_OVER_PI)), 0); \
    _ix = spu_add(_ix, spu_add(spu_rlmaska((vec_int4)_x, -31), 1));	\
									\
    fx = spu_convtf(spu_rlmaska(_ix, -1), 0);				\
    _x  = spu_nmsub(fx, spu_splats((float)M_PI_OVER_2F_HI), _x);	\
    _x  = spu_nmsub(fx, spu_splats((float)M_PI_OVER_2F_LO), _x);	\
  }

/* Double precision MOD_PI_OVER_FOUR
 *
 * Expected Inputs Types: 
 * 	x  = vec_double2
 *	ix = vec_int4
 */
#define MOD_PI_OVER_FOUR(_x, _ix) {					\
    vec_float4 fx;							\
    vec_double2 dix;							\
									\
    fx = spu_roundtf(spu_mul(_x, spu_splats(M_FOUR_OVER_PI)));	\
    _ix = spu_convts(fx, 0);						\
    _ix = spu_add(_ix, spu_add(spu_rlmaska((vec_int4)fx, -31), 1));	\
									\
    dix = spu_extend(spu_convtf(spu_rlmaska(_ix, -1), 0));		\
    _x  = spu_nmsub(spu_splats(M_PI_OVER_2_HI), dix, _x);		\
    _x  = spu_nmsub(spu_splats(M_PI_OVER_2_LO), dix, _x);		\
  }


/* Compute the cos(x) and sin(x) for the range reduced angle x.
 * In order to compute these trig functions to full single precision
 * accuracy, we solve the Taylor series.
 *
 *   c = cos(x) = 1 - x^2/2! + x^4/4! - x^6/6! + x^8/8! - x^10/10!
 *   s = sin(x) = x - x^3/4! + x^5/5! - x^7/7! + x^9/9! - x^11/11!
 *
 * Expected Inputs Types: 
 * 	x = vec_float4
 *	c = vec_float4
 *	s = vec_float4
 */

#define COMPUTE_COS_SIN_F(_x, _c, _s) {					\
    vec_float4 x2, x4, x6;						\
    vec_float4 cos_hi, cos_lo;						\
    vec_float4 sin_hi, sin_lo;						\
									\
    x2 = spu_mul(_x, _x);						\
    x4 = spu_mul(x2, x2);						\
    x6 = spu_mul(x2, x4);						\
									\
    cos_hi = spu_madd(spu_splats((float)COS_10), x2, spu_splats((float)COS_08)); \
    cos_lo = spu_madd(spu_splats((float)COS_04), x2, spu_splats((float)COS_02)); \
    cos_hi = spu_madd(cos_hi, x2, spu_splats((float)COS_06));		\
    cos_lo = spu_madd(cos_lo, x2, spu_splats((float)COS_00));		\
    _c     = spu_madd(cos_hi, x6, cos_lo);				\
									\
    sin_hi = spu_madd(spu_splats((float)SIN_11), x2, spu_splats((float)SIN_09)); \
    sin_lo = spu_madd(spu_splats((float)SIN_05), x2, spu_splats((float)SIN_03)); \
    sin_hi = spu_madd(sin_hi, x2, spu_splats((float)SIN_07));		\
    sin_lo = spu_madd(sin_lo, x2, spu_splats((float)SIN_01));		\
    _s    = spu_madd(sin_hi, x6, sin_lo);				\
    _s     = spu_mul(_s, _x);						\
  }


/* Compute the cos(x) and sin(x) for the range reduced angle x.
 * This version computes the cosine and sine to double precision 
 * accuracy using the Taylor series:
 *
 *   c = cos(x) = 1 - x^2/2! + x^4/4! - x^6/6! + x^8/8! - x^10/10! + x^12/12! - x^14/14!
 *   s = sin(x) = x - x^3/4! + x^5/5! - x^7/7! + x^9/9! - x^11/11! + x^13/13! - x^15/15!
 *
 * Expected Inputs Types: 
 * 	x = vec_double2
 *	c = vec_double2
 *	s = vec_double2
 */

#define COMPUTE_COS_SIN(_x, _c, _s) {					\
    vec_double2 x2, x4, x8;						\
    vec_double2 cos_hi, cos_lo;						\
    vec_double2 sin_hi, sin_lo;						\
									\
    x2 = spu_mul(_x, _x);						\
    x4 = spu_mul(x2, x2);						\
    x8 = spu_mul(x4, x4);						\
									\
    cos_hi = spu_madd(spu_splats(COS_14), x2, spu_splats(COS_12));	\
    cos_lo = spu_madd(spu_splats(COS_06), x2, spu_splats(COS_04));	\
    cos_hi = spu_madd(cos_hi, x2, spu_splats(COS_10));			\
    cos_lo = spu_madd(cos_lo, x2, spu_splats(COS_02));			\
    cos_hi = spu_madd(cos_hi, x2, spu_splats(COS_08));			\
    cos_lo = spu_madd(cos_lo, x2, spu_splats(COS_00));			\
    _c     = spu_madd(cos_hi, x8, cos_lo);				\
									\
    sin_hi = spu_madd(spu_splats(SIN_15), x2, spu_splats(SIN_13));	\
    sin_lo = spu_madd(spu_splats(SIN_07), x2, spu_splats(SIN_05));	\
    sin_hi = spu_madd(sin_hi, x2, spu_splats(SIN_11));			\
    sin_lo = spu_madd(sin_lo, x2, spu_splats(SIN_03));			\
    sin_hi = spu_madd(sin_hi, x2, spu_splats(SIN_09));			\
    sin_lo = spu_madd(sin_lo, x2, spu_splats(SIN_01));			\
    _s     = spu_madd(sin_hi, x8, sin_lo);				\
    _s     = spu_mul(_s, _x);						\
  }




#endif /* _COS_SIN_H_ */
#endif /* __SPU__ */


