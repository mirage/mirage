/* --------------------------------------------------------------  */
/* (C)Copyright 2006,2007,                                         */
/* International Business Machines Corporation                     */
/* All Rights Reserved.                                            */
/*                                                                 */
/* Redistribution and use in source and binary forms, with or      */
/* without modification, are permitted provided that the           */
/* following conditions are met:                                   */
/*                                                                 */
/* - Redistributions of source code must retain the above copyright*/
/*   notice, this list of conditions and the following disclaimer. */
/*                                                                 */
/* - Redistributions in binary form must reproduce the above       */
/*   copyright notice, this list of conditions and the following   */
/*   disclaimer in the documentation and/or other materials        */
/*   provided with the distribution.                               */
/*                                                                 */
/* - Neither the name of IBM Corporation nor the names of its      */
/*   contributors may be used to endorse or promote products       */
/*   derived from this software without specific prior written     */
/*   permission.                                                   */
/* Redistributions of source code must retain the above copyright  */
/* notice, this list of conditions and the following disclaimer.   */
/*                                                                 */
/* Redistributions in binary form must reproduce the above         */
/* copyright notice, this list of conditions and the following     */
/* disclaimer in the documentation and/or other materials          */
/* provided with the distribution.                                 */
/*                                                                 */
/* Neither the name of IBM Corporation nor the names of its        */
/* contributors may be used to endorse or promote products         */
/* derived from this software without specific prior written       */
/* permission.                                                     */
/*                                                                 */
/* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND          */
/* CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,     */
/* INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF        */
/* MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE        */
/* DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR            */
/* CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,    */
/* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT    */
/* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;    */
/* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)        */
/* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN       */
/* CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR    */
/* OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,  */
/* EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.              */
/* --------------------------------------------------------------  */
/* PROLOG END TAG zYx                                              */
#ifdef __SPU__
#ifndef _ISNAND2_H_
#define _ISNAND2_H_	1

#include <spu_intrinsics.h>

/*
 * FUNCTION
 *	vector unsigned long long _isnand2(vector double x)
 *
 * DESCRIPTION
 *      The _isnand2 function returns a vector in which each element indicates
 *      if the corresponding element of x is not a number.  (NaN)  
 *
 * RETURNS
 *      The function _isnand2 returns an unsigned long long vector in which 
 *      each element is defined as:
 *
 *        - ULLONG_MAX  if the element of x is NaN
 *        - 0           otherwise
 *
 */
static __inline vector unsigned long long _isnand2(vector double x)
{

#ifndef __SPU_EDP__

  vec_uint4 sign_mask = (vec_uint4) { 0x7FFFFFFF, 0xFFFFFFFF, 0x7FFFFFFF, 0xFFFFFFFF };
  vec_uint4 test_mask = (vec_uint4) { 0x7FF00000, 0x00000000, 0x7FF00000, 0x00000000 };
  vec_uchar16 hi_promote = (vec_uchar16) { 0, 1, 2, 3, 0, 1, 2, 3, 8, 9, 10, 11, 8, 9, 10, 11 };
	
  //  Remove the sign bits
  vec_uint4 signless = spu_and((vec_uint4)x,sign_mask);

  //  Check if the high word is equal to the max_exp
  vec_uint4 x2 = spu_cmpeq(signless,test_mask);
	
  //  This checks two things:
  //  1)  If the high word is greater than max_exp (indicates a NaN)
  //  2)  If the low word is non-zero (indicates a NaN in conjunction with an
  //      exp equal to max_exp)
  vec_uint4 x1 = spu_cmpgt(signless,test_mask);
	
  //  rotate the low word test of x1 into the high word slot, then and it
  //  with the high word of x2 (checking for #2 above)
  vec_uint4 exp_and_lw = spu_and(spu_rlqwbyte(x1,4),x2);
	
  //  All the goodies are in the high words, so if the high word of either x1
  //  or exp_and_lw is set, then we have a NaN, so we "or" them together
  vec_uint4 result = spu_or(x1,exp_and_lw);
	
  //  And then promote the resulting high word to 64 bit length
  result = spu_shuffle(result,result,hi_promote);
	
  return (vec_ullong2) result;	

#else

  return spu_testsv(x, SPU_SV_NAN);

#endif /* __SPU_EDP__ */
}

#endif // _ISNAND2_H_
#endif /* __SPU__ */
