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

#ifndef _TGAMMAD2_H_
#define _TGAMMAD2_H_	1

#include <spu_intrinsics.h>
#include "simdmath.h"

#include "recipd2.h"
#include "truncd2.h"
#include "expd2.h"
#include "logd2.h"
#include "divd2.h"
#include "sind2.h"
#include "powd2.h"


/*
 * FUNCTION
 *	vector double _tgammad2(vector double x)
 *
 * DESCRIPTION
 *	_tgammad2 
 *
 *	This is an interesting function to approximate fast
 *	and accurately. We take a fairly standard approach - break 
 *	the domain into 5 separate regions:
 *
 *	1. [-infinity, 0)  - use 
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
 * Coefficients for Stirling's Series for Gamma()
 */
/* 1/ 1 */
#define STIRLING_00   1.000000000000000000000000000000000000E0
/* 1/ 12 */
#define STIRLING_01   8.333333333333333333333333333333333333E-2
/* 1/ 288 */
#define STIRLING_02   3.472222222222222222222222222222222222E-3
/* -139/ 51840 */
#define STIRLING_03  -2.681327160493827160493827160493827160E-3
/* -571/ 2488320 */
#define STIRLING_04  -2.294720936213991769547325102880658436E-4
/* 163879/ 209018880 */
#define STIRLING_05   7.840392217200666274740348814422888497E-4
/* 5246819/ 75246796800 */
#define STIRLING_06   6.972813758365857774293988285757833083E-5
/* -534703531/ 902961561600 */
#define STIRLING_07  -5.921664373536938828648362256044011874E-4
/* -4483131259/ 86684309913600 */
#define STIRLING_08  -5.171790908260592193370578430020588228E-5
/* 432261921612371/ 514904800886784000 */
#define STIRLING_09   8.394987206720872799933575167649834452E-4
/* 6232523202521089/ 86504006548979712000 */
#define STIRLING_10   7.204895416020010559085719302250150521E-5
/* -25834629665134204969/ 13494625021640835072000 */
#define STIRLING_11  -1.914438498565477526500898858328522545E-3
/* -1579029138854919086429/ 9716130015581401251840000 */
#define STIRLING_12  -1.625162627839158168986351239802709981E-4
/* 746590869962651602203151/ 116593560186976815022080000 */
#define STIRLING_13   6.403362833808069794823638090265795830E-3
/* 1511513601028097903631961/ 2798245444487443560529920000 */
#define STIRLING_14   5.401647678926045151804675085702417355E-4
/* -8849272268392873147705987190261/ 299692087104605205332754432000000 */
#define STIRLING_15  -2.952788094569912050544065105469382445E-2
/* -142801712490607530608130701097701/ 57540880724084199423888850944000000 */
#define STIRLING_16  -2.481743600264997730915658368743464324E-3


/*
 * Rational Approximation Coefficients for the 
 * domain [1, 2).
 */
#define TGD2_P00     -1.8211798563156931777484715e+05
#define TGD2_P01     -8.7136501560410004458390176e+04
#define TGD2_P02     -3.9304030489789496641606092e+04
#define TGD2_P03     -1.2078833505605729442322627e+04
#define TGD2_P04     -2.2149136023607729839568492e+03
#define TGD2_P05     -7.2672456596961114883015398e+02
#define TGD2_P06     -2.2126466212611862971471055e+01
#define TGD2_P07     -2.0162424149396112937893122e+01

#define TGD2_Q00     1.0000000000000000000000000
#define TGD2_Q01     -1.8212849094205905566923320e+05
#define TGD2_Q02     -1.9220660507239613798446953e+05
#define TGD2_Q03     2.9692670736656051303725690e+04
#define TGD2_Q04     3.0352658363629092491464689e+04
#define TGD2_Q05     -1.0555895821041505769244395e+04
#define TGD2_Q06     1.2786642579487202056043316e+03
#define TGD2_Q07     -5.5279768804094054246434098e+01

static __inline vector double _tgammad2(vector double x) 
{
    vector double signbit = spu_splats(-0.0);
    vector double zerod   = spu_splats(0.0);
    vector double halfd   = spu_splats(0.5);
    vector double oned    = spu_splats(1.0);
    vector double ninep9d = (vec_double2)spu_splats(0x4023FFFFFFFFFFFFull);
    vector double twohd   = spu_splats(200.0);
    vector double pi      = spu_splats(SM_PI);
    vector double sqrt2pi = spu_splats(2.50662827463100050241576528481);
    vector double inf     = (vector double)spu_splats(0x7FF0000000000000ull);
    vector double nan     = (vector double)spu_splats(0x7FF8000000000000ull);


    vector double xabs;
    vector double xscaled;
    vector double xtrunc;
    vector double xinv;
    vector double nresult;
    vector double rresult; /* Rational Approx result */
    vector double sresult; /* Stirling's result */
    vector double result;
    vector double pr,qr;

    vector unsigned long long gt0   = spu_cmpgt(x, zerod);
    vector unsigned long long gt1   = spu_cmpgt(x, oned);
    vector unsigned long long gt9p9 = spu_cmpgt(x, ninep9d);
    vector unsigned long long gt200 = spu_cmpgt(x, twohd);


    xabs    = spu_andc(x, signbit);

    /*
     * For x in [0, 1], add 1 to x, use rational
     * approximation, then use:
     *
     * gamma(x) = gamma(x+1)/x
     *
     */
    xabs = spu_sel(spu_add(xabs, oned), xabs, gt1);
    xtrunc = _truncd2(xabs);


    /*
     * For x in [2, 10):
     */
    xscaled = spu_add(oned, spu_sub(xabs, xtrunc));

    /*
     * For x in [1,2), use a rational approximation.
     */
    pr = spu_madd(xscaled, spu_splats(TGD2_P07), spu_splats(TGD2_P06));
    pr = spu_madd(pr, xscaled, spu_splats(TGD2_P05));
    pr = spu_madd(pr, xscaled, spu_splats(TGD2_P04));
    pr = spu_madd(pr, xscaled, spu_splats(TGD2_P03));
    pr = spu_madd(pr, xscaled, spu_splats(TGD2_P02));
    pr = spu_madd(pr, xscaled, spu_splats(TGD2_P01));
    pr = spu_madd(pr, xscaled, spu_splats(TGD2_P00));

    qr = spu_madd(xscaled, spu_splats(TGD2_Q07), spu_splats(TGD2_Q06));
    qr = spu_madd(qr, xscaled, spu_splats(TGD2_Q05));
    qr = spu_madd(qr, xscaled, spu_splats(TGD2_Q04));
    qr = spu_madd(qr, xscaled, spu_splats(TGD2_Q03));
    qr = spu_madd(qr, xscaled, spu_splats(TGD2_Q02));
    qr = spu_madd(qr, xscaled, spu_splats(TGD2_Q01));
    qr = spu_madd(qr, xscaled, spu_splats(TGD2_Q00));

    rresult = _divd2(pr, qr);
    rresult = spu_sel(_divd2(rresult, x), rresult, gt1);

    /*
     * If x was in [2,10) and we pulled it into [1,2), we need to push
     * it back out again.
     */
    rresult = spu_sel(rresult, spu_mul(rresult, xscaled), spu_cmpgt(x, xscaled)); /* [2,3) */
    xscaled = spu_add(xscaled, oned);
    rresult = spu_sel(rresult, spu_mul(rresult, xscaled), spu_cmpgt(x, xscaled)); /* [3,4) */
    xscaled = spu_add(xscaled, oned);
    rresult = spu_sel(rresult, spu_mul(rresult, xscaled), spu_cmpgt(x, xscaled)); /* [4,5) */
    xscaled = spu_add(xscaled, oned);
    rresult = spu_sel(rresult, spu_mul(rresult, xscaled), spu_cmpgt(x, xscaled)); /* [5,6) */
    xscaled = spu_add(xscaled, oned);
    rresult = spu_sel(rresult, spu_mul(rresult, xscaled), spu_cmpgt(x, xscaled)); /* [6,7) */
    xscaled = spu_add(xscaled, oned);
    rresult = spu_sel(rresult, spu_mul(rresult, xscaled), spu_cmpgt(x, xscaled)); /* [7,8) */
    xscaled = spu_add(xscaled, oned);
    rresult = spu_sel(rresult, spu_mul(rresult, xscaled), spu_cmpgt(x, xscaled)); /* [8,9) */
    xscaled = spu_add(xscaled, oned);
    rresult = spu_sel(rresult, spu_mul(rresult, xscaled), spu_cmpgt(x, xscaled)); /* [9,10) */


    /*
     * For x >= 10, we use Stirling's Approximation
     */
    vector double sum;
    xinv    = _recipd2(xabs);            
    sum = spu_madd(xinv, spu_splats(STIRLING_16), spu_splats(STIRLING_15));
    sum = spu_madd(sum, xinv, spu_splats(STIRLING_14));
    sum = spu_madd(sum, xinv, spu_splats(STIRLING_13));
    sum = spu_madd(sum, xinv, spu_splats(STIRLING_12));
    sum = spu_madd(sum, xinv, spu_splats(STIRLING_11));
    sum = spu_madd(sum, xinv, spu_splats(STIRLING_10));
    sum = spu_madd(sum, xinv, spu_splats(STIRLING_09));
    sum = spu_madd(sum, xinv, spu_splats(STIRLING_08));
    sum = spu_madd(sum, xinv, spu_splats(STIRLING_07));
    sum = spu_madd(sum, xinv, spu_splats(STIRLING_06));
    sum = spu_madd(sum, xinv, spu_splats(STIRLING_05));
    sum = spu_madd(sum, xinv, spu_splats(STIRLING_04));
    sum = spu_madd(sum, xinv, spu_splats(STIRLING_03));
    sum = spu_madd(sum, xinv, spu_splats(STIRLING_02));
    sum = spu_madd(sum, xinv, spu_splats(STIRLING_01));
    sum = spu_madd(sum, xinv, spu_splats(STIRLING_00));

    sum = spu_mul(sum, sqrt2pi);
    sum = spu_mul(sum, _powd2(x, spu_sub(x, halfd)));
    sresult = spu_mul(sum, _expd2(spu_or(x, signbit)));

    /*
     * Choose rational approximation or Stirling's result.
     */
    result = spu_sel(rresult, sresult, gt9p9);


    result = spu_sel(result, inf, gt200);

    /* For x < 0, use:
     *
     * gamma(x) = pi/(x*gamma(-x)*sin(x*pi))
     * or
     * gamma(x) = pi/(gamma(1 - x)*sin(x*pi))
     */
    nresult = _divd2(pi, spu_mul(x, spu_mul(result, _sind2(spu_mul(x, pi)))));
    result = spu_sel(nresult, result, gt0);

    /*
     * x = non-positive integer, return NaN.
     */
    result = spu_sel(result, nan, spu_andc(spu_cmpeq(x, xtrunc), gt0));


    return result;
}

#endif /* _TGAMMAD2_H_ */
#endif /* __SPU__ */
