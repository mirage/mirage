; h8/300 and h8/300h start up file.

#include "setarch.h"

#ifdef __H8300__

	.section .text
	.global	_start
_start:
	mov.w	#_stack,sp
	mov.w	#_edata,r0
	mov.w	#_end,r1
	sub.w   r2,r2
.Loop:	mov.w	r2,@r0
	adds	#2,r0
	cmp	r1,r0
	blo	.Loop
#ifdef __ELF__
	mov.l   #__fini,r0
	jsr     @_atexit
#ifdef __SIMULATOR__
        jsr     @0xcc
#endif
	jsr     @__init
#else
#ifdef __SIMULATOR__
        jsr     @0xcc
#endif
	jsr	@___main
#endif
	jsr	@_main
	jsr	@_exit

	.section .stack
_stack:	.word 	1

#endif

#ifdef __H8300H__

	.section .text
	.global	_start
_start:
	mov.l	#_stack,sp
	mov.l	#_edata,er0
	mov.l	#_end,er1
	sub.w   r2,r2           ; not sure about alignment requirements
.Loop:	mov.w	r2,@er0		; playing it safe for now
	adds	#2,er0
	cmp.l	er1,er0
	blo	.Loop
#ifdef __ELF__
	mov.l   #__fini,er0
	jsr     @_atexit
#ifdef __SIMULATOR__
        jsr     @0xcc
#endif
	jsr     @__init
#else
#ifdef __SIMULATOR__
        jsr     @0xcc
#endif
	jsr	@___main
#endif
	jsr	@_main
	jsr	@_exit

	.section .stack
_stack:	.long 	1

#endif

#if defined (__H8300S__) || defined (__H8300SX__)

	.section .text
	.global	_start
_start:
	mov.l	#_stack,sp
	mov.l	#_edata,er0
	mov.l	#_end,er1
	sub.w   r2,r2           ; not sure about alignment requirements
.Loop:	mov.w	r2,@er0		; playing it safe for now
	adds	#2,er0
	cmp.l	er1,er0
	blo	.Loop
#ifdef __ELF__
	mov.l   #__fini,er0
	jsr     @_atexit
#ifdef __SIMULATOR__
        jsr     @0xcc
#endif
	jsr     @__init
#else
#ifdef __SIMULATOR__
        jsr     @0xcc
#endif
	jsr	@___main
#endif
	jsr	@_main
	jsr	@_exit

	.section .stack
_stack:	.long 	1

#endif
