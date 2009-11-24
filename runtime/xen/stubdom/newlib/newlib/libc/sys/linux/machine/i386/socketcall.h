/* libc/sys/linux/machine/i386/socketcall.h - x86 linux socket system calls */

/* Copyright 2002, Red Hat Inc. */

#ifndef _SOCKETCALL_H

#define _SOCKETCALL_H 

#include <machine/weakalias.h>
#include <sys/errno.h>
#include <asm/unistd.h>
#include "sockops.h"

/*
 * PIC uses %ebx, so we need to save it during system calls
 */

#ifdef __syscall_return

#define __sockcall_base(type, name) \
{ \
long __res; \
__asm__ volatile ("push %%ebx; movl %2,%%ebx; lea 8(%%ebp),%%ecx; int $0x80; pop %%ebx" \
	: "=a" (__res) \
	: "0" (__NR_socketcall),"r" (SOCK_##name)); \
__syscall_return(type,__res); \
}

#else /* !defined(__syscall_return) */

/* FIXME: we need to rewrite this for a vsyscall system.  */

#define __syscall_return(type, res) \
do { \ 
  if ((unsigned long)(res) >= (unsigned long)(-125)) { \
    errno = -(res); \
    res = -1; \
  } \
  return (type) (res); \
} while (0)

#define __sockcall_base(type, name) \
{ \
long __res; \
__asm__ volatile ("push %%ebx; movl %2,%%ebx; lea 8(%%ebp),%%ecx; int $0x80; pop %%ebx" \
	: "=a" (__res) \
	: "0" (__NR_socketcall),"r" (SOCK_##name)); \
__syscall_return(type,__res); \
}

#endif /* !defined(__syscall_return) */

#undef _sockcall1
#define _sockcall1(type,name,type1,arg1) \
type __libc_##name(type1 arg1) \
__sockcall_base(type,name) \
weak_alias(__libc_##name,name)

#undef _sockcall2
#define _sockcall2(type,name,type1,arg1,type2,arg2) \
type __libc_##name(type1 arg1, type2 arg2) \
__sockcall_base(type,name) \
weak_alias(__libc_##name,name)

#undef _sockcall3
#define _sockcall3(type,name,type1,arg1,type2,arg2,type3,arg3) \
type __libc_##name(type1 arg1, type2 arg2, type3 arg3) \
__sockcall_base(type,name) \
weak_alias(__libc_##name,name)

#undef _sockcall4
#define _sockcall4(type,name,type1,arg1,type2,arg2,type3,arg3,type4,arg4) \
type __libc_##name(type1 arg1, type2 arg2, type3 arg3, type4 arg4) \
__sockcall_base(type,name) \
weak_alias(__libc_##name,name)

#undef _sockcall5
#define _sockcall5(type,name,type1,arg1,type2,arg2,type3,arg3,type4,arg4,type5,arg5) \
type __libc_##name(type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5) \
__sockcall_base(type,name) \
weak_alias(__libc_##name,name)

#undef _sockcall6
#define _sockcall6(type,name,type1,arg1,type2,arg2,type3,arg3,type4,arg4,type5,arg5,type6,arg6) \
type __libc_##name(type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6) \
__sockcall_base(type,name) \
weak_alias(__libc_##name,name)

#endif /* _SOCKETCALL_H */
