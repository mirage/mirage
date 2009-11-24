/* Cover function to sparclet `shuffle' instruction.

   This file is in the public domain.  */

#ifdef __sparclet__

int
shuffle (int a, int b)
{
  int res;
  __asm__ ("shuffle %1,%2,%0" : "=r" (res) : "r" (a), "r" (b));
  return res;
}

#endif
