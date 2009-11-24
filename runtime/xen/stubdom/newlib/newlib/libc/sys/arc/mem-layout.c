/* Ideally this kind of stuff is specified in a linker script.  It's not clear
   what the default linker script should do, so for now we have this.  */

/* Keep this file separate from sbrk.c so the programmer can supply his/her
   own _sbrk_r.  This file could go in crt0.S, but I want to keep this in C.
   This is all just an experiment anyway.  */

#ifndef STACK_SIZE
/* Cache lines recycle at 4096 I think, and 4096 is listed as the page size,
   so we make the stack size a multiple of it.  Not that it's relevant or
   anything, but why not base it on *something*?  */
#define STACK_SIZE (4096 * 4)
#endif

int stack_size asm ("stack_size") = STACK_SIZE;

#ifndef SBRK_SIZE
#define SBRK_SIZE (4096 * 32)
#endif

int sbrk_size asm ("sbrk_size") = SBRK_SIZE;
