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
#ifndef _ACOSHD2_H_
#define _ACOSHD2_H_	1

#include <spu_intrinsics.h>
#include "logd2.h"
#include "sqrtd2.h"

/*
 * FUNCTION
 *  vector double _acoshd2(vector double x)
 *
 * DESCRIPTION
 *  The acoshd2 function returns a vector containing the hyperbolic
 *  arccosines of the corresponding elements of the input vector.
 *
 *  We are using the formula:
 *    acosh = ln(x + sqrt(x^2 - 1))
 *
 *  For x near one, we use the Taylor series:
 *
 *                infinity
 *                 ------
 *                  -   '        
 *                   -                 k
 *    acosh x =       -      C  (x - 1)
 *                   -        k
 *                  -   ,
 *                 ------
 *                 k = 0
 *
 *
 *  Special Cases:
 *	- acosh(1)        = +0
 *	- acosh(NaN)      = NaN
 *	- acosh(Infinity) = Infinity
 *	- acosh(x < 1)    = NaN
 *
 */

/*
 * Taylor Series Coefficients 
 * for x around 1.
 */
#define ACOSH_TAY01  1.0000000000000000000000000000000000000000000000000000000000000000000000E0  /* 1 / 1                            */
#define ACOSH_TAY02 -8.3333333333333333333333333333333333333333333333333333333333333333333333E-2 /* 1 / 12                           */
#define ACOSH_TAY03  1.8750000000000000000000000000000000000000000000000000000000000000000000E-2 /* 3 / 160                          */
#define ACOSH_TAY04 -5.5803571428571428571428571428571428571428571428571428571428571428571429E-3 /* 5 / 896                          */
#define ACOSH_TAY05  1.8988715277777777777777777777777777777777777777777777777777777777777778E-3 /* 35 / 18432                       */
#define ACOSH_TAY06 -6.9912997159090909090909090909090909090909090909090909090909090909090909E-4 /* 63 / 90112                       */
#define ACOSH_TAY07  2.7113694411057692307692307692307692307692307692307692307692307692307692E-4 /* 231 / 851968                     */
#define ACOSH_TAY08 -1.0910034179687500000000000000000000000000000000000000000000000000000000E-4 /* 143 / 1310720                    */
#define ACOSH_TAY09  4.5124222250545726102941176470588235294117647058823529411764705882352941E-5 /* 6435 / 142606336                 */
#define ACOSH_TAY10 -1.9065643611707185444078947368421052631578947368421052631578947368421053E-5 /* 12155 / 637534208                */
#define ACOSH_TAY11  8.1936873140789213634672619047619047619047619047619047619047619047619048E-6 /* 46189 / 5637144576               */
#define ACOSH_TAY12 -3.5705692742181860882302989130434782608695652173913043478260869565217391E-6 /* 88179 / 24696061952              */
#define ACOSH_TAY13  1.5740259550511837005615234375000000000000000000000000000000000000000000E-6 /* 676039 / 429496729600            */
#define ACOSH_TAY14 -7.0068819224144573564882631655092592592592592592592592592592592592592593E-7 /* 1300075 / 1855425871872          */
#define ACOSH_TAY15  3.1453306166503321507881427633351293103448275862068965517241379310344828E-7 /* 5014575 / 15942918602752         */
#if 0
#define ACOSH_TAY16 -1.4221629293564136230176494967552923387096774193548387096774193548387097E-7 /* 9694845 / 68169720922112         */
#define ACOSH_TAY17  6.4711106776113328206437555226412686434659090909090909090909090909090909E-8 /* 100180065 / 1548112371908608     */
#define ACOSH_TAY18 -2.9609409781171182528071637664522443498883928571428571428571428571428571E-8 /* 116680311 / 3940649673949184     */
#define ACOSH_TAY19  1.3615438056281793767600509061201198680980785472972972972972972972972973E-8 /* 2268783825 / 166633186212708352  */
#endif

static __inline vector double _acoshd2(vector double x)
{
    vec_uchar16 dup_even  = ((vec_uchar16) { 0,1,2,3,  0,1,2,3, 8,9,10,11, 8,9,10,11 });
    vec_double2 minus_oned = spu_splats(-1.0);
    vec_double2 twod       = spu_splats(2.0);
    vec_double2 xminus1;
    vec_float4  xf;
    /* Where we switch from taylor to formula */
    vec_float4  switch_approx = spu_splats(1.15f);
    vec_uint4   use_form;
    vec_double2 result, fresult, mresult;;

    
    xf = spu_roundtf(x);
    xf = spu_shuffle(xf, xf, dup_even);

    /*
     * Formula:
     *   acosh = ln(x + sqrt(x^2 - 1))
     */
    fresult = _sqrtd2(spu_madd(x, x, minus_oned));
    fresult = spu_add(x, fresult);
    fresult = _logd2(fresult);

    /*
     * Taylor Series
     */
    xminus1 = spu_add(x, minus_oned);

    mresult = spu_madd(xminus1, spu_splats(ACOSH_TAY15), spu_splats(ACOSH_TAY14));
    mresult = spu_madd(xminus1, mresult, spu_splats(ACOSH_TAY13));
    mresult = spu_madd(xminus1, mresult, spu_splats(ACOSH_TAY12));
    mresult = spu_madd(xminus1, mresult, spu_splats(ACOSH_TAY11));
    mresult = spu_madd(xminus1, mresult, spu_splats(ACOSH_TAY10));
    mresult = spu_madd(xminus1, mresult, spu_splats(ACOSH_TAY09));
    mresult = spu_madd(xminus1, mresult, spu_splats(ACOSH_TAY08));
    mresult = spu_madd(xminus1, mresult, spu_splats(ACOSH_TAY07));
    mresult = spu_madd(xminus1, mresult, spu_splats(ACOSH_TAY06));
    mresult = spu_madd(xminus1, mresult, spu_splats(ACOSH_TAY05));
    mresult = spu_madd(xminus1, mresult, spu_splats(ACOSH_TAY04));
    mresult = spu_madd(xminus1, mresult, spu_splats(ACOSH_TAY03));
    mresult = spu_madd(xminus1, mresult, spu_splats(ACOSH_TAY02));
    mresult = spu_madd(xminus1, mresult, spu_splats(ACOSH_TAY01));
    
    mresult = spu_mul(mresult, _sqrtd2(spu_mul(xminus1, twod)));

    /*
     * Select series or formula
     */
    use_form = spu_cmpgt(xf, switch_approx);
    result = spu_sel(mresult, fresult, (vec_ullong2)use_form);

    return result;
}

#endif /* _ACOSHD2_H_ */
#endif /* __SPU__ */
