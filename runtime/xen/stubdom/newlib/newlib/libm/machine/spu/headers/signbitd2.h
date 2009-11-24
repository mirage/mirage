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
#ifndef _SIGNBITD2_H_
#define _SIGNBITD2_H_	1

#include <spu_intrinsics.h>

/*
 * FUNCTION
 *	vector unsigned long long _signbitd2(vector double x)
 *
 * DESCRIPTION
 *      The signbitd2 function returns a vector which contains either all ones 
 *      or all zeros, depending on the sign of the corresponding input vector 
 *      element.
 *
 *      Note that the signbit functions are not logically equivalent to 
 *      x < 0.0.  IEEE 754 floating point rules include a signed zero, so if
 *      the input value is –0.0, signbit will return non-zero, but the naive
 *      implementation will not.
 * 
 * RETURNS
 *      The function signbitf4 returns an unsigned int vector in which each
 *      element is defined as:
 *
 *        - ULLONG_MAX (0xFFFFFFFFFFFFFFFF)   if the sign bit is set for the 
 *                                            corresponding element of x
 *        - 0          (0x0000000000000000)   otherwise.
 *
 */
static __inline vector unsigned long long _signbitd2(vector double x)
{
  vec_uchar16 shuf = ((vec_uchar16){0, 1, 2, 3,  0, 1, 2, 3,  8, 9, 10, 11,  8, 9, 10, 11});
  vec_uint4 r = spu_rlmaska((vec_uint4)x,-31);
  return (vec_ullong2)spu_shuffle(r,r,shuf);
}
#endif /* _SIGNBITD2_H_ */
#endif /* __SPU__ */
