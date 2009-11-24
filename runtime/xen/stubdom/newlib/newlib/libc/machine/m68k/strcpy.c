/*
 *  C library strcpy routine
 *
 *  This routine has been optimized for the CPU32+.
 *  It should run on all 68k machines.
 *
 *  W. Eric Norum
 *  Saskatchewan Accelerator Laboratory
 *  University of Saskatchewan
 *  Saskatoon, Saskatchewan, CANADA
 *  eric@skatter.usask.ca
 */

#include <string.h>

/*
 * Copy bytes using CPU32+ loop mode if possible
 */

char *
strcpy (char *to, const char *from)
{
	char *pto = to;
	unsigned int n = 0xFFFF;

	asm volatile ("1:\n"
	     "\tmove.b (%0)+,(%1)+\n"
#if defined(__mcpu32__)
	     "\tdbeq %2,1b\n"
#endif
	     "\tbne.b 1b\n" :
		"=a" (from), "=a" (pto), "=d" (n) :
		 "0" (from),  "1" (pto), "2" (n) :
		 "cc", "memory");
	return to;
}
