/* Infinity as a constant value.   This is used for HUGE_VAL.
 * Added by Cygnus Support.
 */

#include <float.h>
#include "fdlibm.h"

/* Float version of infinity.  */
const union __fmath __infinityf[1] = {{{0x7f800000}}};

/* Double version of infinity.  */
#ifndef _DOUBLE_IS_32BITS
 #ifdef __IEEE_BIG_ENDIAN
  const union __dmath __infinity[1] = {{{0x7ff00000, 0}}};
 #else
  const union __dmath __infinity[1] = {{{0, 0x7ff00000}}};
 #endif
#else /* defined (_DOUBLE_IS_32BITS) */
 const union __dmath __infinity[1] = {{{0x7f800000, 0}}};
#endif /* defined (_DOUBLE_IS_32BITS) */

/* Long double version of infinity.  */
#ifdef __IEEE_BIG_ENDIAN
 #if LDBL_MANT_DIG == 24
  const union __ldmath __infinityld[1] = {{{0x7f800000, 0, 0, 0}}};
 #elif LDBL_MANT_DIG == 53
  const union __ldmath __infinityld[1] = {{{0x7ff00000, 0, 0, 0}}};
 #else
  const union __ldmath __infinityld[1] = {{{0x7fff0000, 0, 0, 0}}};
 #endif /* LDBL_MANT_DIG size  */
#else /* __IEEE_LITTLE_ENDIAN  */
 #if LDBL_MANT_DIG == 24
  const union __ldmath __infinityld[1] = {{{0x7f800000, 0, 0, 0}}};
 #elif LDBL_MANT_DIG == 53
  const union __ldmath __infinityld[1] = {{{0, 0x7ff00000, 0, 0}}};
 #else
  const union __ldmath __infinityld[1] = {{{0, 0x80000000, 0x00007fff, 0}}};
 #endif /* LDBL_MANT_DIG size  */
#endif /* __IEEE_LITTLE_ENDIAN  */

