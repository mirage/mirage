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
#ifndef _LOG2F_H_
#define _LOG2F_H_	1

#include <spu_intrinsics.h>
#include "headers/dom_chkf_less_than.h"

/*
 * FUNCTION
 *	float _log2f(float x)
 *
 * DESCRIPTION
 *	_log2f computes log (base 2) of the input value x. The log2f
 *	function is approximated as a polynomial of order 8
 *	(C. Hastings, Jr, 1955).
 *
 *                   __8__
 *		     \
 *		      \
 *	log2f(1+x) =   /     Ci*x^i
 *                   /____
 *                    i=1
 *
 *	for x in the range 0.0 to 1.0
 *
 *	C1 =  1.4426898816672
 *	C2 = -0.72116591947498
 *	C3 =  0.47868480909345
 *	C4 = -0.34730547155299
 *	C5 =  0.24187369696082
 *	C6 = -0.13753123777116
 *	C7 =  0.052064690894143
 *	C8 = -0.0093104962134977
 *
 *	This function assumes that x is a non-zero positive value.
 */

static __inline float _log2f(float x)
{
  union {
    unsigned int ui;
    float f;
  } in;
  int exponent;
  float result;
  float x2, x4;
  float hi, lo;
  vector float vx;
  vector float vc = { 0.0, 0.0, 0.0, 0.0 };

  in.f = x;

  /* Extract the exponent from the input X.
   */
  exponent = (signed)((in.ui >> 23) & 0xFF) - 127;

  /* Compute the remainder after removing the exponent.
   */
  in.ui -= exponent << 23;

  /* Calculate the log2 of the remainder using the polynomial
   * approximation.
   */
  x = in.f - 1.0f;

  /* Instruction counts can be reduced if the polynomial was
   * computed entirely from nested (dependent) fma's. However,
   * to reduce the number of pipeline stalls, the polygon is evaluated
   * in two halves (hi amd lo).
   */
  x2 = x * x;
  x4 = x2 * x2;
  hi = -0.0093104962134977f*x + 0.052064690894143f;
  hi =                   hi*x - 0.13753123777116f;
  hi =                   hi*x + 0.24187369696082f;
  hi =                   hi*x - 0.34730547155299f;
  lo =  0.47868480909345f  *x - 0.72116591947498f;
  lo =                   lo*x + 1.4426898816672f;
  lo =                   lo*x;
  result = hi*x4 + lo;

  /* Add the exponent back into the result.
   */
  result += (float)(exponent);

#ifndef _IEEE_LIBM
  vx = spu_promote(x, 0);
  dom_chkf_less_than(vx, vc);
#endif
  return (result);
}

#endif /* _LOG2F_H_ */
