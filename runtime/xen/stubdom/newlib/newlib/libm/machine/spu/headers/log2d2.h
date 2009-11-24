/* --------------------------------------------------------------  */
/* (C)Copyright 2006,2007,                                         */
/* International Business Machines Corporation,                    */
/* Sony Computer Entertainment, Incorporated,                      */
/* Toshiba Corporation,                                            */
/*                                                                 */
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
#ifndef _LOG2D2_H_
#define _LOG2D2_H_	1

#include <spu_intrinsics.h>

/*
 * FUNCTION
 *	vector double _log2d2(vector double x)
 *
 * DESCRIPTION
 *	The function _log2d2 computes log base 2 of the input x for each
 *	of the double word elements of x. The log2 is decomposed
 *      into two parts, log2 of the exponent and log2 of the 
 *	fraction. The log2 of the fraction is approximated 
 *	using a 21st order polynomial of the form:
 *
 *                        __20_
 *                        \
 *	log(x) = x * (1 +  \   (Ci * x^i))
 *                         /
 *                        /____
 *                         i=0
 *
 *      for x in the range 0-1.
 */
#define LOG_C00    
#define LOG_C01   
#define LOG_C02    

static __inline vector double _log2d2(vector double vx) 
{
  vec_int4 addval;
  vec_ullong2 exp_mask = spu_splats(0x7FF0000000000000ULL);
  vec_double2 vy, vxw;
  vec_double2 v1 = spu_splats(1.0);
  vec_double2 x2, x4, x8, x10, p1, p2;

  /* Extract the fraction component of input by forcing
   * its exponent so that input is in the range [1.0, 2.0)
   * and then subtract 1.0 to force it in the range 
   * [0.0, 1.0).
   */
  vxw = spu_sub(spu_sel(vx, v1, exp_mask), v1);

  /* Compute the log2 of the exponent as exp - 1023.
   */
  addval = spu_add(spu_rlmask((vec_int4)vx, -20), -1023);

  /* Compute the log2 of the fractional component using a 21st 
   * order polynomial. The polynomial is evaluated in two halves 
   * to improve efficiency.
   */
  p1 = spu_madd(spu_splats(3.61276447184348752E-05), vxw, spu_splats(-4.16662127033480827E-04));
  p2 = spu_madd(spu_splats(-1.43988260692073185E-01), vxw, spu_splats(1.60245637034704267E-01));
  p1 = spu_madd(vxw, p1, spu_splats(2.28193656337578229E-03));
  p2 = spu_madd(vxw, p2, spu_splats(-1.80329036970820794E-01));
  p1 = spu_madd(vxw, p1, spu_splats(-7.93793829370930689E-03));
  p2 = spu_madd(vxw, p2, spu_splats(2.06098446037376922E-01));
  p1 = spu_madd(vxw, p1, spu_splats(1.98461565426430164E-02));
  p2 = spu_madd(vxw, p2, spu_splats(-2.40449108727688962E-01));
  p1 = spu_madd(vxw, p1, spu_splats(-3.84093543662501949E-02));
  p2 = spu_madd(vxw, p2, spu_splats(2.88539004851839364E-01));
  p1 = spu_madd(vxw, p1, spu_splats(6.08335872067172597E-02));
  p2 = spu_madd(vxw, p2, spu_splats(-3.60673760117245982E-01));
  p1 = spu_madd(vxw, p1, spu_splats(-8.27937055456904317E-02));
  p2 = spu_madd(vxw, p2, spu_splats(4.80898346961226595E-01));
  p1 = spu_madd(vxw, p1, spu_splats(1.01392360727236079E-01));
  p2 = spu_madd(vxw, p2, spu_splats(-7.21347520444469934E-01));
  p1 = spu_madd(vxw, p1, spu_splats(-1.16530490533844182E-01));
  p2 = spu_madd(vxw, p2, spu_splats(0.44269504088896339E+00));
  p1 = spu_madd(vxw, p1, spu_splats(1.30009193360025350E-01));

  x2 = spu_mul(vxw, vxw);
  x4 = spu_mul(x2, x2);
  x8 = spu_mul(x4, x4);
  x10 = spu_mul(x8, x2);

  vy = spu_madd(spu_madd(x10, p1, p2), vxw, vxw);

  /* Add the log2(exponent) and the log2(fraction) to 
   * compute the final result.
   */
  vy = spu_add(vy, spu_extend(spu_convtf(addval, 0))); 

  vxw = spu_extend(spu_convtf(addval, 20));

  return(vy);
}

#endif /* _LOG2D2_H_ */
#endif /* __SPU__ */
