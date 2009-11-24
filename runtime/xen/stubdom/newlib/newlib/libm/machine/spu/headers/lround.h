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
#ifndef _LROUND_H_
#define _LROUND_H_	1

#include <spu_intrinsics.h>
#include "headers/vec_literal.h"

/* Round the input to the nearest integer value, rounding halfway cases
 * away from zero. No special handling is performed when values are
 * outside the 32-bit range.
 */

static __inline long int _lround(double x)
{
  int shift;
  vec_int4 exp;
  vec_uint4 mant, sign, mask, addend;
  vec_double2 in;

  in = spu_promote(x, 0);

  /* Determine how many bits to shift the mantissa to correctly
   * align it into long long element 0.
   */
  exp = spu_and(spu_rlmask((vec_int4)in, -20), 0x7FF);
  exp = spu_add(exp, -979);
  shift = spu_extract(exp, 0);

  mask = spu_cmpgt(exp, 0);

  /* Algn mantissa bits
   */
  mant = spu_sel(spu_rlmaskqwbyte((vec_uint4)in, -8), VEC_SPLAT_U32(0x00100000),
                 VEC_LITERAL(vec_uint4, 0,0,0xFFF00000,0));

  mant = spu_slqwbytebc(spu_slqw(mant, shift), shift);

  /* Perform round by adding 1 if the fraction bits are
   * greater than or equal to .5
   */
  addend = spu_and(spu_rlqw(mant, 1), 1);
  mant = spu_and(spu_add(mant, addend), mask);

  /* Compute the two's complement of the mantissa if the
   * input is negative.
   */
  sign = (vec_uint4)spu_rlmaska((vec_int4)in, -31);

  mant = spu_sub(spu_xor(mant, sign), sign);

  return ((long int)spu_extract(mant, 0));
}
#endif /* _LROUND_H_ */
