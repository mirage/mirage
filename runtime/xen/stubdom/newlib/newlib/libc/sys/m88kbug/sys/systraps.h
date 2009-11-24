/* trap numbers for mvme187bug */

#define INCHR	0x0000
#define OUTCHR	0x0020
#define RETURN	0x0063

#define SYSTRAP(x) {asm("or r9,r0,%0" : : "i" (x) : "r9"); asm("tb0 0,r0,496");}

/* end of systraps.h */
