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
#ifndef _DIVF4_H_
#define _DIVF4_H_	1

#include <spu_intrinsics.h>

/*
 * FUNCTION
 * 	vector float _divf4(vector float dividend, vector float divisor)
 * 
 * DESCRIPTION
 * 	The _divf4 function divides the vector dividend by the vector divisor
 *      and returns the resulting vector quotient.
 *
 */
static __inline vector float _divf4(vector float a, vector float b)
{

  /* This function has been designed to provide a
   * full function operation that presisely computes
   * the quotient for the entire range of extended
   * single precision inputs <a> and <b>. This includes:
   *
   * 1) Computing the quotient to full single precision
   *    floating point accuracy.
   * 2) Round the result consistently with the rounding
   *    mode of the processor - truncated toward zero.
   * 3) Underflow and overflow results are clamped to
   *    Smin and Smax and flagged with the appropriate
   *    UNF or OVF exception in the FPSCR.
   * 4) Divide By Zero (DBZ) exception is produced when
   *    the divisor <b> has a zero exponent. A quotient
   *    of correctly signed Smax is produced.
   * 5) Denorm/zero divided by a denorm/zero generates 
   *    a DBZ with the results undefined.
   * 6) Resulting denorm quotients will be coerced to +0.
   * 7) If a non-compliant IEEE result is produced, the
   *    a DIFF exception is generated.
   */

  vector float inv_b, err, q0, q1, q2;
  vector float mult;
  vector float mant_a, mant_b;
  vector float one = spu_splats(1.0f);
  vector unsigned int exp, exp_a, exp_b, overflow;
  vector unsigned int exp_mask = (vec_uint4)spu_splats(0x7F800000);

  /* If b has a zero exponent, then set the divide by zero
   * (DBZ) exception flag. The estimate result is discarded.
   * Note: This must be implemented as inline assembly. Otherwise
   * the optimizer removes it.
   */
  (void)si_frest((qword)(b));
  
  /* For computing the quotient, force the divisor and 
   * dividend into the range (1.0 <= 0 < 2.0).
   */
  mant_a = spu_sel(a, one, exp_mask);
  mant_b = spu_sel(b, one, exp_mask);

  /* Compute the quotient using reciprocal estimate
   * followed by one iteration of the Newton-Raphson.
   */
  inv_b = spu_re(mant_b);
  q0 = spu_mul(mant_a, inv_b);
  q1 = spu_nmsub(mant_b, q0, mant_a);
  q1 = spu_madd(inv_b, q1, q0);

  /* Due to truncation error, the quotient result
   * may be low by 1 ulp (unit of least position),
   * Conditionally add one if the estimate is too
   * small.
   */
  q2 = (vector float)spu_add((vector unsigned int)(q1), 1);
  err = spu_nmsub(mant_b, q2, mant_a);
  q2 = spu_sel(q1, q2, spu_cmpgt((vector signed int)err, -1));


  /* Compute the quotient's expected exponent. If the exponent
   * is out of range, then force the resulting exponent to 0.
   * (127 with the bias). We correct for the out of range 
   * values by computing a multiplier (mult) that will force the 
   * result to the correct out of range value and set the 
   * correct exception flag (UNF, OVF, or neither). The multiplier
   * is also conditioned to generate correctly signed Smax if the 
   * divisor b is a denorm or zero.
   */
  exp_a = spu_and((vector unsigned int)a, exp_mask);
  exp_b = spu_and((vector unsigned int)b, exp_mask);
  exp   = spu_add(spu_sub(spu_add(exp_a, (vector unsigned int)one), exp_b), spu_cmpabsgt(mant_b, mant_a));

  /* The default multiplier is 1.0. If an underflow is detected (ie, 
   * either the dividend <a> is a denorm/zero, or the computed exponent is 
   * less than or equal to a biased 0), force the multiplier to 0.0.
   */
  mult = spu_and(one, (vector float)spu_cmpgt((vector signed int)exp, 0));

  /* Force the multiplier to positive Smax (0x7FFFFFFF) and the biased exponent 
   * to 127, if the divisor is denorm/zero or the computed biased exponent is 
   * greater than 255.
   */

  overflow = spu_or(spu_cmpeq(exp_b, 0), spu_cmpeq(spu_rlmask(exp, -30), 2));
  exp = spu_sel(exp, (vector unsigned int)one, overflow);

  mult = spu_or(mult, (vector float)spu_rlmask(overflow, -1));
  mult = spu_andc(mult, (vector float)spu_cmpeq(exp_a, 0));

  /* Insert the exponent into the result and perform the
   * final multiplication.
   */
  q2    = spu_sel(q2, (vector float)exp, exp_mask);
  q2    = spu_mul(q2, mult);

  return (q2);

}

#endif /* _DIVF4_H_ */
#endif /* __SPU__ */
