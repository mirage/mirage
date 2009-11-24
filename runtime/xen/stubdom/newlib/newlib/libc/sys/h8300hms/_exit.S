#include "setarch.h"

/* `sleep' is passed an argument in r0 that indicates the reason
   the program is exiting.  The format of r0 is defined in 
   devo/include/wait.h. */ 

/* extern void _exit (int rc); */

	.section .text
	.align 2
	.global __exit
__exit:
	mov.w   #0xdead,r1
	mov.w   #0xbeef,r2
	mov.b   r0l,r0h
	sub.b   r0l,r0l
	sleep
