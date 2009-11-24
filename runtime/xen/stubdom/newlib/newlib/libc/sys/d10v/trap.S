#include "sys/syscall.h"

#define SYSCALL(name) \
	.global name	; \
name:			; \
	ldi	r4, SYS ## name ; \
	bra	__trap0

	.text
	.stabs	"trap.S",100,0,0,__trap0
	.stabs	"int:t(0,1)=r(0,1);-65536;65535;",128,0,0,0
	.stabs	"long int:t(0,2)=r(0,1);0020000000000;0017777777777;",128,0,0,0
	.stabs	"_trap0:F(0,1)",36,0,1,__trap0
	.stabs	"arg1:P(0,1)",64,0,1,0
	.stabs	"arg2:P(0,1)",64,0,1,1
	.stabs	"arg3:P(0,1)",64,0,1,2
	.stabs	"arg4:P(0,1)",64,0,1,3
	.stabs	"number:P(0,1)",64,0,1,4
	.global	__trap0
	.type	__trap0,@function
__trap0:
	trap	15			/* trap 15 returns result in r0, error code in r4 */
	cmpeqi	r4,0			/* is error code zero? */
	brf0t	ret			/* yes, skip setting errno */
#if __INT__==32
	st	r4,@(errno+2,r14)	/* no, set errno */
	srai	r4,15			/* sign extend high word */
	st	r4,@(errno,r14)
#else
	st	r4,@(errno,r14)	/* no, set errno */
#endif

ret:
	jmp	r13		/* return to caller */
.Ltrap0:
	.size	__trap0,.Ltrap0-__trap0
	.stabs	"",36,0,0,.Ltrap0-__trap0

#define CONCAT(a,b) a ## b
#define STRING(a) #a
#define XSTRING(a) STRING(a)
#define XSTRING2(a,b) XSTRING(CONCAT(a,b))

#if __INT__==32
#define _read _read16
#define _lseek _lseek16
#define _write _write16
#define _close _close16
#define _open _open16
#define _creat _creat16
#define _exit _exit16
#define _stat _stat16
#define _chmod _chmod16
#define _chown _chown16
#define _fork _fork16
#define _wait _wait16
#define _execve _execve16
#define _execv _execv16
#define _pipe _pipe16
#define _kill _kill16
#define _getpid _getpid16
#endif

/* Until the assembler allows semicolon as a statement separator, */
/* we cannot use the SYSCALL macro.  So expand it manually for now. */

/* #SYSCALL(_read) */
/* #SYSCALL(_lseek) */
/* #SYSCALL(_write) */
/* #SYSCALL(_close) */
/* #SYSCALL(_open) */
/* #SYSCALL(_creat) */
/* #SYSCALL(_exit) */
/* #SYSCALL(_stat) */
/* #SYSCALL(_chmod) */
/* #SYSCALL(_chown) */
/* #SYSCALL(_fork) */
/* #SYSCALL(_wait) */
/* #SYSCALL(_execve) */
/* #SYSCALL(_execv) */
/* #SYSCALL(_pipe) */
/* #SYSCALL(_getpid) */
/* #SYSCALL(_kill) */

	.global	_read
	.type	_read,@function
	.stabs	XSTRING2(_read,:F(0,1)),36,0,2,_read
	.stabs	"fd:P(0,1)",64,0,1,0
	.stabs	"ptr:P(0,1)",64,0,1,1
	.stabs	"len:P(0,1)",64,0,1,2
_read:
	ldi	r4, SYS_read
	bra	__trap0
.Lread:
	.size	_read,.-_read
	.stabs	"",36,0,0,.Lread-_read

	.global	_lseek
	.type	_lseek,@function
	.stabs	XSTRING2(_lseek,:F(0,1)),36,0,3,_lseek
	.stabs	"fd:P(0,1)",64,0,1,0
	.stabs	"offset:P(0,1)",64,0,1,2
	.stabs	"whence:p(0,1)",160,0,1,0
_lseek:
	ldi	r4, SYS_lseek
	bra	__trap0
.Llseek:
	.size	_lseek,.Llseek-_lseek
	.stabs	"",36,0,0,.Llseek-_lseek

	.global	_write
	.type	_write,@function
	.stabs	XSTRING2(_write,:F(0,1)),36,0,4,_write
	.stabs	"fd:P(0,1)",64,0,1,0
	.stabs	"ptr:P(0,1)",64,0,1,1
	.stabs	"len:P(0,1)",64,0,1,2
_write:
	ldi	r4, SYS_write
	bra	__trap0
.Lwrite:
	.size	_write,.Lwrite-_write
	.stabs	"",36,0,0,.Lwrite-_write

	.global	_close
	.type	_close,@function
	.stabs	XSTRING2(_close,:F(0,1)),36,0,5,_close
	.stabs	"fd:P(0,1)",64,0,1,0
_close:
	ldi	r4, SYS_close
	bra	__trap0
.Lclose:
	.size	_close,.Lclose-_close
	.stabs	"",36,0,0,.Lclose-_close

	.global	_open
	.type	_open,@function
	.stabs	XSTRING2(_open,:F(0,1)),36,0,6,_open
	.stabs	"name:P(0,1)",64,0,1,0
	.stabs	"flags:P(0,1)",64,0,1,1
	.stabs	"mode:P(0,1)",64,0,1,2
_open:
	ldi	r4, SYS_open
	bra	__trap0
.Lopen:
	.size	_open,.Lopen-_open
	.stabs	"",36,0,0,.Lopen-_open

	.global	_creat
	.type	_creat,@function
	.stabs	XSTRING2(_creat,:F(0,1)),36,0,7,_creat
	.stabs	"name:P(0,1)",64,0,1,0
	.stabs	"mode:P(0,1)",64,0,1,1
_creat:
	ldi	r4, SYS_creat
	bra	__trap0
.Lcreat:
	.size	_creat,.Lcreat-_creat
	.stabs	"",36,0,0,.Lcreat-_creat

	.global	_exit
	.type	_exit,@function
	.stabs	XSTRING2(_exit,:F(0,1)),36,0,8,_exit
	.stabs	"status:P(0,1)",64,0,1,0
_exit:
	ldi	r4, SYS_exit
	bra	__trap0
.Lexit:
	.size	_exit,.Lexit-_exit
	.stabs	"",36,0,0,.Lexit-_exit

	.global	_stat
	.type	_stat,@function
	.stabs	XSTRING2(_stat,:F(0,1)),36,0,9,_stat
	.stabs	"name:P(0,1)",64,0,1,0
	.stabs	"packet:P(0,1)",64,0,1,1
_stat:
	ldi	r4, SYS_stat
	bra	__trap0
.Lstat:
	.size	_stat,.Lstat-_stat
	.stabs	"",36,0,0,.Lstat-_stat

	.global	_chmod
	.type	_chmod,@function
	.stabs	XSTRING2(_chmod,:F(0,1)),36,0,10,_chmod
	.stabs	"name:P(0,1)",64,0,1,0
	.stabs	"mode:P(0,1)",64,0,1,1
_chmod:
	ldi	r4, SYS_chmod
	bra	__trap0
.Lchmod:
	.size	_chmod,.Lchmod-_chmod
	.stabs	"",36,0,0,.Lchmod-_chmod

	.global	_chown
	.type	_chown,@function
	.stabs	XSTRING2(_chown,:F(0,1)),36,0,11,_chown
	.stabs	"name:P(0,1)",64,0,1,0
	.stabs	"uid:P(0,1)",64,0,1,1
	.stabs	"gid:P(0,1)",64,0,1,2
_chown:
	ldi	r4, SYS_chown
	bra	__trap0
.Lchown:
	.size	_chown,.Lchown-_chown
	.stabs	"",36,0,0,.Lchown-_chown

	.global	_fork
	.type	_fork,@function
	.stabs	XSTRING2(_fork,:F(0,1)),36,0,12,_fork
_fork:
	ldi	r4, SYS_fork
	bra	__trap0
.Lfork:
	.size	_fork,.Lfork-_fork
	.stabs	"",36,0,0,.Lfork-_fork

	.global	_wait
	.type	_wait,@function
	.stabs	"status:P(0,1)",64,0,1,0
	.stabs	XSTRING2(_wait,:F(0,1)),36,0,13,_wait
_wait:
	ldi	r4, SYS_wait
	bra	__trap0
.Lwait:
	.size	_wait,.Lwait-_wait
	.stabs	"",36,0,0,.Lwait-_wait

	.global	_execve
	.type	_execve,@function
	.stabs	"name:P(0,1)",64,0,1,0
	.stabs	"argv:P(0,1)",64,0,1,1
	.stabs	"envp:P(0,1)",64,0,1,2
	.stabs	XSTRING2(_execve,:F(0,1)),36,0,14,_execve
_execve:
	ldi	r4, SYS_execve
	bra	__trap0
.Lexecve:
	.size	_execve,.Lexecve-_execve
	.stabs	"",36,0,0,.Lexecve-_execve

	.global	_execv
	.type	_execv,@function
	.stabs	XSTRING2(_execv,:F(0,1)),36,0,15,_execv
	.stabs	"name:P(0,1)",64,0,1,0
	.stabs	"argv:P(0,1)",64,0,1,1
_execv:
	ldi	r4, SYS_execv
	bra	__trap0
.Lexecv:
	.size	_execv,.Lexecv-_execv
	.stabs	"",36,0,0,.Lexecv-_execv

	.global	_pipe
	.type	_pipe,@function
	.stabs	XSTRING2(_pipe,:F(0,1)),36,0,16,_pipe
	.stabs	"fds:P(0,1)",64,0,1,0
_pipe:
	ldi	r4, SYS_pipe
	bra	__trap0
.Lpipe:
	.size	_pipe,.Lpipe-_pipe
	.stabs	"",36,0,0,.Lpipe-_pipe

	.global	time
	.type	time,@function
	.stabs	XSTRING2(time,:F(0,1)),36,0,17,time
	.stabs	"ptr:P(0,1)",64,0,1,0
time:
	ldi	r4, SYS_time
	bra	__trap0
.Ltime:
	.size	time,.Ltime-time
	.stabs	"",36,0,0,.Ltime-time

	.global	_kill
	.type	_kill,@function
	.stabs	XSTRING2(_kill,:F(0,1)),36,0,18,_kill
	.stabs	"pid:P(0,1)",64,0,1,0
	.stabs	"sig:P(0,1)",64,0,1,1
_kill:
	ldi	r4, SYS_kill
	bra	__trap0
.Lkill:
	.size	_kill,.Lkill-_kill
	.stabs	"",36,0,0,.Lkill-_kill

	.global	_getpid
	.type	_getpid,@function
	.stabs	XSTRING2(_getpid,:F(0,1)),36,0,19,_getpid
_getpid:
	ldi	r4, SYS_getpid
	bra	__trap0
.Lgetpid:
	.size	_getpid,.Lgetpid-_getpid
	.stabs	"",36,0,0,.Lgetpid-_getpid
