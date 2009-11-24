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

/*
 * Functions to pack/unpack the 128 bit fpscr to/from the 32 bit fenv_t.
 * The fpscr currently has 32 of 128 bits defined.
 */

#ifndef _FEFPSCR_H_
#define _FEFPSCR_H_	1

#include <spu_intrinsics.h>
#include <fenv.h>

static __inline vec_uint4 __unpack_fpscr(fenv_t word)
{
  vec_uint4 fpscr;
  vec_uchar16 splat = { 0, 1, 0, 1, 0, 1, 0, 1, 2, 3, 2, 3, 2, 3, 2, 3 };
  vec_short8 rotm = { -12, -9, -3, 0, -10, -7, -3, 0 };
  vec_uint4 mask = { 0x00000f07, 0x00003f07, 0x00003f07, 0x00000f07 };

  fpscr = spu_promote (word, 0);
  fpscr = spu_shuffle (fpscr, fpscr, splat);
  /*
   * The casts here are important, so we generate different code.
   */
  fpscr = (vec_uint4) spu_rlmask ((vec_short8) fpscr, rotm);
  fpscr = (vec_uint4) spu_and ((vec_short8) fpscr, 0xff);
  fpscr = spu_or (spu_rlmask(fpscr, -8), fpscr);
  fpscr = spu_and (fpscr, mask);
  return fpscr;
}

static __inline fenv_t __pack_fpscr(vec_uint4 fpscr)
{
  vec_uchar16 pat = { 0x80, 2, 0x80, 10, 0x80, 3, 0x80, 11,
                      0x80, 6, 0x80, 14, 0x80, 7, 0x80, 15 };
  vec_ushort8 shl = { 12, 10, 9, 7, 3, 3, 0, 0 };
  vec_uint4 mask = { 0x00000f07, 0x00003f07, 0x00003f07, 0x00000f07 };
  vec_uint4 word;

  word = spu_and (fpscr, mask);
  word = spu_shuffle (word, word, pat);
  word = (vec_uint4) spu_sl ((vec_short8) word, shl);
  word = spu_orx (word);
  return spu_extract (word, 0);
}

#endif
