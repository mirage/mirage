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

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.
*/
#include <spu_intrinsics.h>
#include <stddef.h>
#include "vec_literal.h"

/* Scans the string pointed to by s for the character c and
 * returns a pointer to the last occurance of c. If
 * c is not found, then NULL is returned.
 */
char * strrchr(const char *s, int c)
{
  int nskip;
  vec_uchar16 *ptr, data, vc;
  vec_uint4 cmp_c, cmp_0, cmp;
  vec_uint4 res_ptr, res_cmp;
  vec_uint4 mask, result;
  vec_uint4 one = spu_splats(0xffffU);
  /* Scan memory array a quadword at a time. Skip leading
   * mis-aligned bytes.
   */
  ptr = (vec_uchar16 *)s;

  nskip = -((unsigned int)(ptr) & 15);
  mask = spu_rlmask(one, nskip);

  vc = spu_splats((unsigned char)(c));

  data = *ptr++;
  ptr = (vec_uchar16 *)((unsigned int)ptr & ~15);

  cmp_c = spu_and(spu_gather(spu_cmpeq(data, vc)), mask);
  cmp_0 = spu_and(spu_gather(spu_cmpeq(data, 0)), mask);

  res_ptr = spu_splats(0U);
  res_cmp = spu_splats(0U);

  while (spu_extract(cmp_0, 0) == 0) {
    cmp = spu_cmpeq(cmp_c, 0);

    res_ptr = spu_sel(spu_promote((unsigned int)(ptr), 0), res_ptr, cmp);
    res_cmp = spu_sel(cmp_c, res_cmp, cmp);

    data = *ptr++;

    cmp_c = spu_gather(spu_cmpeq(data, vc));
    cmp_0 = spu_gather(spu_cmpeq(data, 0));

    cmp = spu_cmpeq(cmp_c, 0);
  }

  /* Compute the location of the last character before termination
   * character.
   *
   * First mask off compare results following the first termination character.
   */
  mask = spu_sl(one, 31 - spu_extract(spu_cntlz(cmp_0), 0));
  cmp_c = spu_and(cmp_c, mask);

  /* Conditionally update res_ptr and res_cmd if a match was found in the last
   * quadword.
   */
  cmp = spu_cmpeq(cmp_c, 0);

  res_ptr = spu_sel(spu_promote((unsigned int)(ptr), 0), res_ptr, cmp);
  res_cmp = spu_sel(cmp_c, res_cmp, cmp);

  /* Bit reserve res_cmp for locating last occurance.
   */
  mask = spu_cmpeq(res_cmp, 0);

  res_cmp = (vec_uint4)spu_maskb(spu_extract(res_cmp, 0));
  res_cmp = spu_gather((vec_uchar16)spu_shuffle(res_cmp, res_cmp,
						VEC_LITERAL(vec_uchar16,
							    15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0)));

  /* Compute the location (ptr) of the last occurance of c. If no
   * occurance was found (ie, element 0 of res_cmp == 0, then return
   * NULL.
   */
  result = spu_sub(spu_add(res_ptr, 15), spu_cntlz(res_cmp));
  result = spu_andc(result, mask);

  return ((char *)spu_extract(result, 0));
}
