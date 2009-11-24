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
#include <string.h>

/* Copy the string up to n character from memory area src to
 * memory area dest. The memory areas may not overlap. The
 * strncpy subroutine returns a pointer to dest.
 */
char * strncpy(char * __restrict__ dest, const char * __restrict__ src, size_t n)
{
  unsigned int len;
  unsigned int cmp, skip, mask;
  vec_uchar16 *ptr, data;
  vec_uint4 cnt, gt, N;

  N = spu_promote((unsigned int)n, 0);

  /* Determine the string length, including termination character,
   * clamped to n characters.
   */
  ptr = (vec_uchar16 *)src;
  skip = (unsigned int)(ptr) & 15;
  mask = 0xFFFF >> skip;

  data = *ptr++;
  cmp = spu_extract(spu_gather(spu_cmpeq(data, 0)), 0);
  cmp &= mask;

  cnt = spu_cntlz(spu_promote(cmp, 0));
  len = spu_extract(cnt, 0) - (skip + 15);

  gt = spu_cmpgt(spu_promote(len, 0), N);

  while (spu_extract(spu_andc(spu_cmpeq(cnt, 32), gt), 0)) {
    data = *ptr++;
    len -= 16;
    cnt  = spu_cntlz(spu_gather(spu_cmpeq(data, 0)));
    len += spu_extract(cnt, 0);

    gt = spu_cmpgt(spu_promote(len, 0), N);
  }

  /* len = MIN(len, n)
   */
  len = spu_extract(spu_sel(spu_promote((unsigned int)len, 0), N, gt), 0);

  /* Padding
   */
  if (len != n) {
    memset(dest + len, 0, n - len);
  }
  /* Perform a memcpy of the resulting length
   */
  return ((char *)memcpy((void *)dest, (const void *)src, len));
}
