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

#ifndef _DIVD2_H_
#define _DIVD2_H_		 1

#include <spu_intrinsics.h>

/*
 * FUNCTION
 * 	vector double _divd2(vector double a, vector double b)
 * 
 * DESCRIPTION
 * 	_divd2 divides the vector dividend a by the vector divisor b and 
 *      returns the resulting vector quotient.  Maximum error 0.5 ULPS for 
 *      normalized results, 1ulp for denorm results, over entire double 
 *      range including denorms, compared to true result in round-to-nearest
 *      rounding mode.  Handles Inf or NaN operands and results correctly.
 */
static __inline vector double _divd2(vector double a, vector double b)
{


  /* Variables
   */
  vec_float4 inv_bf, mant_bf;
  vec_double2 mant_a, mant_b, inv_b, q0, q1, q2, mult;
  vec_int4 exp, tmp;
  vec_uint4 exp_a, exp_b, exp_q1, overflow, nounderflow, normal, utmp,
    sign_a, sign_b, a_frac, b_frac, a_frac_0, b_frac_0, a_exp_0, b_exp_0, 
    a_exp_ones, b_exp_ones, a_nan, b_nan, a_inf, b_inf, a_zero, b_zero, 
    res_nan, sign_res;

  /* Constants
   */
  vec_float4 onef = spu_splats(1.0f);
  vec_double2 one = spu_splats(1.0);
  vec_uint4 exp_mask = (vec_uint4) { 0x7FF00000, 0, 0x7FF00000, 0 };
  vec_uint4 sign_mask = (vec_uint4) { 0x80000000, 0, 0x80000000, 0};
  vec_uint4 sign_exp_mask = (vec_uint4) { 0xFFF00000, 0, 0xFFF00000,0};
  vec_uint4 frac_mask =(vec_uint4) { 0x000FFFFF, 0xFFFFFFFF, 0x000FFFFF, 0xFFFFFFFF };
  vec_uchar16 swap32 = (vec_uchar16) ((vec_uint4) { 0x04050607, 0x00010203, 0x0C0D0E0F, 0x08090A0B} );
  vec_uint4 zero = (vec_uint4) { 0, 0, 0, 0 };
  vec_int4 e1022 = (vec_int4) { 0x000003FE, 0, 0x000003FE, 0 };
  vec_int4 emax  = (vec_int4) { 0x000007FE, 0, 0x000007FE, 0 };
  vec_int4 e1    = (vec_int4) { 0x00000001, 0, 0x00000001, 0 };

  vec_uint4 nan  = (vec_uint4) { 0x7FF80000, 0, 0x7FF80000, 0};

  /* Extract exponents and underflow denorm arguments to signed zero.
   */
  exp_a = spu_and((vec_uint4)a, exp_mask);
  exp_b = spu_and((vec_uint4)b, exp_mask);

  sign_a = spu_and((vec_uint4)a, sign_mask);
  sign_b = spu_and((vec_uint4)b, sign_mask);

  a_exp_0 = spu_cmpeq (exp_a, 0);
  utmp = spu_shuffle (a_exp_0, a_exp_0, swap32);
  a_exp_0 = spu_and (a_exp_0, utmp);
  b_exp_0 = spu_cmpeq (exp_b, 0);
  utmp = spu_shuffle (b_exp_0, b_exp_0, swap32);
  b_exp_0 = spu_and (b_exp_0, utmp);

  a = spu_sel(a, (vec_double2)sign_a, (vec_ullong2)a_exp_0);
  b = spu_sel(b, (vec_double2)sign_b, (vec_ullong2)b_exp_0);

  /* Force the divisor and dividend into the range [1.0,2.0).
     (Unless they're zero.)
  */
  mant_a = spu_sel(a, one, (vec_ullong2)sign_exp_mask);
  mant_b = spu_sel(b, one, (vec_ullong2)sign_exp_mask);

  /* Approximate the single reciprocal of b by using
   * the single precision reciprocal estimate followed by one 
   * single precision iteration of Newton-Raphson.
   */
  mant_bf = spu_roundtf(mant_b);
  inv_bf = spu_re(mant_bf);
  inv_bf = spu_madd(spu_nmsub(mant_bf, inv_bf, onef), inv_bf, inv_bf);

  /* Perform 2 more Newton-Raphson iterations in double precision.
   */
  inv_b = spu_extend(inv_bf);
  inv_b = spu_madd(spu_nmsub(mant_b, inv_b, one), inv_b, inv_b);
  q0 = spu_mul(mant_a, inv_b);
  q1 = spu_madd(spu_nmsub(mant_b, q0, mant_a), inv_b, q0);

  /* Compute the quotient's expected exponent. If the exponent
   * is out of range, then force the resulting exponent to 0.
   * (1023 with the bias). We correct for the out of range 
   * values by computing a multiplier (mult) that will force the 
   * result to the correct out of range value and set the 
   * correct exception flag (UNF, OVF, or neither).
   */
  exp_q1 = spu_and((vec_uint4)q1, exp_mask);
  exp = spu_sub((vec_int4)exp_a, (vec_int4)exp_b);
  exp = spu_rlmaska(exp, -20);  // shift right to allow enough bits for working
  tmp = spu_rlmaska((vec_int4)exp_q1, -20);
  exp = spu_add(exp, tmp);  // biased exponent of result (right justified)

  /* The default multiplier is 1.0. If an underflow is detected (the computed 
   * exponent is less than or equal to a biased 0), force the multiplier to 0.0.
   * If exp<=0 set mult = 2**(unbiased exp + 1022) and unbiased exp = -1022
   * = biased 1, the smallest normalized exponent.  If exp<-51 set 
   * mult = 2**(-1074) to ensure underflowing result.  Otherwise mult=1.
   */
  normal = spu_cmpgt(exp, 0);
  nounderflow = spu_cmpgt(exp, -52);
  tmp = spu_add(exp, e1022);
  mult = (vec_double2)spu_sl(tmp, 20);
  mult = spu_sel(mult, one, (vec_ullong2)normal);
  mult = spu_sel((vec_double2)e1, mult, (vec_ullong2)nounderflow);
  exp = spu_sel(e1, exp, normal);  // unbiased -1022 is biased 1

  /* Force the multiplier to positive infinity (exp_mask) and the biased 
   * exponent to 1022, if the computed biased exponent is > emax.
   */
  overflow = spu_cmpgt(exp, (vec_int4)emax);
  exp = spu_sel(exp, (vec_int4)e1022, overflow);
  mult = spu_sel(mult, (vec_double2)exp_mask, (vec_ullong2)overflow);

  /* Determine if a, b are Inf, NaN, or zero.
   * Since these are rare, it would improve speed if these could be detected
   * quickly and a branch used to avoid slowing down the main path.  However
   * most of the work seems to be in the detection.
   */
  a_exp_ones = spu_cmpeq (exp_a, exp_mask);
  utmp = spu_shuffle (a_exp_ones, a_exp_ones, swap32);
  a_exp_ones = spu_and (a_exp_ones, utmp);

  a_frac = spu_and ((vec_uint4)a, frac_mask);
  a_frac_0 = spu_cmpeq (a_frac, 0);
  utmp = spu_shuffle (a_frac_0, a_frac_0, swap32);
  a_frac_0 = spu_and (a_frac_0, utmp);

  a_zero = spu_and (a_exp_0, a_frac_0);
  a_inf = spu_and (a_exp_ones, a_frac_0);
  a_nan = spu_andc (a_exp_ones, a_frac_0);

  b_exp_ones = spu_cmpeq (exp_b, exp_mask);
  utmp = spu_shuffle (b_exp_ones, b_exp_ones, swap32);
  b_exp_ones = spu_and (b_exp_ones, utmp);

  b_frac = spu_and ((vec_uint4)b, frac_mask);
  b_frac_0 = spu_cmpeq (b_frac, 0);
  utmp = spu_shuffle (b_frac_0, b_frac_0, swap32);
  b_frac_0 = spu_and (b_frac_0, utmp);

  b_zero = spu_and (b_exp_0, b_frac_0);
  b_inf = spu_and (b_exp_ones, b_frac_0);
  b_nan = spu_andc (b_exp_ones, b_frac_0);

  /* Handle exception cases */

  /* Result is 0 for 0/x, x!=0, or x/Inf, x!=Inf.
   * Set mult=0 for 0/0 or Inf/Inf now, since it will be replaced 
   * with NaN later.
   */
  utmp = spu_or (a_zero, b_inf);
  mult = spu_sel(mult, (vec_double2)zero, (vec_ullong2)utmp);

  /* Result is Inf for x/0, x!=0.  Set mult=Inf for 0/0 now, since it
   * will be replaced with NaN later.
   */
  mult = spu_sel(mult, (vec_double2)exp_mask, (vec_ullong2)b_zero);

  /* Result is NaN if either operand is, or Inf/Inf, or 0/0.
   */
  res_nan = spu_or (a_nan, b_nan);
  utmp = spu_and (a_inf, b_inf);
  res_nan = spu_or (res_nan, utmp);
  utmp = spu_and (a_zero, b_zero);
  res_nan = spu_or (res_nan, utmp);
  mult = spu_sel(mult, (vec_double2)nan, (vec_ullong2)res_nan);
  
  /* Insert sign of result into mult.
   */
  sign_res = spu_xor (sign_a, sign_b);
  mult = spu_or (mult, (vec_double2)sign_res);

  /* Insert the sign and exponent into the result and perform the
   * final multiplication.
   */
  exp = spu_sl(exp, 20);
  q2 = spu_sel(q1, (vec_double2)exp, (vec_ullong2)exp_mask);
  q2 = spu_mul(q2, mult);

  return (q2);
}

#endif /* _DIVD2_H_ */
#endif /* __SPU__ */
