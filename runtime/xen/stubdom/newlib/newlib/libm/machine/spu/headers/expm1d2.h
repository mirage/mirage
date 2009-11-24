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

#ifndef _EXPM1D2_H_
#define _EXPM1D2_H_	1

#include <spu_intrinsics.h>

#include "expd2.h"
#include "divd2.h"

#define EXPM1_P0 0.0000000000000000000000000e+00
#define EXPM1_P1 1.0000000000000000000000000e+00
#define EXPM1_P2 9.7234232565378004697204117e-04
#define EXPM1_P3 3.3328278237299953368211192e-02
#define EXPM1_P4 3.1156225044634678993365345e-05
#define EXPM1_P5 2.1352206553343212164751408e-04
#define EXPM1_P6 1.6975135794626144795757452e-07
#define EXPM1_P7 2.7686287801334994383131629e-07
#define EXPM1_P8 1.1186114936216450015354379e-10

#define EXPM1_Q0 1.0000000000000000000000000e+00
#define EXPM1_Q1 -4.9902765767434620336473472e-01
#define EXPM1_Q2 1.1617544040780639069687652e-01
#define EXPM1_Q3 -1.6551954366467523660499950e-02
#define EXPM1_Q4 1.5864115838972218334307351e-03
#define EXPM1_Q5 -1.0534540477401370666288988e-04
#define EXPM1_Q6 4.7650003993592160620959043e-06
#define EXPM1_Q7 -1.3529198871087017840776265e-07
#define EXPM1_Q8 1.8635779407675460757658020e-09

/*
 * FUNCTION
 *	vector double _expm1d2(vector double x)
 *
 * DESCRIPTION
 *	_expm1d2 computes the exponential - 1 for each element
 *	of the input vector x.
 *
 *	This function is intended to return accurate values, even
 *	where exp(x) - 1 would normally produce bad results due to
 *	floating-point cancellation errors.
 *
 */

static __inline vector double _expm1d2(vector double x) 
{
  vector double oned  = spu_splats(1.0);
  vector double range = spu_splats(1.0625);
  vector unsigned long long use_exp;
  vector double pr, qr;
  vector double eresult;
  vector double rresult;
  vector double result;

  /* Compiler Bug. Replace xbug with x when spu_cmp*() doesn't 
   * modify it's arguments! */
  volatile vector double xbug = x;
  use_exp = spu_cmpabsgt(xbug, range);

  /*
   * Calculate directly using exp(x) - 1
   */
  eresult = spu_sub(_expd2(x), oned);

  /*
   * For x in [-1.0625,1.0625], use a rational approximation.
   * The madd's are interleaved to reduce dependency stalls. Looks
   * like gcc is smart enough to do this on it's own... but why
   * take the chance.
   */
  pr = spu_madd(x, spu_splats(EXPM1_P8), spu_splats(EXPM1_P7));
  qr = spu_madd(x, spu_splats(EXPM1_Q8), spu_splats(EXPM1_Q7));
  pr = spu_madd(pr, x, spu_splats(EXPM1_P6));
  qr = spu_madd(qr, x, spu_splats(EXPM1_Q6));
  pr = spu_madd(pr, x, spu_splats(EXPM1_P5));
  qr = spu_madd(qr, x, spu_splats(EXPM1_Q5));
  pr = spu_madd(pr, x, spu_splats(EXPM1_P4));
  qr = spu_madd(qr, x, spu_splats(EXPM1_Q4));
  pr = spu_madd(pr, x, spu_splats(EXPM1_P3));
  qr = spu_madd(qr, x, spu_splats(EXPM1_Q3));
  pr = spu_madd(pr, x, spu_splats(EXPM1_P2));
  qr = spu_madd(qr, x, spu_splats(EXPM1_Q2));
  pr = spu_madd(pr, x, spu_splats(EXPM1_P1));
  qr = spu_madd(qr, x, spu_splats(EXPM1_Q1));
  pr = spu_madd(pr, x, spu_splats(EXPM1_P0));
  qr = spu_madd(qr, x, spu_splats(EXPM1_Q0));
  rresult = _divd2(pr, qr);

  /*
   * Select either direct calculation or rational approximation.
   */
  result = spu_sel(rresult, eresult, use_exp);

  return result;
}

#endif /* _EXPM1D2_H_ */
#endif /* __SPU__ */
