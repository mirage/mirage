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
#ifndef _LOG1PD2_H_
#define _LOG1PD2_H_	1

#include <spu_intrinsics.h>
#include "simdmath.h"

#include "logd2.h"
#include "divd2.h"



#define LOG1PD2_P0 0.0000000000000000000000000e+00
#define LOG1PD2_P1 1.0000000000000000000000000e+00
#define LOG1PD2_P2 2.3771612265431403265836252e+00
#define LOG1PD2_P3 2.0034423569559494104908026e+00
#define LOG1PD2_P4 7.1309327316770110272159400e-01
#define LOG1PD2_P5 9.8219761968547217301228613e-02
#define LOG1PD2_P6 3.4385125174546914139650511e-03

#define LOG1PD2_Q0 1.0000000000000000000000000e+00
#define LOG1PD2_Q1 2.8771612265431403265836252e+00
#define LOG1PD2_Q2 3.1086896368941925317130881e+00
#define LOG1PD2_Q3 1.5583843494335058998956356e+00
#define LOG1PD2_Q4 3.6047236436186669283898709e-01
#define LOG1PD2_Q5 3.2620075387969869884496887e-02
#define LOG1PD2_Q6 6.8047193336239690346356479e-04


/*
 * FUNCTION
 *	vector double _log1pd2(vector double x)
 *
 * DESCRIPTION
 *	The function _log1pd2 computes the natural logarithm of x + 1 
 *	for each of the double word elements of x.
 *
 */

static __inline vector double _log1pd2(vector double x) 
{
  vector double oned  = spu_splats(1.0);
  vector double rangehi = spu_splats(0.35);
  vector double rangelo = spu_splats(0.0);
  vector unsigned long long use_log;
  vector double pr, qr;
  vector double eresult;
  vector double rresult;
  vector double result;

  /* Compiler Bug. Replace xbug with x when spu_cmp*() doesn't 
   * modify it's arguments! */
  volatile vector double xbug = x;
  use_log = spu_or(spu_cmpgt(xbug, rangehi), spu_cmpgt(rangelo, xbug));

  /*
   * Calculate directly using log(x+1)
   */
  eresult = _logd2(spu_add(x, oned));

  /*
   * For x in [0.0,0.35], use a rational approximation.
   */
  pr = spu_madd(x, spu_splats(LOG1PD2_P6), spu_splats(LOG1PD2_P5));
  qr = spu_madd(x, spu_splats(LOG1PD2_Q6), spu_splats(LOG1PD2_Q5));
  pr = spu_madd(pr, x, spu_splats(LOG1PD2_P4));
  qr = spu_madd(qr, x, spu_splats(LOG1PD2_Q4));
  pr = spu_madd(pr, x, spu_splats(LOG1PD2_P3));
  qr = spu_madd(qr, x, spu_splats(LOG1PD2_Q3));
  pr = spu_madd(pr, x, spu_splats(LOG1PD2_P2));
  qr = spu_madd(qr, x, spu_splats(LOG1PD2_Q2));
  pr = spu_madd(pr, x, spu_splats(LOG1PD2_P1));
  qr = spu_madd(qr, x, spu_splats(LOG1PD2_Q1));
  pr = spu_madd(pr, x, spu_splats(LOG1PD2_P0));
  qr = spu_madd(qr, x, spu_splats(LOG1PD2_Q0));
  rresult = _divd2(pr, qr);

  /*
   * Select either direct calculation or rational approximation.
   */
  result = spu_sel(rresult, eresult, use_log);

  return result;
}

#endif /* _LOG1PD2_H_ */
#endif /* __SPU__ */
