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

/* Calculates  the  length  of  the string s, not including the terminating
 * \0 character.
 */
size_t strlen(const char *s)
{
  size_t len;
  unsigned int cnt, cmp, skip, mask;
  vec_uchar16 *ptr, data;

  /* Compensate for initial mis-aligned string.
   */
  ptr = (vec_uchar16 *)s;
  skip = (unsigned int)(ptr) & 15;
  mask = 0xFFFF >> skip;

  data = *ptr++;
  cmp = spu_extract(spu_gather(spu_cmpeq(data, 0)), 0);
  cmp &= mask;

  cnt = spu_extract(spu_cntlz(spu_promote(cmp, 0)), 0);
  len = cnt - (skip + 16);

  while (cnt == 32) {
    data = *ptr++;
    len -= 16;
    cnt = spu_extract(spu_cntlz(spu_gather(spu_cmpeq(data, 0))), 0);
    len += cnt;
  }

  return (len);
}
