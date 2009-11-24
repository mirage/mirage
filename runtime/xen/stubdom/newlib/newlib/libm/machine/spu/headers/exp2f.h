/*
  (C) Copyright 2001,2006,
  International Business Machines Corporation,
  Sony Computer Entertainment, Incorporated,
  Toshiba Corporation,

  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
    * Neither the names of the copyright holders nor the names of their
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
  OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
#ifndef _EXP2F_H_
#define _EXP2F_H_	1

#ifndef M_LN2
#define M_LN2	0.69314718055994530942	/* ln(2) */
#endif /* M_LN2 */

/*
 * FUNCTION
 *	float _exp2f(float x)
 *
 * DESCRIPTION
 *	_exp2f computes 2 raised to the input x. Computation is
 *	performed by observing the 2^(a+b) = 2^a * 2^b.
 *	We decompose x into a and b (above) by letting.
 *	a = ceil(x), b = x - a;
 *
 *	2^a is easilty computed by placing a into the exponent
 *	or a floating point number whose mantissa is all zeros.
 *
 *	2^b is computed using the following polynomial approximation.
 *	(C. Hastings, Jr, 1955).
 *
 *             __7__
 *	       \
 *		\
 *	2^x =   /     Ci*x^i
 *             /____
 *              i=0
 *
 *	for x in the range 0.0 to 1.0
 *
 *	C0 =  1.0
 *	C1 = -0.9999999995
 *	C2 =  0.4999999206
 *	C3 = -0.1666653019
 *	C4 =  0.0416573475
 *	C5 = -0.0083013598
 *	C6 =  0.0013298820
 *	C7 = -0.0001413161
 *
 */
static __inline float _exp2f(float x)
{
  union {
    float f;
    unsigned int ui;
  } bias, exp_int, exp_frac;
  unsigned int overflow, underflow;
  int ix;
  float frac, frac2, frac4;
  float hi, lo;

  /* Break in the input x into two parts ceil(x), x - ceil(x).
   */
  bias.f = x;
  bias.ui = ~(unsigned int)((signed)(bias.ui) >> 31) & 0x3F7FFFFF;
  ix = (int)(x + bias.f);
  frac = (float)ix - x;
  frac *= (float)(M_LN2);

  exp_int.ui  = (ix + 127) << 23;

  overflow  = (ix > 128)  ? 0x7FFFFFFF : 0x0;
  underflow = (ix < -127) ? 0xFFFFFFFF : 0x0;

  /* Instruction counts can be reduced if the polynomial was
   * computed entirely from nested (dependent) fma's. However,
   * to reduce the number of pipeline stalls, the polygon is evaluated
   * in two halves (hi amd lo).
   */
  frac2 = frac  * frac;
  frac4 = frac2 * frac2;
  hi = -0.0001413161f * frac + 0.0013298820f;
  hi =             hi * frac - 0.0083013598f;
  hi =             hi * frac + 0.0416573475f;
  lo = -0.1666653019f * frac + 0.4999999206f;
  lo =             lo * frac - 0.9999999995f;
  lo =             lo * frac + 1.0f;
  exp_frac.f =     hi * frac4 + lo;

  ix += exp_frac.ui >> 23;
  exp_frac.f *= exp_int.f;

  exp_frac.ui = (exp_frac.ui | overflow) & ~underflow;

  return (exp_frac.f);
}

#endif /* _EXP2F_H_ */


