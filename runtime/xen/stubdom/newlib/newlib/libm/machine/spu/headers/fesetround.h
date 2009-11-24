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
#ifndef _FESETROUND_H_
#define _FESETROUND_H_  1

#include <spu_intrinsics.h>
#include <fenv.h>

#define FE_MASK_ROUND    (__FE_ROUND_ELE_0 | __FE_ROUND_ELE_1)

#define SMALL  (FE_MASK_ROUND - 1)
#define LARGE  (FE_MASK_ROUND + \
     ((__FE_SPU_DOWNWARD << 2) | __FE_SPU_DOWNWARD) + 1)

static __inline int _fesetround(int mode)
{
  unsigned int umode;
  vec_uint4 vec_mode;
  vec_uint4 valid, fail;
  vec_uint4 cur_fpscr, new_fpscr, mask_fpscr;
  vec_uint4 const valid_ele0 =
    { FE_TONEAREST, FE_TOWARDZERO, FE_UPWARD, FE_DOWNWARD };
  vec_uint4 const valid_ele1 =
    { FE_TONEAREST_1, FE_TOWARDZERO_1, FE_UPWARD_1, FE_DOWNWARD_1 };
  vec_uint4 const too_large = { LARGE, LARGE, LARGE, LARGE };
  vec_uchar16 const splat_ele0 =
    { 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3 };
  vec_uint4 const clear_non_ele0 = { 0xffffffff, 0, 0, 0 };

  /*
   * There are 24 valid values, check for a range plus the other 8
   * rather than check for specific bit settings.
   *
   * These are all the valid values:
   *   0xf00 through 0xf0f (SMALL + 1 through LARGE - 1, 16 values)
   *   0xc00 0xc04 0xc08 0xc0c (in ele0)
   *   0x300 0x301 0x302 0x303 (in ele1)
   */
  umode = mode;
  vec_mode = spu_splats(umode);
  valid = spu_cmpeq(vec_mode, valid_ele0);
  valid = spu_or(valid, spu_cmpeq(vec_mode, valid_ele1));
  valid = spu_or(valid, spu_cmpgt(vec_mode, SMALL));
  valid = spu_and(valid, spu_cmpgt(too_large, vec_mode));

  fail = spu_gather(valid);
  fail = spu_cmpeq(fail, 0);
  /*
   * set all elements of fail to the value of fail's element 0, so
   * we can select the current fpscr values on failure.
   */
  fail = spu_shuffle(fail, fail, splat_ele0);

  cur_fpscr = spu_mffpscr();
  /*
   * We don't have to mask the round element selection out since it
   * is shifted out.
   */
  new_fpscr = spu_promote(umode << 8, 0);
  new_fpscr = spu_and(new_fpscr, clear_non_ele0);
  /*
   * Use the element bits of the mode to set the mask.
   */
  mask_fpscr = spu_promote((umode & FE_MASK_ROUND), 0);
  new_fpscr = spu_sel(cur_fpscr, new_fpscr, mask_fpscr);
  /*
   * Use the current fpscr value if the round mode was invalid
   */
  new_fpscr = spu_sel(new_fpscr, cur_fpscr, fail);
  spu_mtfpscr(new_fpscr);

  return spu_extract(fail, 0);
}
#endif /* _FESETROUND_H_ */
