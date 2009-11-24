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
#ifndef _ATANHD2_H_
#define _ATANHD2_H_	1

#include <spu_intrinsics.h>
#include "logd2.h"

/*
 * FUNCTION
 *  vector double _atanhd2(vector double x)
 *
 * DESCRIPTION
 *  The atanhd2 function returns a vector containing the hyperbolic
 *  arctangents of the corresponding elements of the input vector.
 *
 *  We are using the formula:
 *    atanh x = 1/2 * ln((1 + x)/(1 - x)) = 1/2 * [ln(1+x) - ln(1-x)]
 *  and the anti-symmetry of atanh.
 *
 *  For x near 0, we use the Taylor series:
 *    atanh x = x + x^3/3 + x^5/5 + x^7/7 + x^9/9 + ...
 *
 *  Special Cases:
 *  - atanh(1)  =  Infinity
 *  - atanh(-1) = -Infinity
 *  - atanh(x) for |x| > 1 = NaN
 *
 */

/*
 * Maclaurin Series Coefficients 
 * for x near 0.
 */
#define ATANH_MAC01 1.0000000000000000000000000000000000000000000000000000000000000000000000E0
#define ATANH_MAC03 3.3333333333333333333333333333333333333333333333333333333333333333333333E-1
#define ATANH_MAC05 2.0000000000000000000000000000000000000000000000000000000000000000000000E-1
#define ATANH_MAC07 1.4285714285714285714285714285714285714285714285714285714285714285714286E-1
#define ATANH_MAC09 1.1111111111111111111111111111111111111111111111111111111111111111111111E-1
#define ATANH_MAC11 9.0909090909090909090909090909090909090909090909090909090909090909090909E-2
#define ATANH_MAC13 7.6923076923076923076923076923076923076923076923076923076923076923076923E-2
#if 0
#define ATANH_MAC15 6.6666666666666666666666666666666666666666666666666666666666666666666667E-2
#define ATANH_MAC17 5.8823529411764705882352941176470588235294117647058823529411764705882353E-2
#define ATANH_MAC19 5.2631578947368421052631578947368421052631578947368421052631578947368421E-2
#define ATANH_MAC21 4.7619047619047619047619047619047619047619047619047619047619047619047619E-2
#define ATANH_MAC23 4.3478260869565217391304347826086956521739130434782608695652173913043478E-2
#define ATANH_MAC25 4.0000000000000000000000000000000000000000000000000000000000000000000000E-2
#define ATANH_MAC27 3.7037037037037037037037037037037037037037037037037037037037037037037037E-2
#define ATANH_MAC29 3.4482758620689655172413793103448275862068965517241379310344827586206897E-2
#define ATANH_MAC31 3.2258064516129032258064516129032258064516129032258064516129032258064516E-2
#define ATANH_MAC33 3.0303030303030303030303030303030303030303030303030303030303030303030303E-2
#define ATANH_MAC35 2.8571428571428571428571428571428571428571428571428571428571428571428571E-2
#define ATANH_MAC37 2.7027027027027027027027027027027027027027027027027027027027027027027027E-2
#define ATANH_MAC39 2.5641025641025641025641025641025641025641025641025641025641025641025641E-2
#define ATANH_MAC41 2.4390243902439024390243902439024390243902439024390243902439024390243902E-2
#define ATANH_MAC43 2.3255813953488372093023255813953488372093023255813953488372093023255814E-2
#define ATANH_MAC45 2.2222222222222222222222222222222222222222222222222222222222222222222222E-2
#define ATANH_MAC47 2.1276595744680851063829787234042553191489361702127659574468085106382979E-2
#define ATANH_MAC49 2.0408163265306122448979591836734693877551020408163265306122448979591837E-2
#define ATANH_MAC51 1.9607843137254901960784313725490196078431372549019607843137254901960784E-2
#define ATANH_MAC53 1.8867924528301886792452830188679245283018867924528301886792452830188679E-2
#define ATANH_MAC55 1.8181818181818181818181818181818181818181818181818181818181818181818182E-2
#define ATANH_MAC57 1.7543859649122807017543859649122807017543859649122807017543859649122807E-2
#define ATANH_MAC59 1.6949152542372881355932203389830508474576271186440677966101694915254237E-2
#endif


static __inline vector double _atanhd2(vector double x)
{
    vec_uchar16 dup_even  = ((vec_uchar16) { 0,1,2,3,  0,1,2,3, 8,9,10,11, 8,9,10,11 });
    vec_double2 sign_mask = spu_splats(-0.0);
    vec_double2 oned      = spu_splats(1.0);
    vec_double2 onehalfd  = spu_splats(0.5);
    vec_uint4   infminus1 = spu_splats(0x7FEFFFFFU);
    vec_uint4   isinfnan;
    vec_uint4   xabshigh;
    vec_double2 xabs, xsqu;
    /* Where we switch from maclaurin to formula */
    vec_float4  switch_approx = spu_splats(0.08f);
    vec_uint4   use_form;
    vec_float4  xf;
    vec_double2 result, fresult, mresult;;

    xabs = spu_andc(x, sign_mask);
    xsqu = spu_mul(x, x);

    xf = spu_roundtf(xabs);
    xf = spu_shuffle(xf, xf, dup_even);

    /*
     * Formula:
     *   atanh = 1/2 * ln((1 + x)/(1 - x)) = 1/2 * [ln(1+x) - ln(1-x)]
     */
    fresult = spu_sub(_logd2(spu_add(oned, xabs)), _logd2(spu_sub(oned, xabs)));
    fresult = spu_mul(fresult, onehalfd);


    /*
     * Taylor Series
     */
    mresult = spu_madd(xsqu, spu_splats(ATANH_MAC13), spu_splats(ATANH_MAC11));
    mresult = spu_madd(xsqu, mresult, spu_splats(ATANH_MAC09));
    mresult = spu_madd(xsqu, mresult, spu_splats(ATANH_MAC07));
    mresult = spu_madd(xsqu, mresult, spu_splats(ATANH_MAC05));
    mresult = spu_madd(xsqu, mresult, spu_splats(ATANH_MAC03));
    mresult = spu_madd(xsqu, mresult, spu_splats(ATANH_MAC01));
    mresult = spu_mul(xabs, mresult);


    /*
     * Choose between series and formula
     */
    use_form = spu_cmpgt(xf, switch_approx);
    result = spu_sel(mresult, fresult, (vec_ullong2)use_form);

    /* Infinity and NaN */
    xabshigh = (vec_uint4)spu_shuffle(xabs, xabs, dup_even);
    isinfnan = spu_cmpgt(xabshigh, infminus1);
    result = spu_sel(result, x, (vec_ullong2)isinfnan);

    /* Restore sign - atanh is an anti-symmetric */
    result = spu_sel(result, x, (vec_ullong2)sign_mask);

    return result;
}

#endif /* _ATANHD2_H_ */
#endif /* __SPU__ */
