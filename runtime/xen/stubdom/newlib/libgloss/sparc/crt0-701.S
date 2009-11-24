/* crt0.S for the sparclet 701.

   At the moment, all the necessary syscalls are here.
   Convention has them in a separate file but libgloss is still in
   too much flux.  */

	.text

	.global start
start:

! zero bss

	sethi %hi(_end), %o1
	or %o1, %lo(_end), %o1
	sethi %hi(_edata), %o0
	or %o0, %lo (_edata), %o0
	sub %o1, %o0, %o1
Lzero_bss:
	subcc %o1, 4, %o1
	clr [%o0]
	bne Lzero_bss
	add %o0, 4, %o0

! set up argc, argv, envp (?)

	ld [%sp+64], %o0
	sll %o0, 2, %o2
	add %o2, 4, %o2
	add %sp, 68, %o1
	add %o1, %o2, %o2
	sethi %hi(_environ), %o3
	st %o2, [%o3+%lo(_environ)]

! call main, exit

	call _main
	sub %sp, 32, %sp
	call _exit
	nop

! void _exit (int rc)

	.global __exit
__exit:
	mov 1, %g1
	ta 0
! If that does not work, just loop forever.
Lloop_forever:
	b Lloop_forever
	nop

! int _open (char *, int)

	.global _open
_open:
	mov 5, %g1
	ta 0
	bcc Lnoerr
	nop
	b Lcerror
	nop

! int _close (int)

	.global _close
_close:
	mov 6, %g1
	ta 0
	bcc Lnoerr
	nop
	b Lcerror
	nop

! int read (int, char *, int)

	.global _read
_read:
	mov 3, %g1
	ta 0
	bcc Lnoerr
	nop
	b Lcerror
	nop

! int write (int, char *, int)

	.global _write
_write:
	mov 4, %g1
	ta 0
	bcc Lnoerr
	nop
	b Lcerror
	nop

Lnoerr:
	retl
	nop

Lcerror:
	sethi %hi(__impure_ptr), %g1
	st %o0, [%g1+%lo(__impure_ptr)]
	retl
	mov -1, %o0
