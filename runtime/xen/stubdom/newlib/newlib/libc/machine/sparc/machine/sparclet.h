/* Various stuff for the sparclet processor.

   This file is in the public domain.  */

#ifndef _MACHINE_SPARCLET_H_
#define _MACHINE_SPARCLET_H_

#ifdef __sparclet__

/* sparclet scan instruction */

extern __inline__ int
scan (int a, int b)
{
  int res;
  __asm__ ("scan %1,%2,%0" : "=r" (res) : "r" (a), "r" (b));
  return res;
}

/* sparclet shuffle instruction */

extern __inline__ int
shuffle (int a, int b)
{
  int res;
  __asm__ ("shuffle %1,%2,%0" : "=r" (res) : "r" (a), "r" (b));
  return res;
}

#endif /* __sparclet__ */

#endif /* _MACHINE_SPARCLET_H_ */
