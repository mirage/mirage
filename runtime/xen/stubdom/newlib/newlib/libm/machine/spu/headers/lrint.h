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
#ifndef _LRINT_H_
#define _LRINT_H_	1

#include <spu_intrinsics.h>
#include "headers/vec_literal.h"

/* Round the input to the nearest integer according to the current
 * rounding mode.
 */
static __inline long int _lrint(double x)
{
  vec_int4 out, sign;
  vec_double2 in, addend;

  in = spu_promote(x, 0);

  /* Add 2^53 affect a round to be performed by the hardware.
   */
  addend = spu_sel((vec_double2)(VEC_SPLAT_U64(0x4330000000000000ULL)),
                   in, VEC_SPLAT_U64(0x8000000000000000ULL));
  out = (vec_int4)spu_rlqwbyte(spu_add(in, addend), 4);

  /* Correct the output sign.
   */
  sign = spu_rlmaska((vec_int4)in, -31);

  out = spu_sub(spu_xor(out, sign), sign);

  return ((long int)spu_extract(out, 0));
}
#endif /* _LRINT_H_ */
