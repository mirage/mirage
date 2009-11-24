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
#ifndef _SINHD2_H_
#define _SINHD2_H_	1

#include <spu_intrinsics.h>

#include "expd2.h"
#include "recipd2.h"

/*
 * FUNCTION
 *	vector double _sinhd2(vector double angle)
 *
 * DESCRIPTION
 *	The _sinhd2 function computes the hyperbolic sine of a vector of
 *      angles (expressed in radians) to an accuracy of a double precision 
 *      floating point.
 */
static __inline vector double _sinhd2(vector double x)
{
  // Coefficents for the power series
  vec_double2 f03 = spu_splats(1.66666666666666666667E-01);  // 1/(3!)
  vec_double2 f05 = spu_splats(8.33333333333333333333E-03);  // 1/(5!)
  vec_double2 f07 = spu_splats(1.98412698412698412698E-04);  // 1/(7!)
  vec_double2 f09 = spu_splats(2.75573192239858906526E-06);  // 1/(9!)
  vec_double2 f11 = spu_splats(2.50521083854417187751E-08);  // 1/(11!)
  vec_double2 f13 = spu_splats(1.60590438368216145994E-10);  // 1/(13!)
  vec_double2 f15 = spu_splats(7.64716373181981647590E-13);  // 1/(15!)
  vec_double2 f17 = spu_splats(2.81145725434552076320E-15);  // 1/(17!)
  vec_double2 f19 = spu_splats(8.22063524662432971696E-18);  // 1/(19!)
  vec_double2 f21 = spu_splats(1.95729410633912612308E-20);  // 1/(21!)
  vec_double2 f23 = spu_splats(3.86817017063068403772E-23);  // 1/(23!)



  //  Check if the input is within the range [ -1.0 ... 1.0 ]
  //  If it is, we want to use the power series, otherwise
  //  we want to use the 0.5 * (e^x - e^-x)

  // round to float, check if within range.  Results will be in 
  // slots 0 and 2, so we rotate right 4 bytes, and "or" with ourself
  // to produce 64 bits of all 1's or 0's.
  vec_uint4 use_exp = spu_cmpabsgt(spu_roundtf(x),spu_splats(1.0f));
  use_exp = spu_or(use_exp,spu_rlmaskqwbyte(use_exp,-4));




  // Perform the calculation of the power series using Horner's method
  vec_double2 result;
  vec_double2 x2 = spu_mul(x,x);
  result = spu_madd(x2,f23,f21);
  result = spu_madd(x2,result,f19);
  result = spu_madd(x2,result,f17);
  result = spu_madd(x2,result,f15);
  result = spu_madd(x2,result,f13);
  result = spu_madd(x2,result,f11);
  result = spu_madd(x2,result,f09);
  result = spu_madd(x2,result,f07);
  result = spu_madd(x2,result,f05);
  result = spu_madd(x2,result,f03);
  result = spu_madd(x2,result,spu_splats(1.0));
  result = spu_mul(x,result);


  //  Perform calculation as a function of 0.5 * (e^x - e^-x)
  vec_double2 ex = _expd2(x);
  vec_double2 ex_inv = _recipd2(ex);

  vec_double2 r2= spu_sub(ex,ex_inv);
  r2 = spu_mul(r2,spu_splats(0.5)); 


  //  Select either the power series or exp version
  result = spu_sel(result,r2,(vec_ullong2)use_exp);



  return result;

}

#endif /* _SINHD2_H_ */
#endif /* __SPU__ */
