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
#include "vec_literal.h"

/* Compare the two strings s1 and s2. Return an integer less than, equal
 * to, or greater than zero if  s1 is found, respectively, to be less than,
 * to match, or be greater than s2.
 */

int strcmp(const char *s1, const char *s2)
{
  unsigned int offset1, offset2;
  vec_uint4 gt_v, lt_v, mask_v;
  vec_uint4 cnt1_v, cnt2_v;
  vec_uint4 end1_v, end2_v, end_v, neq_v;
  vec_uchar16 shuffle1, shuffle2;
  vec_uchar16 data1A, data1B, data1, data2A, data2B, data2;
  vec_uchar16 *ptr1, *ptr2;

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

  do {
    data1B = *ptr1++;
    data2B = *ptr2++;

    data1 = spu_shuffle(data1A, data1B, shuffle1);
    data2 = spu_shuffle(data2A, data2B, shuffle2);

    data1A = data1B;
    data2A = data2B;

    neq_v = spu_gather(spu_xor(spu_cmpeq(data1, data2), -1));

    end1_v = spu_gather(spu_cmpeq(data1, 0));
    end2_v = spu_gather(spu_cmpeq(data2, 0));
    end_v  = spu_or(end1_v, end2_v), 0;
  } while (spu_extract(spu_or(end_v, neq_v), 0) == 0);

  cnt1_v = spu_cntlz(end1_v);
  cnt2_v = spu_cntlz(end2_v);

  gt_v = spu_gather(spu_cmpgt(data1, data2));
  lt_v = spu_gather(spu_cmpgt(data2, data1));

  mask_v = spu_and(spu_cmpeq(cnt1_v, cnt2_v),
		   spu_cmpeq(spu_rlmask(neq_v, (vec_int4)spu_add((vec_uint4)cnt1_v, -32)), 0));

  gt_v = spu_sub(-1, spu_sl(spu_cmpgt(gt_v, lt_v), 1));

  return (spu_extract(spu_andc(gt_v, mask_v), 0));
}
