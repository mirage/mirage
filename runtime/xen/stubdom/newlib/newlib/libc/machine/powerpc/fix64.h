#ifndef _FIX64_H_

#define _FIX64_H_

#include <ieeefp.h>
#include <math.h>
#include <float.h>
#include <errno.h>
#include <sys/config.h>

#ifdef __IEEE_LITTLE_ENDIAN
#define IEEE_8087
#endif

#ifdef __IEEE_BIG_ENDIAN
#define IEEE_MC68k
#endif

#ifdef __Z8000__
#define Just_16
#endif

#if defined(IEEE_8087) + defined(IEEE_MC68k) + defined(VAX) + defined(IBM) != 1
Exactly one of IEEE_8087, IEEE_MC68k, VAX, or IBM should be defined.
#endif

union long_double_union
{
  long double ld;
  __uint32_t i[4];
};

typedef union long_double_union LONG_DOUBLE_UNION;

extern void _simdstrtold (char *, char **, LONG_DOUBLE_UNION *);
extern int  _simdldcheck (LONG_DOUBLE_UNION *);

#define SIMD_LDBL_MANT_DIG 113

#ifdef IEEE_8087
# define word0(x) (x.i[3])
# define word1(x) (x.i[2])
# define word2(x) (x.i[1])
# define word3(x) (x.i[0])
#else /* !IEEE_8087 */
# define word0(x) (x.i[0])
# define word1(x) (x.i[1])
# define word2(x) (x.i[2])
# define word3(x) (x.i[3])
#endif /* !IEEE_8087 */

#undef  Exp_shift
#define Exp_shift   16
#undef  Exp_mask
#define Exp_mask    ((__uint32_t)0x7fff0000L)
#undef  Exp_msk1
#define Exp_msk1    ((__uint32_t)0x00010000L)
#undef  Bias
#define Bias 	     16383
#undef  Ebits
#define Ebits 	     15
#undef  Sign_bit
#define Sign_bit    ((__uint32_t)0x80000000L)
#define init(x) {} 

union fix64_union
{
  __uint64_t ll;
  __uint32_t j[2];
};

#ifdef __LITTLE_ENDIAN__
# define hiword(y) (y.j[1])
# define loword(y) (y.j[0])
#else /* __BIG_ENDIAN__ */
# define hiword(y) (y.j[0])
# define loword(y) (y.j[1])
#endif /* __BIG_ENDIAN__ */

#endif /* _FIX64_H_ */
