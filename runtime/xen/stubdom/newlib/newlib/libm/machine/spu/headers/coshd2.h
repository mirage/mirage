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
#ifndef _COSHD2_H_
#define _COSHD2_H_	1

#include <spu_intrinsics.h>

#include "expd2.h"
#include "recipd2.h"

/*
 * FUNCTION
 *	vector float _coshd2(vector double angle)
 *
 * DESCRIPTION
 *	_coshd2 computes the hyperbolic cosines of a vector of angles 
 *      (expressed in radians) to an accuracy of a double precision 
 *      floating point.
 */
static __inline vector double _coshd2(vector double x)
{
 
  // Coefficents for the power series
  vec_double2 f02 = spu_splats(5.00000000000000000000E-1);   // 1/(2!)
  vec_double2 f04 = spu_splats(4.16666666666666666667E-2);   // 1/(4!)
  vec_double2 f06 = spu_splats(1.38888888888888888889E-3);   // 1/(6!)
  vec_double2 f08 = spu_splats(2.48015873015873015873E-5);   // 1/(8!)
  vec_double2 f10 = spu_splats(2.75573192239858906526E-7);   // 1/(10!)
  vec_double2 f12 = spu_splats(2.08767569878680989792E-9);   // 1/(12!)
  vec_double2 f14 = spu_splats(1.14707455977297247139E-11);  // 1/(14!)
  vec_double2 f16 = spu_splats(4.77947733238738529744E-14);  // 1/(16!)
  vec_double2 f18 = spu_splats(1.56192069685862264622E-16);  // 1/(18!)
  vec_double2 f20 = spu_splats(4.11031762331216485848E-19);  // 1/(20!)
  vec_double2 f22 = spu_splats(8.89679139245057328675E-22);  // 1/(22!)

  //  Check if the input is within the range [ -1.0 ... 1.0 ]
  //  If it is, we want to use the power series, otherwise
  //  we want to use the 0.5 * (e^x + e^-x)

  // round to float, check if within range.  Results will be in 
  // slots 0 and 2, so we rotate right 4 bytes, and "or" with ourself
  // to produce 64 bits of all 1's or 0's.
  vec_uint4 use_exp = spu_cmpabsgt(spu_roundtf(x),spu_splats(1.0f));
  use_exp = spu_or(use_exp,spu_rlmaskqwbyte(use_exp,-4));


  // Perform the calculation of the power series using Horner's method
  vec_double2 result;
  vec_double2 x2 = spu_mul(x,x);
  result = spu_madd(x2,f22,f20);
  result = spu_madd(x2,result,f18);
  result = spu_madd(x2,result,f16);
  result = spu_madd(x2,result,f14);
  result = spu_madd(x2,result,f12);
  result = spu_madd(x2,result,f10);
  result = spu_madd(x2,result,f08);
  result = spu_madd(x2,result,f06);
  result = spu_madd(x2,result,f04);
  result = spu_madd(x2,result,f02);
  result = spu_madd(x2,result,spu_splats(1.0));


  //  Perform calculation as a function of 0.5 * (e^x + e^-x)
  vec_double2 ex = _expd2(x);
  vec_double2 ex_inv = _recipd2(ex);

  vec_double2 r2= spu_add(ex,ex_inv);
  r2 = spu_mul(r2,f02);  // we can reuse f02 here


  //  Select either the power series or exp version
  result = spu_sel(result,r2,(vec_ullong2)use_exp);

  return result;

}

#endif /* _COSHD2_H_ */
#endif /* __SPU__ */
