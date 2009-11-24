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
#ifndef _LOG1PF4_H_
#define _LOG1PF4_H_	1

#include <spu_intrinsics.h>
#include "simdmath.h"

#include "logf4.h"
#include "divf4.h"

/*
 * FUNCTION
 *	vector float _log1pf4(vector float x)
 *
 * DESCRIPTION
 *	The function _log1pf4 computes the natural logarithm of x + 1 
 *	for each of the float word elements of x.
 *
 *
 */

#define LOG1PF4_P0 0.0000000000000000000000000e+00f
#define LOG1PF4_P1 1.0000000000000000000000000e+00f
#define LOG1PF4_P2 1.4220868022897381610647471e+00f
#define LOG1PF4_P3 5.4254553902256308361984338e-01f
#define LOG1PF4_P4 4.5971908823142115796400731e-02f

#define LOG1PF4_Q0 1.0000000000000000000000000e+00f
#define LOG1PF4_Q1 1.9220868007537357247116461e+00f
#define LOG1PF4_Q2 1.1702556461286610645089468e+00f
#define LOG1PF4_Q3 2.4040413392943396631018516e-01f
#define LOG1PF4_Q4 1.0637426466449625625521058e-02f


static __inline vector float _log1pf4(vector float x) 
{
  vector float onef  = spu_splats(1.0f);
  vector float range = spu_splats(0.35f);
  vector unsigned int use_log;
  vector float pr, qr;
  vector float eresult;
  vector float rresult;
  vector float result;

  use_log = spu_cmpabsgt(x, range);

  /*
   * Calculate directly using log(x+1)
   */
  eresult = _logf4(spu_add(x, onef));

  /*
   * For x in [-0.35,0.35], use a rational approximation.
   */
  pr = spu_madd(x, spu_splats((float)LOG1PF4_P4), spu_splats((float)LOG1PF4_P3));
  qr = spu_madd(x, spu_splats((float)LOG1PF4_Q4), spu_splats((float)LOG1PF4_Q3));
  pr = spu_madd(pr, x, spu_splats((float)LOG1PF4_P2));
  qr = spu_madd(qr, x, spu_splats((float)LOG1PF4_Q2));
  pr = spu_madd(pr, x, spu_splats((float)LOG1PF4_P1));
  qr = spu_madd(qr, x, spu_splats((float)LOG1PF4_Q1));
  pr = spu_madd(pr, x, spu_splats((float)LOG1PF4_P0));
  qr = spu_madd(qr, x, spu_splats((float)LOG1PF4_Q0));
  rresult = _divf4(pr, qr);

  /*
   * Select either direct calculation or rational approximation.
   */
  result = spu_sel(rresult, eresult, use_log);

  return result;
}

#endif /* _LOG1PF4_H_ */
#endif /* __SPU__ */
