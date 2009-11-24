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

/* Compare the two strings s1 and s2 of length n.  Returns an integer
 * less than, equal to, or greater than zero if  s1  is  found, respectively,
 * to be less than, to match, or be greater than s2.
 */

int strncmp(const char *s1, const char *s2, size_t n)
{
  unsigned int offset1, offset2;
  vec_int4 n_v;
  vec_uint4 cnt1_v, cnt2_v, max_cnt_v;
  vec_uint4 gt_v, lt_v, mask_v, end1_v, end2_v, end_v, neq_v;
  vec_uint4 shift_n_v, shift_eos_v, max_shift_v;
  vec_uchar16 shuffle1, shuffle2;
  vec_uchar16 data1A, data1B, data1, data2A, data2B, data2;
  vec_uchar16 *ptr1, *ptr2;

  data1 = data2 = spu_splats((unsigned char)0);

  ptr1 = (vec_uchar16 *)s1;
  ptr2 = (vec_uchar16 *)s2;

  offset1 = (unsigned int)(ptr1) & 15;
  offset2 = (unsigned int)(ptr2) & 15;

  shuffle1 = (vec_uchar16)spu_add((vec_uint4)spu_splats((unsigned char)offset1),
				  VEC_LITERAL(vec_uint4, 0x00010203, 0x04050607, 0x08090A0B, 0x0C0D0E0F));
  shuffle2 = (vec_uchar16)spu_add((vec_uint4)spu_splats((unsigned char)offset2),
				  VEC_LITERAL(vec_uint4, 0x00010203, 0x04050607, 0x08090A0B, 0x0C0D0E0F));
  data1A = *ptr1++;
  data2A = *ptr2++;

  n_v = spu_promote((int)n, 0);

  do {
    data1B = *ptr1++;
    data2B = *ptr2++;

    /* Quadword align each of the input strings so that
     * we operate on full quadwords.
     */
    data1 = spu_shuffle(data1A, data1B, shuffle1);
    data2 = spu_shuffle(data2A, data2B, shuffle2);

    data1A = data1B;
    data2A = data2B;

    neq_v = spu_gather(spu_xor(spu_cmpeq(data1, data2), -1));

    end1_v = spu_gather(spu_cmpeq(data1, 0));
    end2_v = spu_gather(spu_cmpeq(data2, 0));
    end_v  = spu_or(end1_v, end2_v), 0;

    n_v = spu_add(n_v, -16);

    /* Repeat until either
     * 1) the character count expired,
     * 2) a null character is discovered in one of the input strings, or
     * 3) the strings do not compare equal.
     */
  } while (spu_extract(spu_and(spu_cmpeq(spu_or(end_v, neq_v), 0), spu_cmpgt(n_v, 0)), 0));

  /* Construct a mask to eliminate characters that are not of interest
   * in the comparison. Theses include characters that are beyond the
   * n character count and beyond the first null character.
   */
  cnt1_v = spu_cntlz(end1_v);
  cnt2_v = spu_cntlz(end2_v);

  max_cnt_v = spu_sel(cnt1_v, cnt2_v, spu_cmpgt(cnt2_v, cnt1_v));

  mask_v = spu_splats((unsigned int)0xFFFF);

  shift_n_v = spu_andc((__vector unsigned int)spu_sub(0, n_v), spu_cmpgt(n_v, -1));
  shift_eos_v = spu_sub(32, max_cnt_v);

  max_shift_v = spu_sel(shift_n_v, shift_eos_v, spu_cmpgt(shift_eos_v, shift_n_v));

  mask_v = spu_and(spu_sl(mask_v, spu_extract(max_shift_v, 0)), mask_v);

  /* Determine if greater then or less then in the case that they are
   * not equal. gt_v is either 1 (in the case s1 is greater then s2), or
   * -1 (in the case that s2 is greater then s1).
   */
  gt_v = spu_gather(spu_cmpgt(data1, data2));
  lt_v = spu_gather(spu_cmpgt(data2, data1));

  gt_v = spu_sub(-1, spu_sl(spu_cmpgt(gt_v, lt_v), 1));

  /* Construct a mask to be applied to gt_v if the strings are discovered
   * to be equal.
   */
  mask_v = spu_cmpeq(spu_and(neq_v, mask_v), 0);

  return (spu_extract(spu_andc(gt_v, mask_v), 0));
}
