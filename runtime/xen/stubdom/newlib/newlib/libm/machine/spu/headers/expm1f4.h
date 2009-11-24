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

#ifndef _EXPM1F4_H_
#define _EXPM1F4_H_	1

#include <spu_intrinsics.h>

#include "expf4.h"
#include "divf4.h"


#define EXPM1F4_P0 0.0000000000000000000000000e-00
#define EXPM1F4_P1 9.9999999999999988897769754e-01
#define EXPM1F4_P2 -6.5597409827762467697531701e-04
#define EXPM1F4_P3 2.3800889637330315679042414e-02
#define EXPM1F4_P4 -1.0914929910143700584950963e-05

#define EXPM1F4_Q0 1.0000000000000000000000000e-00
#define EXPM1F4_Q1 -5.0065597410018825019761834e-01
#define EXPM1F4_Q2 1.0746220997195164714721471e-01
#define EXPM1F4_Q3 -1.1966024153043854083566799e-02
#define EXPM1F4_Q4 5.9997727954467768105711878e-04


/*
 * FUNCTION
 *	vector float _expm1f4(vector float x)
 *
 *	_expm1d2 computes the exponential - 1 for each element
 *	of the input vector x.
 *
 *	This function is intended to return accurate values, even
 *	where exp(x) - 1 would normally produce bad results due to
 *	floating-point cancellation errors.
 *
 */

static __inline vector float _expm1f4(vector float x) 
{
  vector float onef  = spu_splats(1.0f);
  vector float rangelo = spu_splats(-0.4f);
  vector float rangehi = spu_splats(0.35f);
  vector unsigned int use_exp;
  vector float pr, qr;
  vector float eresult;
  vector float rresult;
  vector float result;

  use_exp = spu_or(spu_cmpgt(x, rangehi), spu_cmpgt(rangelo, x));

  /*
   * Calculate directly using exp(x) - 1
   */
  eresult = spu_sub(_expf4(x), onef);

  /*
   * For x in [-0.5,0.5], use a rational approximation.
   * The madd's are interleaved to reduce dependency stalls. Looks
   * like gcc is smart enough to do this on it's own... but why
   * take the chance.
   */
  pr = spu_madd(x, spu_splats((float)EXPM1F4_P4), spu_splats((float)EXPM1F4_P3));
  qr = spu_madd(x, spu_splats((float)EXPM1F4_Q4), spu_splats((float)EXPM1F4_Q3));
  pr = spu_madd(pr, x, spu_splats((float)EXPM1F4_P2));
  qr = spu_madd(qr, x, spu_splats((float)EXPM1F4_Q2));
  pr = spu_madd(pr, x, spu_splats((float)EXPM1F4_P1));
  qr = spu_madd(qr, x, spu_splats((float)EXPM1F4_Q1));
  pr = spu_madd(pr, x, spu_splats((float)EXPM1F4_P0));
  qr = spu_madd(qr, x, spu_splats((float)EXPM1F4_Q0));
  rresult = _divf4(pr, qr);

  /*
   * Select either direct calculation or rational approximation.
   */
  result = spu_sel(rresult, eresult, use_exp);

  return result;
}

#endif /* _EXPM1F4_H_ */
#endif /* __SPU__ */
