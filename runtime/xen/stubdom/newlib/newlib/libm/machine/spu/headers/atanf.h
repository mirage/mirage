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
#ifndef _ATANF_H_
#define _ATANF_H_	1

#ifndef M_PI_2
#define M_PI_2		1.5707963267949f
#endif /* M_PI_2 */

/*
 * FUNCTION
 *	float _atanf(float x)
 *
 * DESCRIPTION
 *	_atanf computes the arc tangent of the value x; that is the value
 *	whose tangent is x.
 *
 *	_atanf returns the arc tangent in radians and the value is
 *	mathematically defined to be in the range -PI/2 to PI/2.
 *
 *	The arc tangent function is computed using a polynomial approximation
 *	(B. Carlson, M. Goldstein, Los Alamos Scientific Laboratiry, 1955).
 *                __8__
 *		  \
 *		   \
 *	atanf(x) =  /    Ci*x^(2*i+1)
 *                /____
 *                 i=0
 *
 *	for x in the range -1 to 1. The remaining regions are defined to be:
 *
 *	[1, infinity]   :  PI/2 + atanf(-1/x)
 *	[-infinity, -1] : -PI/2 + atanf(-1/x)
 */

static __inline float _atanf(float x)
{
  float xabs;
  float bias;
  float x2, x3, x4, x8, x9;
  float hi, lo;
  float result;

  bias = 0.0f;
  xabs = (x < 0.0f) ? -x : x;

  if (xabs >= 1.0f) {
    bias = M_PI_2;
    if (x < 0.0f) {
      bias = -bias;
    }
    x = -1.0f / x;
  }
  /* Instruction counts can be reduced if the polynomial was
   * computed entirely from nested (dependent) fma's. However,
   * to reduce the number of pipeline stalls, the polygon is evaluated
   * in two halves(hi and lo).
   */
  bias += x;

  x2 = x * x;
  x3 = x2 * x;
  x4 = x2 * x2;
  x8 = x4 * x4;
  x9 = x8 * x;
  hi =  0.0028662257f * x2 - 0.0161657367f;
  hi =             hi * x2 + 0.0429096138f;
  hi =             hi * x2 - 0.0752896400f;
  hi =             hi * x2 + 0.1065626393f;
  lo = -0.1420889944f * x2 + 0.1999355085f;
  lo =             lo * x2 - 0.3333314528f;
  lo =             lo * x3 + bias;

  result = hi * x9 + lo;

  return (result);
}

#endif /* _ATANF_H_ */



