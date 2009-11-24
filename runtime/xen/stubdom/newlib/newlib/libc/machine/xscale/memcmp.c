#if defined __thumb__

#include "../../string/memcmp.c"

#else

#include <string.h>
#include "xscale.h"

int
memcmp (const void * s1, const void * s2, size_t len)
{
  int result;
  asm (
#ifndef __OPTIMIZE_SIZE__ 
"\n\
	cmp	%2, #0x3	@ Is the length a multiple of four ?\n\
	bls	6f		@ no  = goto SLOW CHECK\n\
	and	r2, %0, #0x3	@ get alignment of first pointer\n\
	and	r3, %1, #0x3	@ get alignment of second pointer\n\
	cmp	r2, r3		@ Do the two pointers share the same alignment ?\n\
	bne	6f		@ no = goto SLOW CHECK\n\
	mov	lr, %0		@ copy first pointer into LR\n\
	mov	r4, %1		@ copy second pointer into R4\n\
	cmp	r2, #0x0	@ Are we comparing word aligned pointers ?\n\
	beq	3f		@ yes = goto START WORD CHECK LOOP\n\
	b	1f		@ jump to LOOP TEST\n\
0:			       @ LOOP START\n\
	ldrb	r2, [lr], #1	@ load byte from LR, post inc.\n\
"	PRELOADSTR("lr") "	@ preload\n\
	ldrb	r3, [r4], #1	@ load byte from R4, post inc.\n\
"	PRELOADSTR("r4") "	@ preload\n\
	cmp	r2, r3		@ are the two bytes the same ?\n\
	bne	5f		@ no = goto EXIT\n\
	tst	lr, #0x3	@ has the LR become word aligned ?\n\
	bne     1f		@ no = skip the next test\n\
	cmp     %2, #4		@ is the count >= 4 ?\n\
	bhs     3f		@ yes = goto START WORD CHECK LOOP\n\
1:			       @ LOOP TEST\n\
	sub	%2, %2, #1	@ decrement count by one\n\
	cmn	%2, #0x1	@ has the count reached -1 ?\n\
	bne	0b		@ no = loop back to LOOP START\n\
	b	4f		@ goto PASS END\n\
\n\
0:			       @ ??\n\
	cmp	%2, #0x7	@ Is the count a multiple of 8 ?\n\
	bls	3f		@ no = goto ???\n\
	ldmia	lr,{r2, r3}	@ get two words from first pointer, post inc\n\
	ldmia	r4,{r5, r6}	@ get two words from second pointer, post inc\n\
	sub	%2, %2, #0x4	@ decrement count by 4\n\
	cmp	r2, r5		@ has the count reached ????\n\
	bne	1f		@ no = goto\n\
	sub	%2, %2, #0x4	@ decrement the count by 4\n\
	add	lr, lr, #0x4	@ add 4 to first pointer\n\
	add	r4, r4, #0x4	@ add 4 to second pointer\n\
	cmp	r3, r6		@ ???\n\
	beq	0b		@ goto ???\n\
1:			       @ ??\n\
	add	%2, %2, #0x4	@ Add four to count\n\
	sub	%0, lr, #0x4	@ decrement first pointer by 4\n\
	sub	%1, r4, #0x4	@ decrement second pointer by 4\n\
	b	6f		@ goto SLOW CHECK\n\
\n\
3:			       @ START WORD CHECK LOOP\n\
	cmp	%2, #0x3	@ is the count <= 3 ?\n\
	bls	1f		@ yes = goto CHECK BYTES BY HAND\n\
	ldr	r2, [lr], #4	@ get word from LR, post inc\n\
	ldr	r3, [r4], #4	@ get word from R4, post inc\n\
	sub	%2, %2, #4	@ decrement count by 4\n\
	cmp	r2, r3		@ are the two words the same ?\n\
	bne	1f		@ no = goto CHECK WORD CONTENTS\n\
0:			       @ WORD CHECK LOOP\n\
	cmp	%2, #0x3	@ is the count <= 3 ?\n\
	bls	1f		@ yes = goto CHECK BYTES BY HAND\n\
	ldr	r2, [lr], #4	@ load word from LR, post inc\n\
"	PRELOADSTR("lr") "	@ preload\n\
	ldr	r3, [r4], #4	@ load word from R4, post inc\n\
"	PRELOADSTR("r4") "	@ preload\n\
	sub	%2, %2, #4	@ decrement count by 4\n\
	cmp	r2, r3		@ are the two words the same ?\n\
	beq	0b		@ yes = goto WORD CHECK LOOP\n\
1:			       @ CHECK BYTES BY HAND\n\
	sub	%0, lr, #0x4	@ move LR back a word and put into first pointer\n\
	sub	%1, r4, #0x4	@ move R4 back a word and put into second pointer\n\
	add	%2, %2, #4	@ increment the count by 4\n\
				@ fall through into SLOW CHECK"
#endif /* !__OPTIMIZE_SIZE__ */
"\n\
6:			       @ SLOW CHECK\n\
	sub	%2, %2, #1	@ Decrement the count by one\n\
	cmn	%2, #0x1	@ Has the count reached -1 ?\n\
	beq	4f		@ Yes - we are finished, goto PASS END\n\
0:			       @ LOOP1\n\
	ldrb	r2, [%0], #1	@ get byte from first pointer\n\
"	PRELOADSTR("%0") "	@ preload first pointer\n\
	ldrb	r3, [%1], #1	@ get byte from second pointer\n\
"	PRELOADSTR("%1") "	@ preload second pointer\n\
	cmp	r2, r3		@ compare the two loaded bytes\n\
	bne	5f		@ if they are not equal goto EXIT\n\
	sub	%2, %2, #1	@ decremented count by 1\n\
	cmn	%2, #0x1	@ has the count reached -1 ?\n\
	bne	0b		@ no = then go back to LOOP1\n\
4:			       @ PASS END\n\
	mov	r3, r2		@ Default return value is 0\n\
5:			       @ EXIT\n\
	rsb	%0, r3, r2	@ return difference between last two bytes loaded"
       : "=r" (result), "=&r" (s2), "=&r" (len)
       : "0" (s1), "1" (s2), "2" (len)
       : "r2", "r3", "r4", "r5", "r6", "cc", "lr");
  return result;
}
#endif
