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
#ifndef _RECIPF4_H_
#define _RECIPF4_H_		1

#include <spu_intrinsics.h>

/*
 * FUNCTION
 *	vector float _recipf4(vector float value)
 * 
 * DESCRIPTION
 * 	The _recipf4 function inverts the vector "value" and returns the 
 *      result.
 *
 */ 
static __inline vector float _recipf4(vector float a)
{
  /* This function has been designed to provide a
   * full function operation that presisely computes
   * the reciprocal for the entire range of extended
   * single precision input <a>. This includes:
   *
   * 1) Computing the reciprocal to full single precision
   *    floating point accuracy.
   * 2) Round the result consistently with the rounding
   *    mode of the processor - truncated toward zero.
   * 3) Underflow and overflow results are clamped to
   *    Smin and Smax and flagged with the appropriate
   *    UNF or OVF exception in the FPSCR.
   * 4) Divide By Zero (DBZ) exception is produced when
   *    the input <a> has a zero exponent. A reciprocal
   *    of correctly signed Smax is produced.
   * 5) Resulting denorm reciprocal will be coerced to +0.
   * 6) If a non-compliant IEEE result is produced, the
   *    a DIFF exception is generated.
   */
  vector float err, x0, x1;
  vector float mult;
  vector float mant_a;
  vector float one = spu_splats(1.0f);
  vector unsigned int exp, exp_a;
  vector unsigned int exp_mask = (vec_uint4)spu_splats(0x7F800000);

  /* If a has a zero exponent, then set the divide by zero
   * (DBZ) exception flag. The estimate result is discarded.
   */
  (void)si_frest((qword)(a));

  /* For computing the reciprocal, force the value
   * into the range (1.0 <= 0 < 2.0).
   */
  mant_a = spu_sel(a, one, exp_mask);

  /* Compute the reciprocal using the reciprocal estimate
   * followed by one iteration of the Newton-Raphson. 
   * Due to truncation error, the quotient result may be low 
   * by 1 ulp (unit of least position). Conditionally add one
   * if the estimate is too small.
   */
  x0 = spu_re(mant_a);
  x0  = spu_madd(spu_nmsub(mant_a, x0, one), x0, x0);

  x1 = (vector float)(spu_add((vector unsigned int)(x0), 1));
  err = spu_nmsub(mant_a, x1, one);

  x1 = spu_sel(x0, x1, spu_cmpgt((vector signed int)(err), -1));

  /* Compute the reciprocal's expected exponent. If the exponent
   * is out of range, then force the resulting exponent to 0.
   * (127 with the bias). We correct for the out of range 
   * values by computing a multiplier (mult) that will force the 
   * result to the correct out of range value and set the 
   * correct exception flag (UNF, OVF, or neither). The multiplier
   * is also conditioned to generate correctly signed Smax if the 
   * inoput <a> is a denorm or zero.
   */
  exp_a = spu_and((vector unsigned int)a, exp_mask);
  exp   = spu_add(spu_sub(spu_splats((unsigned int)0x7F000000), exp_a), spu_cmpabsgt(mant_a, one));

  /* The default multiplier is 1.0. If an underflow is detected (ie, 
   * either the dividend <a> is a denorm/zero, or the computed exponent is 
   * less than or equal to a biased 0), force the multiplier to 0.0.
   */
  mult = spu_and(one, (vector float)spu_cmpgt((vector signed int)(exp), 0));

  /* Force the multiplier to positive Smax (0x7FFFFFFF) and the biased exponent 
   * to 127, if the divisor is denorm/zero or the computed biased exponent is 
   * greater than 255.
   */
  mult = spu_or(mult, (vector float)spu_rlmask(spu_cmpeq(exp_a, 0), -1));

  /* Insert the exponent into the result and perform the
   * final multiplication.
   */
  x1    = spu_sel(x1, (vector float)exp, exp_mask);
  x1    = spu_mul(x1, mult);

  return (x1);
}

#endif /* _RECIPF4_H_ */
#endif /* __SPU__ */
