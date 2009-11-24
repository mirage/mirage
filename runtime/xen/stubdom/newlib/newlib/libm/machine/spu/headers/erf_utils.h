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
#ifndef _ERF_UTILS_H_
#define _ERF_UTILS_H_	1

#include <spu_intrinsics.h>


/*
 * This file contains approximation methods for the erf and erfc functions.
 */


#define SQRT_PI          1.7724538509055160272981674833411451827975494561223871282138077898529113E0
#define INV_SQRT_PI      5.6418958354775628694807945156077258584405062932899885684408572171064247E-1
#define TWO_OVER_SQRT_PI 1.1283791670955125738961589031215451716881012586579977136881714434212849E0

/*
 * Coefficients of Taylor Series Expansion of Error Function
 */
#define TAYLOR_ERF_00  1.0000000000000000000000000000000000000000000000000000000000000000000000E0
#define TAYLOR_ERF_01 -3.3333333333333333333333333333333333333333333333333333333333333333333333E-1
#define TAYLOR_ERF_02  1.0000000000000000000000000000000000000000000000000000000000000000000000E-1
#define TAYLOR_ERF_03 -2.3809523809523809523809523809523809523809523809523809523809523809523810E-2
#define TAYLOR_ERF_04  4.6296296296296296296296296296296296296296296296296296296296296296296296E-3
#define TAYLOR_ERF_05 -7.5757575757575757575757575757575757575757575757575757575757575757575758E-4
#define TAYLOR_ERF_06  1.0683760683760683760683760683760683760683760683760683760683760683760684E-4
#define TAYLOR_ERF_07 -1.3227513227513227513227513227513227513227513227513227513227513227513228E-5
#define TAYLOR_ERF_08  1.4589169000933706816059757236227824463118580765639589169000933706816060E-6
#define TAYLOR_ERF_09 -1.4503852223150468764503852223150468764503852223150468764503852223150469E-7
#define TAYLOR_ERF_10  1.3122532963802805072646342487612328882170152011421852691693961535231377E-8
#define TAYLOR_ERF_11 -1.0892221037148573380457438428452921206544394950192051641327003645844226E-9
#define TAYLOR_ERF_12  8.3507027951472395916840361284805729250173694618139062583507027951472396E-11
#define TAYLOR_ERF_13 -5.9477940136376350368119915445018325676761890753660300985403866062302276E-12
#define TAYLOR_ERF_14  3.9554295164585257633971372340283122987009139171153402133150354277885750E-13
#define TAYLOR_ERF_15 -2.4668270102644569277100425760606678852113226579859111007771188689434124E-14
#define TAYLOR_ERF_16  1.4483264643598137264964265124598618265445265605599099265926266086599580E-15
#define TAYLOR_ERF_17 -8.0327350124157736091398445228866286178099792434415172399254921152569101E-17
#define TAYLOR_ERF_18  4.2214072888070882330314498243398198441944335363431396906515348954052831E-18
#define TAYLOR_ERF_19 -2.1078551914421358248605080094544309613386510235451574703658136454790212E-19
#define TAYLOR_ERF_20  1.0025164934907719167019489313258878962464315843690383090764235630936808E-20
#define TAYLOR_ERF_21 -4.5518467589282002862436219473268442686715055325725991884976042178118399E-22
#define TAYLOR_ERF_22  1.9770647538779051748330883205561040762916640191981996475292624380394860E-23
#define TAYLOR_ERF_23 -8.2301492992142213568444934713251326025092396728879726307878639881384709E-25
#define TAYLOR_ERF_24  3.2892603491757517327524761322472893904586246991984244357740612877764297E-26
#define TAYLOR_ERF_25 -1.2641078988989163521950692586675857265291969432213552733563059066748632E-27
#define TAYLOR_ERF_26  4.6784835155184857737263085770716162592880293254201102279514950101899871E-29
#define TAYLOR_ERF_27 -1.6697617934173720269864939702679842541566703989714871520634965356233624E-30
#define TAYLOR_ERF_28  5.7541916439821717721965644338808981189609568886862025916975131240153466E-32
#define TAYLOR_ERF_29 -1.9169428621097825307726719621929350834644917747230482041306735714136456E-33
#define TAYLOR_ERF_30  6.1803075882227961374638057797477142035193997108557291827163792739565622E-35
#define TAYLOR_ERF_31 -1.9303572088151078565555153741147494440075954038003045578376811864380455E-36
#define TAYLOR_ERF_32  5.8467550074688362962979552196744814890614668480489993819122074396921572E-38
#define TAYLOR_ERF_33 -1.7188560628017836239681912676564509126594090688520350964463748691994130E-39
#define TAYLOR_ERF_34  4.9089239645234229670020807729318930583197104694410209489303971115243253E-41
#define TAYLOR_ERF_35 -1.3630412617791395763506783635102640685072837923196396196225247512884444E-42
#define TAYLOR_ERF_36  3.6824935154611457351939940566677606112639706717920248475342183158858278E-44
#define TAYLOR_ERF_37 -9.6872802388707617538436600409638387251268417672366779772972229571050606E-46
#define TAYLOR_ERF_38  2.4830690974549115910398991902675594818336060579041382375163763560590552E-47
#define TAYLOR_ERF_39 -6.2056579196373967059419746072899084745598074150801247740591035188752759E-49
#define TAYLOR_ERF_40  1.5131079495412170980537530678268603996611876104670674603415715370097123E-50
#define TAYLOR_ERF_41 -3.6015793098101259166133998969725445892611283117200253978156713046660799E-52
#define TAYLOR_ERF_42  8.3734196838722815428266720293759440030440798283686864991232694198118944E-54
#define TAYLOR_ERF_43 -1.9025412272898795272394202686366085010926137006451172211319911806576077E-55
#define TAYLOR_ERF_44  4.2267897541935525758383443148974703675959497435169866761614717241371774E-57
#define TAYLOR_ERF_45 -9.1864295023986856959612367283485924961181813717463202485560679718732304E-59

  /*
   * Taylor Series Expansion of Erf
   *
   *                       infinite
   *                      ---------
   *                       -            n     2n
   *            2 * x        -        -1  *  x
   * erf(x) =    ----    *    -      ------------
   *            sqrt(pi)     -        (2n + 1) * n!
   *                       -     
   *                      ---------
   *                       n = 0
   *
   * 45 terms give us accurate results for 0 <= x < 2.5
   */
#define TAYLOR_ERF(_xabs, _xsqu, _tresult)  {                                          \
  _tresult = spu_madd(_xsqu, spu_splats(TAYLOR_ERF_45), spu_splats(TAYLOR_ERF_44));    \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_43));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_42));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_41));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_40));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_39));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_38));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_37));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_36));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_35));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_34));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_33));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_32));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_31));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_30));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_29));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_28));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_27));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_26));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_25));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_24));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_23));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_22));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_21));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_20));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_19));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_18));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_17));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_16));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_15));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_14));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_13));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_12));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_11));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_10));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_09));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_08));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_07));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_06));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_05));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_04));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_03));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_02));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_01));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats(TAYLOR_ERF_00));                     \
  _tresult = spu_mul(_tresult, _xabs);                                                 \
  _tresult = spu_mul(_tresult, spu_splats(TWO_OVER_SQRT_PI));                          \
}

#define TAYLOR_ERFF4(_xabs, _xsqu, _tresult)  {                                          \
  _tresult = spu_madd(_xsqu, spu_splats((float)TAYLOR_ERF_45), spu_splats((float)TAYLOR_ERF_44));    \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_43));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_42));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_41));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_40));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_39));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_38));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_37));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_36));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_35));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_34));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_33));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_32));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_31));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_30));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_29));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_28));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_27));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_26));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_25));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_24));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_23));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_22));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_21));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_20));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_19));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_18));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_17));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_16));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_15));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_14));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_13));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_12));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_11));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_10));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_09));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_08));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_07));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_06));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_05));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_04));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_03));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_02));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_01));                     \
  _tresult = spu_madd(_tresult, _xsqu, spu_splats((float)TAYLOR_ERF_00));                     \
  _tresult = spu_mul(_tresult, _xabs);                                                 \
  _tresult = spu_mul(_tresult, spu_splats((float)TWO_OVER_SQRT_PI));                          \
}



  /*
   * Continued Fractions Approximation of Erfc()
   *                                             (                      )
   *                          1                 (  1    v   2v   3v      )
   *   erfc(x)  =  -------------------------  * ( ---  ---  ---  --- ... )
   *               sqrt(pi) * x * exp(x^2)      (  1+   1+  1+   1+      )
   *                                             (                      )
   *                                                Continued Fractions
   *          1
   *   v =  -----
   *        2*x^2
   *
   *   We are using a backward recurrence calculation to estimate the continued fraction.
   *
   *   p    =   a   p        +  b   q
   *     m,n     m   m+1,n       m    m+1,n
   *
   *   q    =   p
   *     m,n     m+1,n
   *
   *   With,
   *
   *   p    =   a   ;   q    =  1
   *    n,n      n        n,n
   *
   *
   *   a  =  0,    b   =  1,
   *    0           0
   *
   *   a  =  1,    b   =  n/2x^2
   *    n           n
   *
   *
   *    F     =   p    /    q
   *     0,n       0,n       0,n
   *
   * Ref: "Computing the Incomplete Gamma Function to Arbitrary Precision",
   *       by Serge Winitzki, Department of Physics, Ludwig-Maximilians University, Munich, Germany.
   *
   */

#define CONTFRAC_ERFCF4(_xabs, _xsqu, _presult) {   \
  vec_float4 v;                         \
  vec_float4 p, q, plast, qlast;        \
  vec_float4 factor;                    \
  vec_float4 inv_xsqu;                  \
  inv_xsqu = _recipf4(_xsqu);            \
  v = spu_mul(inv_xsqu, onehalff);       \
  p = spu_splats(3.025f); q = onef; plast = p; qlast = q;                                        \
  p = spu_madd(qlast, spu_mul(v, spu_splats(40.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(39.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(38.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(37.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(36.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(35.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(34.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(33.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(32.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(31.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(30.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(29.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(28.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(27.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(26.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(25.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(24.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(23.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(22.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(21.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(20.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(19.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(18.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(17.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(16.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(15.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(14.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(13.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(12.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(11.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(10.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats( 9.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats( 8.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats( 7.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats( 6.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats( 5.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats( 4.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats( 3.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats( 2.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats( 1.0f)), plast); q = plast; plast = p; qlast = q;    \
  p = qlast; q = plast;                                                                         \
  factor = spu_mul(spu_splats((float)SQRT_PI), spu_mul(_xabs, _expf4(_xsqu)));                         \
  _presult = _divf4(p, spu_mul(factor, q));                                                     \
}

#define CONTFRAC_ERFC(_xabs, _xsqu, _presult) {   \
  vec_double2 v;                         \
  vec_double2 p, q, plast, qlast;        \
  vec_double2 factor;                    \
  vec_double2 inv_xsqu;                  \
  inv_xsqu = _recipd2(_xsqu);            \
  v = spu_mul(inv_xsqu, onehalfd);       \
  p = spu_splats(3.025); q = oned; plast = p; qlast = q;                                        \
  p = spu_madd(qlast, spu_mul(v, spu_splats(40.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(39.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(38.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(37.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(36.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(35.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(34.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(33.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(32.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(31.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(30.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(29.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(28.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(27.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(26.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(25.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(24.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(23.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(22.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(21.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(20.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(19.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(18.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(17.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(16.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(15.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(14.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(13.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(12.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(11.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats(10.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats( 9.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats( 8.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats( 7.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats( 6.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats( 5.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats( 4.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats( 3.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats( 2.0)), plast); q = plast; plast = p; qlast = q;    \
  p = spu_madd(qlast, spu_mul(v, spu_splats( 1.0)), plast); q = plast; plast = p; qlast = q;    \
  p = qlast; q = plast;                                                                         \
  factor = spu_mul(spu_splats(SQRT_PI), spu_mul(_xabs, _expd2(_xsqu)));                         \
  _presult = _divd2(p, spu_mul(factor, q));                                                     \
}

#endif /* _ERF_UTILS_H_ */
#endif /* __SPU__ */
