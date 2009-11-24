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
#ifndef __SIMD_MATH_H__
#define __SIMD_MATH_H__ 1

#ifdef __cplusplus
extern "C" {
#endif

#if !defined(__SPU__) && !defined(__ALTIVEC__)
#error Bad platform
#else

#define SM_E		2.7182818284590452354	/* e */
#define SM_LOG2E        1.4426950408889634074	/* log_2 e */
#define SM_LOG10E	0.43429448190325182765	/* log_10 e */
#define SM_LN2		0.69314718055994530942	/* log_e 2 */
#define SM_LN10		2.30258509299404568402	/* log_e 10 */
#define SM_PI		3.14159265358979323846	/* pi */
#define SM_PI_2		1.57079632679489661923	/* pi/2 */
#define SM_PI_4		0.78539816339744830962	/* pi/4 */
#define SM_1_PI		0.31830988618379067154	/* 1/pi */
#define SM_2_PI		0.63661977236758134308	/* 2/pi */
#define SM_2_SQRTPI	1.12837916709551257390	/* 2/sqrt(pi) */
#define SM_SQRT2        1.41421356237309504880	/* sqrt(2) */
#define SM_SQRT1_2       0.70710678118654752440	/* 1/sqrt(2) */

/* Typedefs common to both SPU and PPU */
typedef struct divi4_s {
  vector signed int quot;
  vector signed int rem;
} divi4_t;

typedef struct divu4_s {
  vector unsigned int quot;
  vector unsigned int rem;
} divu4_t;


/*  Functions common to both SPU and PPU  */
vector signed int absi4(vector signed int x);
vector float acosf4(vector float x);
vector float acoshf4(vector float x);
vector float asinf4(vector float x);
vector float asinhf4(vector float x);
vector float atanf4(vector float x);
vector float atanhf4(vector float x);
vector float atan2f4(vector float y, vector float x);
vector float cbrtf4(vector float x);     
vector float ceilf4(vector float x);
vector float copysignf4(vector float x, vector float y);
vector float cosf4(vector float x);
vector float coshf4(vector float x);
vector float divf4(vector float x, vector float y);
vector float divf4_fast(vector float x, vector float y);
divi4_t divi4(vector signed int dividend, vector signed int divisor);
divu4_t divu4(vector unsigned int dividend, vector unsigned int divisor);
vector float erff4(vector float x);
vector float erfcf4(vector float x);
vector float exp2f4(vector float x);
vector float expf4(vector float x);
vector float expm1f4(vector float x);
vector float fabsf4(vector float value);
vector float fdimf4(vector float x, vector float y);
vector float floorf4(vector float value);
vector float fmaf4(vector float x, vector float y, vector float z);
vector float fmaxf4(vector float x, vector float y);
vector float fminf4(vector float x, vector float y);
vector float fmodf4(vector float x, vector float y);
vector signed int fpclassifyf4(vector float x);
vector float frexpf4(vector float x, vector signed int *pexp);
vector float hypotf4(vector float x, vector float y);
vector signed int ilogbf4(vector float x);
vector signed int irintf4(vector float x);
vector signed int iroundf4(vector float x);
vector unsigned int is0denormf4(vector float x);
vector unsigned int isequalf4(vector float x, vector float y);
vector unsigned int isfinitef4(vector float x);
vector unsigned int isgreaterf4(vector float x, vector float y);
vector unsigned int isgreaterequalf4(vector float x, vector float y);
vector unsigned int isinff4(vector float x);
vector unsigned int islessf4(vector float x, vector float y);
vector unsigned int islessequalf4(vector float x, vector float y);
vector unsigned int islessgreaterf4(vector float x, vector float y);
vector unsigned int isnanf4(vector float x);
vector unsigned int isnormalf4(vector float x);
vector unsigned int isunorderedf4(vector float x, vector float y);
vector float ldexpf4(vector float x, vector signed int exp);
vector float lgammaf4(vector float x);
vector float log10f4(vector float x);
vector float log1pf4(vector float x);
vector float log2f4(vector float x);
vector float logbf4(vector float x);
vector float logf4(vector float x);
vector float modff4(vector float x, vector float *pint);
vector float nearbyintf4(vector float x);
vector float negatef4(vector float x);
vector signed int negatei4(vector signed int x);
vector float nextafterf4(vector float x, vector float y);
vector float powf4(vector float x, vector float y);
vector float recipf4(vector float a);
vector float remainderf4(vector float x, vector float y);
vector float remquof4(vector float x, vector float y, vector signed int *quo);
vector float rintf4(vector float x);
vector float roundf4(vector float x);
vector float rsqrtf4(vector float value);
vector float scalbnf4(vector float x, vector signed int exp);
vector unsigned int signbitf4(vector float x);
void sincosf4(vector float x, vector float *sx, vector float *cx);
vector float sinf4(vector float x);
vector float sinhf4(vector float x);
vector float sqrtf4(vector float in);
vector float tanf4(vector float angle);
vector float tanhf4(vector float x);
vector float tgammaf4(vector float x);
vector float truncf4(vector float x);


#ifdef __SPU__
/* Typedefs specific to SPU */
typedef struct llroundf4_s {
  vector signed long long vll[2];
} llroundf4_t;

typedef struct lldivi2_s {
  vector signed long long quot;
  vector signed long long rem;
} lldivi2_t;

typedef struct lldivu2_s {
  vector unsigned long long quot;
  vector unsigned long long rem;
} lldivu2_t;


/*  Functions specific to SPU  */
llroundf4_t llrintf4(vector float in);
llroundf4_t llroundf4 (vector float x);
vector double acosd2(vector double x);
vector double acoshd2(vector double x);
vector double asind2(vector double x);
vector double asinhd2(vector double x);
vector double atan2d2(vector double y, vector double x);
vector double atand2(vector double x);
vector double atanhd2(vector double x);
vector double cbrtd2(vector double x);
vector double ceild2(vector double x);
vector float  ceilf4_fast(vector float x);
vector double copysignd2(vector double x, vector double y);
vector double cosd2(vector double x);
vector double coshd2(vector double x);
vector double divd2(vector double a, vector double b);
vector double erfcd2(vector double x);
vector double erfd2(vector double x);
vector double exp2d2(vector double x);
vector double expd2(vector double x);
vector double expm1d2(vector double x);
vector double fabsd2(vector double x);
vector double fdimd2(vector double x, vector double y);
vector double floord2(vector double x);
vector float  floorf4_fast(vector float value);
vector double fmad2(vector double x, vector double y, vector double z);
vector double fmaxd2(vector double x, vector double y);
vector double fmind2(vector double x, vector double y);
vector double fmodd2(vector double x, vector double y);
vector float  fmodf4_fast(vector float x, vector float y);
vector signed long long fpclassifyd2(vector double x);
vector double frexpd2(vector double x, vector signed int *pexp);
vector double hypotd2(vector double x, vector double y);
vector signed int ilogbd2(vector double x);
vector unsigned long long is0denormd2(vector double x);
vector unsigned long long isequald2(vector double x, vector double y);
vector unsigned long long isfinited2(vector double x);
vector unsigned long long isgreaterd2(vector double x, vector double y);
vector unsigned long long isgreaterequald2(vector double x, vector double y);
vector unsigned long long isinfd2(vector double x);
vector unsigned long long islessd2(vector double x, vector double y);
vector unsigned long long islessequald2(vector double x, vector double y);
vector unsigned long long islessgreaterd2(vector double x, vector double y);
vector unsigned long long isnand2(vector double x);
vector unsigned long long isnormald2(vector double x);
vector unsigned long long isunorderedd2(vector double x, vector double y);
vector double ldexpd2(vector double x, vector signed int exp);
vector signed long long llabsi2(vector signed long long x);
lldivi2_t lldivi2(vector signed long long x, vector signed long long y);
lldivu2_t lldivu2(vector unsigned long long x, vector unsigned long long y);
vector double lgammad2(vector double x);
vector signed long long llrintd2(vector double in);
vector signed long long llroundd2(vector double x);
vector double log10d2(vector double x);
vector double log1pd2(vector double x);
vector double log2d2(vector double x);
vector double logd2(vector double x);
vector double modfd2(vector double x, vector double* pint);
vector double nearbyintd2(vector double x);
vector double negated2(vector double x);
vector double nextafterd2(vector double x, vector double y);
vector signed long long negatell2(vector signed long long x);
vector double powd2(vector double x, vector double y);
vector double recipd2(vector double value_d);
vector float  recipf4_fast(vector float a);
vector double remainderd2(vector double x, vector double y);
vector double remquod2(vector double x, vector double y, vector signed int *quo);
vector double rintd2(vector double x);
vector double roundd2(vector double x);
vector double rsqrtd2(vector double x);
vector double scalbllnd2(vector double x, vector signed long long n);
vector unsigned long long signbitd2(vector double x);
void sincosd2(vector double x, vector double *sx, vector double *cx);
vector double sind2(vector double x);
vector double sinhd2(vector double x);
vector double sqrtd2(vector double x);
vector float  sqrtf4_fast(vector float in);
vector double tand2(vector double x);
vector double tanhd2(vector double x);
vector double tgammad2(vector double x);
vector double truncd2(vector double x);

#endif /* __SPU__ */

/*  Functions specific to PPU */
#ifdef __ALTIVEC__
#endif

#endif /* __SPU__ || __ALTIVEC__ */

#ifdef __cplusplus
}
#endif

#endif /* __SIMD_MATH_H__  */
