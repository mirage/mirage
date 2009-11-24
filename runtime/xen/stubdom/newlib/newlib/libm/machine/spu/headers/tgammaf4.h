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
#ifndef _TGAMMAF4_H_
#define _TGAMMAF4_H_	1

#include <spu_intrinsics.h>
#include "simdmath.h"

#include "recipf4.h"
#include "truncf4.h"
#include "expf4.h"
#include "logf4.h"
#include "divf4.h"
#include "sinf4.h"
#include "powf4.h"
#include "tgammad2.h"

/*
 * FUNCTION
 *  vector float _tgammaf4(vector float x)
 *
 * DESCRIPTION
 *  The tgammaf4 function returns a vector containing tgamma for each 
 *  element of x 
 *
 *	We take a fairly standard approach - break the domain into 5 separate regions:
 *
 *	1. [-infinity, 0)  - use gamma(x) = pi/(x*gamma(-x)*sin(x*pi))
 *	2. [0, 1)          - push x into [1,2), then adjust the 
 *	                     result.
 *	3. [1, 2)          - use a rational approximation.
 *	4. [2, 10)         - pull back into [1, 2), then adjust
 *	                     the result.
 *	5. [10, +infinity] - use Stirling's Approximation.
 *
 *
 * Special Cases:
 *	- tgamma(+/- 0) returns +/- infinity
 *	- tgamma(negative integer) returns NaN
 *	- tgamma(-infinity) returns NaN
 *	- tgamma(infinity) returns infinity
 *
 */

/*
 * Coefficients for Stirling's Series for Gamma() are defined in 
 * tgammad2.h
 */

/*
 * Rational Approximation Coefficients for the 
 * domain [1, 2) are defined in tgammad2.h
 */


static __inline vector float _tgammaf4(vector float x)
{
    vector float signbit = spu_splats(-0.0f);
    vector float zerof   = spu_splats(0.0f);
    vector float halff   = spu_splats(0.5f);
    vector float onef    = spu_splats(1.0f);
    vector float ninep9f = (vector float)spu_splats(0x411FFFFF); /* Next closest to 10.0 */
    vector float t38f    = spu_splats(38.0f);
    vector float pi      = spu_splats((float)SM_PI);
    vector float sqrt2pi = spu_splats(2.506628274631000502415765284811f);
    vector float inf     = (vec_float4)spu_splats(0x7F800000);
    vector float nan     = (vec_float4)spu_splats(0x7FFFFFFF);

    vector float xabs;
    vector float xscaled;
    vector float xtrunc;
    vector float xinv;
    vector float nresult; /* Negative x result */
    vector float rresult; /* Rational Approx result */
    vector float sresult; /* Stirling's result */
    vector float result;
    vector float pr,qr;

    vector unsigned int gt0   = spu_cmpgt(x, zerof);
    vector unsigned int gt1   = spu_cmpgt(x, onef);
    vector unsigned int gt9p9 = spu_cmpgt(x, ninep9f);
    vector unsigned int gt38  = spu_cmpgt(x, t38f);

    xabs    = spu_andc(x, signbit);

    /*
     * For x in [0, 1], add 1 to x, use rational
     * approximation, then use:
     *
     * gamma(x) = gamma(x+1)/x
     *
     */
    xabs = spu_sel(spu_add(xabs, onef), xabs, gt1);
    xtrunc = _truncf4(xabs);


    /*
     * For x in [2, 10):
     */
    xscaled = spu_add(onef, spu_sub(xabs, xtrunc));

    /*
     * For x in [1,2), use a rational approximation.
     */
    pr = spu_madd(xscaled, spu_splats((float)TGD2_P07), spu_splats((float)TGD2_P06));
    pr = spu_madd(pr, xscaled, spu_splats((float)TGD2_P05));
    pr = spu_madd(pr, xscaled, spu_splats((float)TGD2_P04));
    pr = spu_madd(pr, xscaled, spu_splats((float)TGD2_P03));
    pr = spu_madd(pr, xscaled, spu_splats((float)TGD2_P02));
    pr = spu_madd(pr, xscaled, spu_splats((float)TGD2_P01));
    pr = spu_madd(pr, xscaled, spu_splats((float)TGD2_P00));

    qr = spu_madd(xscaled, spu_splats((float)TGD2_Q07), spu_splats((float)TGD2_Q06));
    qr = spu_madd(qr, xscaled, spu_splats((float)TGD2_Q05));
    qr = spu_madd(qr, xscaled, spu_splats((float)TGD2_Q04));
    qr = spu_madd(qr, xscaled, spu_splats((float)TGD2_Q03));
    qr = spu_madd(qr, xscaled, spu_splats((float)TGD2_Q02));
    qr = spu_madd(qr, xscaled, spu_splats((float)TGD2_Q01));
    qr = spu_madd(qr, xscaled, spu_splats((float)TGD2_Q00));

    rresult = _divf4(pr, qr);
    rresult = spu_sel(_divf4(rresult, x), rresult, gt1);

    /*
     * If x was in [2,10) and we pulled it into [1,2), we need to push
     * it back out again.
     */
    rresult = spu_sel(rresult, spu_mul(rresult, xscaled), spu_cmpgt(x, xscaled)); /* [2,3) */
    xscaled = spu_add(xscaled, onef);
    rresult = spu_sel(rresult, spu_mul(rresult, xscaled), spu_cmpgt(x, xscaled)); /* [3,4) */
    xscaled = spu_add(xscaled, onef);
    rresult = spu_sel(rresult, spu_mul(rresult, xscaled), spu_cmpgt(x, xscaled)); /* [4,5) */
    xscaled = spu_add(xscaled, onef);
    rresult = spu_sel(rresult, spu_mul(rresult, xscaled), spu_cmpgt(x, xscaled)); /* [5,6) */
    xscaled = spu_add(xscaled, onef);
    rresult = spu_sel(rresult, spu_mul(rresult, xscaled), spu_cmpgt(x, xscaled)); /* [6,7) */
    xscaled = spu_add(xscaled, onef);
    rresult = spu_sel(rresult, spu_mul(rresult, xscaled), spu_cmpgt(x, xscaled)); /* [7,8) */
    xscaled = spu_add(xscaled, onef);
    rresult = spu_sel(rresult, spu_mul(rresult, xscaled), spu_cmpgt(x, xscaled)); /* [8,9) */
    xscaled = spu_add(xscaled, onef);
    rresult = spu_sel(rresult, spu_mul(rresult, xscaled), spu_cmpgt(x, xscaled)); /* [9,10) */


    /*
     * For x >= 10, we use Stirling's Approximation
     */
    vector float sum;
    xinv    = _recipf4(xabs);            
    sum = spu_madd(xinv, spu_splats((float)STIRLING_16), spu_splats((float)STIRLING_15));
    sum = spu_madd(sum, xinv, spu_splats((float)STIRLING_14));
    sum = spu_madd(sum, xinv, spu_splats((float)STIRLING_13));
    sum = spu_madd(sum, xinv, spu_splats((float)STIRLING_12));
    sum = spu_madd(sum, xinv, spu_splats((float)STIRLING_11));
    sum = spu_madd(sum, xinv, spu_splats((float)STIRLING_10));
    sum = spu_madd(sum, xinv, spu_splats((float)STIRLING_09));
    sum = spu_madd(sum, xinv, spu_splats((float)STIRLING_08));
    sum = spu_madd(sum, xinv, spu_splats((float)STIRLING_07));
    sum = spu_madd(sum, xinv, spu_splats((float)STIRLING_06));
    sum = spu_madd(sum, xinv, spu_splats((float)STIRLING_05));
    sum = spu_madd(sum, xinv, spu_splats((float)STIRLING_04));
    sum = spu_madd(sum, xinv, spu_splats((float)STIRLING_03));
    sum = spu_madd(sum, xinv, spu_splats((float)STIRLING_02));
    sum = spu_madd(sum, xinv, spu_splats((float)STIRLING_01));
    sum = spu_madd(sum, xinv, spu_splats((float)STIRLING_00));

    sum = spu_mul(sum, sqrt2pi);
    sum = spu_mul(sum, _powf4(x, spu_sub(x, halff)));
    sresult = spu_mul(sum, _expf4(spu_or(x, signbit)));

    /*
     * Choose rational approximation or Stirling's result.
     */
    result = spu_sel(rresult, sresult, gt9p9);

    result = spu_sel(result, inf, gt38);

    /* For x < 0, use:
     * gamma(x) = pi/(x*gamma(-x)*sin(x*pi))
     */
    nresult = _divf4(pi, spu_mul(x, spu_mul(result, _sinf4(spu_mul(x, pi)))));
    result = spu_sel(nresult, result, gt0);

    /*
     * x = non-positive integer, return NaN.
     */
    result = spu_sel(result, nan, spu_andc(spu_cmpeq(x, xtrunc), gt0));

    return result;
}

#endif /* _TGAMMAF4_H_ */
#endif /* __SPU__ */
