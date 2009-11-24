; ARC start up file
; In the absence of a custom linker script, go with something simple.
; We do not support passing arguments to "main", but this is an embedded
; system anyway.
;
; We call init/fini here without cpu prefixes because there is always
; only one .init/.fini section per image.

	.section .text
	.align 4

	.global	start
start:

	mov	sp,end		; Round "sp" up to page after "end".
	add	sp,sp,4095
	and	sp,sp,-4096

	ld	r8,[stack_size]	; Add stack size to "sp".
	add	sp,sp,r8

	st	sp,[sbrk_start]	; Initialize malloc heap.
	st	sp,[sbrk_loc]

	sub	sp,sp,16	; callee expects 16 bytes already "pushed".
	mov	fp,0		; Top of stack frame indicator.

	mov	r0,edata	; Zero bss.
	mov	r2,end
	sub	r2,r2,r0
	mov	r1,0

#ifdef __base__
	bl.nd	_memset
	bl.nd	init		; .init section entry point.
	mov	r0,%st(fini)	; .fini section entry point.
	bl.nd	_atexit
	mov	r0,0		; argc
	mov	r1,0		; argv
	bl.nd	_main
	bl.nd	_exit
#endif

#ifdef __host__
	bl.nd	_host_memset
	bl.nd	init		; .init section entry point.
	mov	r0,%st(fini)	; .fini section entry point.
	bl.nd	_host_atexit
	mov	r0,0		; argc
	mov	r1,0		; argv
	bl.nd	_host_main
	bl.nd	_host_exit
#endif

#ifdef __graphics__
	bl.nd	_graphics_memset
	bl.nd	init		; .init section entry point.
	mov	r0,%st(fini)	; .fini section entry point.
	bl.nd	_graphics_atexit
	mov	r0,0		; argc
	mov	r1,0		; argv
	bl.nd	_graphics_main
	bl.nd	_graphics_exit
#endif

#ifdef __audio__
	bl.nd	_audio_memset
	bl.nd	init		; .init section entry point.
	mov	r0,%st(fini)	; .fini section entry point.
	bl.nd	_audio_atexit
	mov	r0,0		; argc
	mov	r1,0		; argv
	bl.nd	_audio_main
	bl.nd	_audio_exit
#endif
