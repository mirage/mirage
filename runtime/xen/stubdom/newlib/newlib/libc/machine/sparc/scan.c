/* Cover function to sparclet `scan' instruction.

   This file is in the public domain.  */

#ifdef __sparclet__

int
scan (int a, int b)
{
  int res;
  __asm__ ("scan %1,%2,%0" : "=r" (res) : "r" (a), "r" (b));
  return res;
}

#endif
