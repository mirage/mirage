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

/* Copy n bytes from memory area src to memory area dest.
 * Copying is performed as if the n characters pointed to
 * by src are first copied into a temporary array that does
 * not overlap the src and dest arrays. Then the n characters
 * of the temporary array are copied into the destination
 * array. The memmove subroutine returns a pointer to dest.
 */

void * memmove(void * __restrict__ dest, const void * __restrict__ src, size_t n)
{
  int adjust, delta;
  unsigned int soffset1, soffset2, doffset1, doffset2;
  vec_uchar16 *vSrc, *vDst;
  vec_uchar16 sdata1, sdata2, sdata, ddata, shuffle;
  vec_uchar16 mask, mask1, mask2, mask3, one = spu_splats((unsigned char)-1);

  soffset1  = (unsigned int)(src) & 15;
  doffset1 = (unsigned int)(dest) & 15;
  doffset2 = ((unsigned int)(dest) + n) & 15;

  /* Construct a series of masks used to data insert. The masks
   * contains 0 bit when the destination word is unchanged, 1 when it
   * must be replaced by source bits.
   *
   * mask1 = mask for leading unchanged bytes
   * mask2 = mask for trailing unchange bytes
   * mask3 = mask indicating the more than one qword is being changed.
   */
  mask  = one;
  mask1 = spu_rlmaskqwbyte(mask, -doffset1);
  mask2 = spu_slqwbyte(mask, 16-doffset2);
  mask3 = (vec_uchar16)spu_cmpgt(spu_splats((unsigned int)(doffset1 + n)), 15);

  vDst = (vec_uchar16 *)(dest);

  delta  = (int)soffset1 - (int)doffset1;

  /* The follow check only works if the SPU addresses are not
   * wrapped. No provisions have been made to correct for this
   * limitation.
   */
  if (((unsigned int)dest - (unsigned int)src) >= (unsigned int)n) {
    /* Forward copy. Perform a memcpy.
     *
     * Handle any leading destination partial quadwords as
     * well a very short copy (ie, such that the n characters
     * all reside in a single (destination) quadword.
     */
    vSrc = (vec_uchar16 *)(src);
    vDst = (vec_uchar16 *)(dest);

    /* Handle any leading destination partial quadwords as
     * well a very short copy (ie, such that the n characters
     * all reside in a single (destination) quadword.
     */
    soffset1 = (unsigned int)(src) & 15;
    doffset1 = (unsigned int)(dest) & 15;
    doffset2 = ((unsigned int)(dest) + n) & 15;

    /* Compute a shuffle pattern used to align the source string
     * with the alignment of the destination string.
     */

    adjust = (int)spu_extract(spu_cmpgt(spu_promote(doffset1, 0), spu_promote(soffset1, 0)), 0);
    delta  = (int)soffset1 - (int)doffset1;
    delta += adjust & 16;

    shuffle = (vec_uchar16)spu_add((vec_uint4)spu_splats((unsigned char)delta),
				   VEC_LITERAL(vec_uint4, 0x00010203, 0x04050607, 0x08090A0B, 0x0C0D0E0F));

    vSrc += adjust;

    sdata1 = *vSrc++;
    sdata2 = *vSrc++;

    ddata = *vDst;
    sdata = spu_shuffle(sdata1, sdata2, shuffle);

    /* Construct a series of masks used to data insert. The masks
     * contain 0 when the destination word is unchanged, 1 when it
     * must be replaced by source bytes.
     *
     * mask1 = mask for leading unchanged bytes
     * mask2 = mask for trailing unchange bytes
     * mask3 = mask indicating the more than one qword is being changed.
     */
    mask  = one;
    mask1 = spu_rlmaskqwbyte(mask, -doffset1);
    mask2 = spu_slqwbyte(mask, 16-doffset2);
    mask3 = (vec_uchar16)spu_cmpgt(spu_splats((unsigned int)(doffset1 + n)), 15);

    *vDst++ = spu_sel(ddata, sdata, spu_and(mask1, spu_or(mask2, mask3)));

    n += doffset1;

    /* Handle complete destination quadwords
     */
    while (n > 31) {
      sdata1 = sdata2;
      sdata2 = *vSrc++;
      *vDst++ = spu_shuffle(sdata1, sdata2, shuffle);
      n -= 16;
    }

    /* Handle any trailing partial (destination) quadwords
     */
    mask = spu_and((vec_uchar16)spu_cmpgt(spu_splats((unsigned int)n), 16), mask2);
    *vDst = spu_sel(*vDst, spu_shuffle(sdata2, *vSrc, shuffle), mask);

  } else {
    /* Backward copy.
     *
     * Handle any leading destination partial quadwords as
     * well a very short copy (ie, such that the n characters
     * all reside in a single (destination) quadword.
     */
    vSrc = (vec_uchar16 *)((unsigned int)src  + n-1);
    vDst = (vec_uchar16 *)((unsigned int)dest + n-1);

    /* Handle any leading destination partial quadwords as
     * well a very short copy (ie, such that the n characters
     * all reside in a single (destination) quadword.
     */
    soffset1 = (unsigned int)(src)  & 15;
    soffset2 = (unsigned int)(vSrc) & 15;
    doffset1 = (unsigned int)(dest) & 15;
    doffset2 = (unsigned int)(vDst) & 15;

    /* Compute a shuffle pattern used to align the source string
     * with the alignment of the destination string.
     */
    adjust = (int)spu_extract(spu_cmpgt(spu_promote(soffset2, 0), spu_promote(doffset2, 0)), 0);
    delta  = (int)doffset2 - (int)soffset2;
    delta += adjust & 16;

    shuffle = (vec_uchar16)spu_sub(VEC_LITERAL(vec_uint4, 0x10111213, 0x14151617, 0x18191A1B, 0x1C1D1E1F),
				   (vec_uint4)spu_splats((unsigned char)delta));

    vSrc -= adjust;

    sdata2 = *vSrc--;
    sdata1 = *vSrc--;

    ddata = *vDst;
    sdata = spu_shuffle(sdata1, sdata2, shuffle);

    /* Construct a series of masks used to data insert. The masks
     * contain 0 when the destination word is unchanged, 1 when it
     * must be replaced by source bytes.
     *
     * mask1 = mask for leading unchanged bytes
     * mask2 = mask for trailing unchange bytes
     * mask3 = mask indicating the more than one qword is being changed.
     */
    mask  = one;
    mask1 = spu_rlmaskqwbyte(mask, -doffset1);
    mask2 = spu_slqwbyte(mask, 15-doffset2);
    mask3 = (vec_uchar16)spu_cmpgt(spu_splats((int)(doffset2 - n)), -2);

    *vDst-- = spu_sel(ddata, sdata, spu_and(mask2, spu_orc(mask1, mask3)));

    n -= doffset2 + 1;

    /* Handle complete destination quadwords
     */
    while ((int)n > 15) {
      sdata2 = sdata1;
      sdata1 = *vSrc--;
      *vDst-- = spu_shuffle(sdata1, sdata2, shuffle);
      n -= 16;
    }

    /* Handle any trailing partial (destination) quadwords
     */
    mask = spu_and((vec_uchar16)spu_cmpgt(spu_splats((int)n), 0), mask1);
    *vDst = spu_sel(*vDst, spu_shuffle(*vSrc, sdata1, shuffle), mask);
  }
  return (dest);
}

