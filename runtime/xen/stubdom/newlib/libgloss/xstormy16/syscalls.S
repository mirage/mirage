# xstormy16 system calls for the simulator

#include <syscall.h>

	.text

	.globl _exit
_exit:
	mov r1,#SYS_exit
	.hword 0x0001
	bnz r1,#0,syscall_error
	ret
0:	.size exit,0b-_exit

	.globl _open
_open:
	mov r1,#SYS_open
	.hword 0x0001
	bnz r1,#0,syscall_error
	ret
0:	.size open,0b-_open

	.globl _close
_close:
	mov r1,#SYS_close
	.hword 0x0001
	bnz r1,#0,syscall_error
	ret
0:	.size close,0b-_close

	.globl _read
_read:
	mov r1,#SYS_read
	.hword 0x0001
	bnz r1,#0,syscall_error
	ret
0:	.size read,0b-_read

	.globl _write
_write:
	mov r1,#SYS_write
	.hword 0x0001
	bnz r1,#0,syscall_error
	ret
0:	.size write,0b-_write

	.globl _lseek
_lseek:
	mov r1,#SYS_lseek
	.hword 0x0001
	bnz r1,#0,syscall_error
	ret
0:	.size lseek,0b-_lseek

	.globl _unlink
_unlink:
	mov r1,#SYS_unlink
	.hword 0x0001
	bnz r1,#0,syscall_error
	ret
0:	.size unlink,0b-_unlink

	.globl _getpid
_getpid:
	mov r1,#SYS_getpid
	.hword 0x0001
	bnz r1,#0,syscall_error
	ret
0:	.size getpid,0b-_getpid

	.globl _kill
_kill:
	mov r1,#SYS_kill
	.hword 0x0001
	bnz r1,#0,syscall_error
	ret
0:	.size kill,0b-_kill

	.globl _fstat
_fstat:
	mov r1,#SYS_fstat
	.hword 0x0001
	bnz r1,#0,syscall_error
	ret
0:	.size fstat,0b-_fstat

	.globl _chdir
_chdir:
	mov r1,#SYS_chdir
	.hword 0x0001
	bnz r1,#0,syscall_error
	ret
0:	.size chdir,0b-_chdir

	.globl _stat
_stat:
	mov r1,#SYS_stat
	.hword 0x0001
	bnz r1,#0,syscall_error
	ret
0:	.size stat,0b-_stat

	.globl _chmod
_chmod:
	mov r1,#SYS_chmod
	.hword 0x0001
	bnz r1,#0,syscall_error
	ret
0:	.size chmod,0b-_chmod

	.globl _utime
_utime:
	mov r1,#SYS_utime
	.hword 0x0001
	bnz r1,#0,syscall_error
	ret
0:	.size utime,0b-_utime

	.globl _time
_time:
	mov r1,#SYS_time
	.hword 0x0001
	bnz r1,#0,syscall_error
	ret
0:	.size time,0b-_time

	.globl _gettimeofday
_gettimeofday:
	mov r1,#SYS_gettimeofday
	.hword 0x0001
	bnz r1,#0,syscall_error
	ret
0:	.size gettimeofday,0b-_gettimeofday

	.globl _times
_times:
	mov r1,#SYS_times
	.hword 0x0001
	bnz r1,#0,syscall_error
	ret
0:	.size times,0b-_times

	.globl _link
_link:
	mov r1,#SYS_link
	.hword 0x0001
	bnz r1,#0,syscall_error
	ret
0:	.size link,0b-_link

syscall_error:
# Return value for the syscall is in r2.  Save it here, as
# _errno will overwrite it with the address of the errno
# variable.  r0 is the errno.
	push r2
	push r0
	callf __errno
	pop r0
	mov.w (r2),r0
	pop r2
	ret
0:	.size syscall_error,0b-syscall_error
