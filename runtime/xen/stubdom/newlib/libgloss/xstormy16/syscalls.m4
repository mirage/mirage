# xstormy16 system calls for the simulator

#include <syscall.h>

	.text

define(`syscall',`.globl _`'$1
_`'$1`':
	mov r1,#SYS_$1
	.hword 0x0001
	bnz r1,#0,syscall_error
	ret
0:	.size $1,0b-_$1
')dnl
	syscall(exit)
	syscall(open)
	syscall(close)
	syscall(read)
	syscall(write)
	syscall(lseek)
	syscall(unlink)
	syscall(getpid)
	syscall(kill)
	syscall(fstat)
	syscall(chdir)
	syscall(stat)
	syscall(chmod)
	syscall(utime)
	syscall(time)
	syscall(gettimeofday)
	syscall(times)
	syscall(link)
dnl
syscall_error:
	push r0
	callf __errno
	pop r0
	mov.w (r2),r0
	ret
0:	.size syscall_error,0b-syscall_error
