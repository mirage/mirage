#ifndef __F_MATH_H__
#define __F_MATH_H__

#include <_ansi.h>
#include "fdlibm.h"

__inline__
static 
int 
_DEFUN (check_finite, (x),
         double x)
{  
  __int32_t hx;
  GET_HIGH_WORD(hx,x);
  return  (int)((__uint32_t)((hx&0x7fffffff)-0x7ff00000)>>31);
}

__inline__
static 
int 
_DEFUN (check_finitef, (x),
         float x)
{  
  __int32_t ix;
  GET_FLOAT_WORD(ix,x);
  return  (int)((__uint32_t)((ix&0x7fffffff)-0x7f800000)>>31);
}

#endif /* __F_MATH_H__ */
