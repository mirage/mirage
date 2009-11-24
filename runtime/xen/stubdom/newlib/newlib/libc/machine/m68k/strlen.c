/*
 *  C library strlen routine
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
 * Test bytes using CPU32+ loop mode if possible.
 */
size_t
strlen (const char *str)
{
	unsigned int n = ~0;
	const char *cp = str;

	asm volatile ("1:\n"
	     "\ttst.b (%0)+\n"
#if defined(__mcpu32__)
	     "\tdbeq %1,1b\n"
#endif
	     "\tbne.b 1b\n" :
		"=a" (cp), "=d" (n) :
		 "0" (cp),  "1" (n) :
		 "cc");
	return (cp - str) - 1;
}
