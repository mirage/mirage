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

/* Fills the first n bytes of the memory area pointed to by s
 * with the constant byte c. Returns a pointer to the memory area s.
 */
void * memset(void *s, int c, size_t n)
{
  int skip, cnt, i;
  vec_uchar16 *vs;
  vec_uchar16 vc, mask, one = spu_splats((unsigned char)-1);

  vs = (vec_uchar16 *)(s);
  vc = spu_splats((unsigned char)c);
  cnt = (int)(n);

  /* Handle any leading partial quadwords as well a
   * very short settings (ie, such that the n characters
   * all reside in a single quadword.
   */
  skip = (int)(s) & 15;
  if (skip) {
    mask = spu_rlmaskqwbyte(one, -skip);
    cnt -= 16 - skip;
    if (cnt < 0) {
      mask = spu_and(mask, spu_slqwbyte(one, (unsigned int)(-cnt)));
    }
    *vs = spu_sel(*vs, vc, mask);
    vs++;
  }

  /* Handle 8 quadwords at a time
   */
  for (i=127; i<cnt; cnt-=8*16) {
    vs[0] = vc;
    vs[1] = vc;
    vs[2] = vc;
    vs[3] = vc;
    vs[4] = vc;
    vs[5] = vc;
    vs[6] = vc;
    vs[7] = vc;
    vs += 8;
  }

  /* Finish all remaining complete quadwords
   */
  for (i=15; i<cnt; cnt-=16) *vs++ = vc;

  /* Handle any trailing partial quadwords
   */
  if (cnt > 0) {
    mask = spu_slqwbyte(one, (unsigned int)(16-cnt));
    *vs = spu_sel(*vs, vc, mask);
  }

  return (s);
}
