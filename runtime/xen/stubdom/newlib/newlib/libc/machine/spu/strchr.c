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

/* Scans the string pointed to by s for the character c and
 * returns a pointer to the first occurance of c. If
 * c is not found, then NULL is returned.
 */
char *strchr(const char *s, int c)
{
  unsigned int cmp, skip;
  vec_uchar16 *ptr, data, vc;
  vec_uint4 cmp_c, cmp_0;
  vec_uint4 result;
  vec_uint4 mask;
  vec_uint4 one = spu_splats(0xffffU);
  /* Scan memory array a quadword at a time. Skip leading
   * mis-aligned bytes.
   */
  ptr = (vec_uchar16 *)s;

  skip = (unsigned int)(ptr) & 15;
  mask = spu_rlmask(one, -skip);

  vc = spu_splats((unsigned char)(c));

  data = *ptr++;

  cmp_c = spu_and(spu_gather(spu_cmpeq(data, vc)), mask);
  cmp_0 = spu_and(spu_gather(spu_cmpeq(data, 0)), mask);

  cmp = spu_extract(spu_or(cmp_c, cmp_0), 0);

  while (cmp == 0) {
    data = *ptr++;
    cmp_c = spu_gather(spu_cmpeq(data, vc));
    cmp_0 = spu_gather(spu_cmpeq(data, 0));

    cmp = spu_extract(spu_or(cmp_c, cmp_0), 0);
  }

  /* Compute the location of the first character. If it is beyond
   * the end of the string, then return NULL.
   */
  result = spu_add(spu_promote((unsigned int)ptr - (skip+32), 0),
		   spu_cntlz(spu_promote(cmp, 0)));

  result = spu_andc(result, spu_cmpgt(cmp_0, cmp_c));

  return ((char *)spu_extract(result, 0));
}
