/** Linux system call interface for the ARM processor.
 * Written by Shaun Jackman <sjackman@gmail.com>.
 * Copyright 2006 Pathway Connectivity
 *
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

#include "linux-syscall.h"

#if __thumb__
# define FUNC(name) .type name, %function; .thumb_func; name:
# define SET .thumb_set
#else
# define FUNC(name) .type name, %function; name:
# define SET .set
#endif

#define GLOBAL(name) .global name; FUNC(name)
#define SIZE(name) .size name, .-name

#if __thumb__

# define SYSCALL0(name) \
	GLOBAL(_ ## name); \
	mov r12, r7; \
	mov r7, #SYS_ ## name; \
	swi; \
	mov r7, r12; \
	b _set_errno; \
	SIZE(_ ## name)

/* static int _syscall3(int a, int b, int c, int number); */
FUNC(_syscall3)
	push { r7 }
	mov r7, r3
	swi
	pop { r7 }
	b _set_errno
	SIZE(_syscall3)

# define SYSCALL3(name) \
	GLOBAL(_ ## name); \
	mov r3, #SYS_ ## name; \
	b _syscall3; \
	SIZE(_ ## name)

# define SYSCALL6(name) \
	GLOBAL(_ ## name); \
	push { r4 - r5, r7 }; \
	ldr r4, [sp, #12]; \
	ldr r5, [sp, #16]; \
	mov r7, #SYS_ ## name; \
	swi; \
	pop { r4 - r5, r7 }; \
	b _set_errno; \
	SIZE(_ ## name)

# define SYSCALL4(name) SYSCALL6(name)

#else /* __thumb__ */

# define SYSCALL4(name) \
	GLOBAL(_ ## name); \
	swi #SYS_ ## name; \
	b _set_errno; \
	SIZE(_ ## name)

# define SYSCALL6(name) \
	GLOBAL(_ ## name); \
	push { r4 - r5 }; \
	ldr r4, [sp, #8]; \
	ldr r5, [sp, #12]; \
	swi #SYS_ ## name; \
	pop { r4 - r5 }; \
	b _set_errno; \
	SIZE(_ ## name)

#define SYSCALL0(name) SYSCALL3(name)
#define SYSCALL3(name) SYSCALL4(name)

#endif /* __thumb__ */

#define SYSCALL1(name) SYSCALL3(name)
#define SYSCALL2(name) SYSCALL3(name)
#define SYSCALL5(name) SYSCALL6(name)

SYSCALL1(alarm)
SYSCALL1(brk)
SYSCALL1(chdir)
SYSCALL2(chmod)
SYSCALL3(chown)
SYSCALL1(close)
SYSCALL1(dup)
SYSCALL2(dup2)
SYSCALL3(execve)
SYSCALL1(exit)
SYSCALL3(fcntl)
SYSCALL2(fstat)
SYSCALL2(ftruncate)
SYSCALL3(getdents)
SYSCALL0(getegid)
SYSCALL0(geteuid)
SYSCALL0(getgid)
SYSCALL2(getgroups)
SYSCALL1(getpgid)
SYSCALL0(getpgrp)
SYSCALL0(getpid)
SYSCALL0(getuid)
SYSCALL2(gettimeofday)
SYSCALL3(ioctl)
SYSCALL2(kill)
SYSCALL3(lchown)
SYSCALL2(link)
SYSCALL3(lseek)
SYSCALL2(lstat)
SYSCALL2(mkdir)
SYSCALL3(mknod)
SYSCALL2(nanosleep)
SYSCALL3(open)
SYSCALL0(pause)
SYSCALL1(pipe)
SYSCALL3(read)
SYSCALL3(readlink)
SYSCALL4(reboot)
SYSCALL1(rmdir)
SYSCALL5(select)
SYSCALL2(setpgid)
SYSCALL1(setgid)
SYSCALL0(setsid)
SYSCALL1(setuid)
SYSCALL3(sigprocmask)
SYSCALL2(socketcall)
SYSCALL2(stat)
SYSCALL1(stime)
SYSCALL2(symlink)
SYSCALL1(sync)
SYSCALL1(sysinfo)
SYSCALL1(times)
SYSCALL2(truncate)
SYSCALL1(umask)
SYSCALL1(uname)
SYSCALL1(unlink)
SYSCALL2(utime)
SYSCALL0(vfork)
SYSCALL4(wait4)
SYSCALL3(write)

#define ALIAS(name) .GLOBAL name; SET name, _ ## name

ALIAS(alarm)
ALIAS(chdir)
ALIAS(chmod)
ALIAS(chown)
ALIAS(dup)
ALIAS(dup2)
ALIAS(ftruncate)
ALIAS(getdents)
ALIAS(getegid)
ALIAS(geteuid)
ALIAS(getgid)
ALIAS(getgroups)
ALIAS(getpgid)
ALIAS(getpgrp)
ALIAS(getuid)
ALIAS(ioctl)
ALIAS(lchown)
ALIAS(lstat)
ALIAS(mkdir)
ALIAS(mknod)
ALIAS(nanosleep)
ALIAS(pause)
ALIAS(pipe)
ALIAS(readlink)
ALIAS(rmdir)
ALIAS(select)
ALIAS(setgid)
ALIAS(setpgid)
ALIAS(setsid)
ALIAS(setuid)
ALIAS(sigprocmask)
ALIAS(stime)
ALIAS(symlink)
ALIAS(sync)
ALIAS(sysinfo)
ALIAS(truncate)
ALIAS(umask)
ALIAS(uname)
ALIAS(utime)
ALIAS(vfork)
ALIAS(wait4)

# define SOCKETCALL(name, NAME) \
	GLOBAL(name); \
	push { r0 - r3 }; \
	mov r0, #SYS_ ## NAME; \
	b _socketcall_tail; \
	SIZE(name)

FUNC(_socketcall_tail)
	mov r1, sp
	push { lr }
	bl _socketcall
	pop { r3 }
	add sp, #16
#if defined(__ARM_ARCH_2__) || defined(__ARM_ARCH_3__) \
    || defined(__ARM_ARCH_3M__) || defined(__ARM_ARCH_4__)
	mov pc, r3
#else
	bx r3
#endif
	SIZE(_socketcall_tail)

#define SOCKETCALL2(name, NAME) SOCKETCALL(name, NAME)
#define SOCKETCALL3(name, NAME) SOCKETCALL(name, NAME)
#define SOCKETCALL4(name, NAME) SOCKETCALL(name, NAME)
#define SOCKETCALL5(name, NAME) SOCKETCALL(name, NAME)
#define SOCKETCALL6(name, NAME) SOCKETCALL(name, NAME)

SOCKETCALL3(accept, ACCEPT)
SOCKETCALL3(bind, BIND)
SOCKETCALL3(connect, CONNECT)
SOCKETCALL3(getpeername, GETPEERNAME)
SOCKETCALL3(getsockname, GETSOCKNAME)
SOCKETCALL5(getsockopt, GETSOCKOPT)
SOCKETCALL2(listen, LISTEN)
SOCKETCALL4(recv, RECV)
SOCKETCALL6(recvfrom, RECVFROM)
SOCKETCALL3(recvmsg, RECVMSG)
SOCKETCALL4(send, SEND)
SOCKETCALL3(sendmsg, SENDMSG)
SOCKETCALL6(sendto, SENDTO)
SOCKETCALL5(setsockopt, SETSOCKOPT)
SOCKETCALL2(shutdown, SHUTDOWN)
SOCKETCALL3(socket, SOCKET)
SOCKETCALL4(socketpair, SOCKETPAIR)
