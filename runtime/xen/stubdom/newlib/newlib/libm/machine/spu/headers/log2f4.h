/* --------------------------------------------------------------  */
/* (C)Copyright 2006,2007,                                         */
/* International Business Machines Corporation,                    */
/* Sony Computer Entertainment, Incorporated,                      */
/* Toshiba Corporation,                                            */
/*                                                                 */
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

#ifndef _LOG2F4_H_
#define _LOG2F4_H_	1

#include <spu_intrinsics.h>

/*
 * FUNCTION
 *	vector float _log2f4(vector float x)
 *
 * DESCRIPTION
 *	The _log2f4 function computes log (base 2) on a vector if inputs 
 *      values x. The _log2f4 function is approximated as a polynomial of
 *      order 8 (C. Hastings, Jr, 1955).
 *
 *                   __8__
 *		     \
 *		      \ 
 *	log2f(1+x) =  /     Ci*x^i
 *                   /____
 *                    i=1
 *
 *	for x in the range 0.0 to 1.0
 *
 *	C1 =  1.4426898816672
 *	C2 = -0.72116591947498
 *	C3 =  0.47868480909345
 *	C4 = -0.34730547155299
 *	C5 =  0.24187369696082
 *	C6 = -0.13753123777116
 *	C7 =  0.052064690894143
 *	C8 = -0.0093104962134977
 *
 *	This function assumes that x is a non-zero positive value.
 *
 */
static __inline vector float _log2f4(vector float x)
{
  vector signed int exponent;
  vector float result;
  vector float x2, x4;
  vector float hi, lo;

  /* Extract the exponent from the input X. 
   */
  exponent = (vector signed int)spu_and(spu_rlmask((vector unsigned int)(x), -23), 0xFF);
  exponent = spu_add(exponent, -127);

  /* Compute the remainder after removing the exponent.
   */
  x = (vector float)spu_sub((vector signed int)(x), spu_sl(exponent, 23));

  /* Calculate the log2 of the remainder using the polynomial
   * approximation.
   */
  x = spu_sub(x, spu_splats(1.0f));

  /* Instruction counts can be reduced if the polynomial was
   * computed entirely from nested (dependent) fma's. However, 
   * to reduce the number of pipeline stalls, the polygon is evaluated 
   * in two halves (hi amd lo). 
   */
  x2 = spu_mul(x, x);
  x4 = spu_mul(x2, x2);

  hi = spu_madd(x, spu_splats(-0.0093104962134977f), spu_splats(0.052064690894143f));
  hi = spu_madd(x, hi, spu_splats(-0.13753123777116f));
  hi = spu_madd(x, hi, spu_splats( 0.24187369696082f));
  hi = spu_madd(x, hi, spu_splats(-0.34730547155299f));
  lo = spu_madd(x, spu_splats(0.47868480909345f), spu_splats(-0.72116591947498f));
  lo = spu_madd(x, lo, spu_splats(1.4426898816672f));
  lo = spu_mul(x, lo);
  result = spu_madd(x4, hi, lo);

  /* Add the exponent back into the result.
   */
  result = spu_add(result, spu_convtf(exponent, 0));
  
  return (result);
}

#endif /* _LOG2F4_H_ */
#endif /* __SPU__ */
