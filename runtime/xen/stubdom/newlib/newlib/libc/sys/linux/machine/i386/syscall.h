/* libc/sys/linux/machine/i386/syscall.h - x86 linux system calls */

/* Written 2000 by Werner Almesberger */


#ifndef SYSCALL_H

#include <machine/weakalias.h>
#include <sys/errno.h>
#include <asm/unistd.h>
#include <unistd.h>


/*
 * Note: several system calls are for SysV or BSD compatibility, or are
 * specific Linuxisms. Most of those system calls are not implemented in
 * this library.
 */


#if defined(__PIC__) && defined(__i386__)

/*
 * PIC uses %ebx, so we need to save it during system calls
 */

#ifndef __syscall_return

/* FIXME: remove this and switch over to use vsyscall.  */

#define __syscall_return(type, res) \
do { \
  if ((unsigned long)(res) >= (unsigned long)(-125)) { \
    errno = -(res); \
    res = -1; \
  } \
  return (type) (res); \
} while (0)

#endif                                                                                
#undef __inline_syscall0
#define __inline_syscall0(name,ret) \
__asm__ volatile ("int $0x80" \
	: "=a" (ret) \
	: "0" (__NR_##name));

#undef __inline_syscall1
#define __inline_syscall1(name,ret,arg1) \
__asm__ volatile ("push %%ebx; movl %2,%%ebx; int $0x80; pop %%ebx" \
	: "=a" (ret) \
	: "0" (__NR_##name),"r" ((long)(arg1)));

#undef __inline_syscall2
#define __inline_syscall2(name,ret,arg1,arg2) \
__asm__ volatile ("push %%ebx; movl %2,%%ebx; int $0x80; pop %%ebx" \
	: "=a" (ret) \
	: "0" (__NR_##name),"r" ((long)(arg1)),"c" ((long)(arg2)));

#undef __inline_syscall3
#define __inline_syscall3(name,ret,arg1,arg2,arg3) \
__asm__ volatile ("push %%ebx; movl %2,%%ebx; int $0x80; pop %%ebx" \
	: "=a" (ret) \
	: "0" (__NR_##name),"r" ((long)(arg1)),"c" ((long)(arg2)), \
		"d" ((long)(arg3)));

#undef __inline_syscall4
#define __inline_syscall4(name,ret,arg1,arg2,arg3,arg4) \
__asm__ volatile ("push %%ebx; movl %2,%%ebx; int $0x80; pop %%ebx" \
	: "=a" (ret) \
	: "0" (__NR_##name),"r" ((long)(arg1)),"c" ((long)(arg2)), \
	  "d" ((long)(arg3)),"S" ((long)(arg4)));

#undef __inline_syscall5
#define __inline_syscall5(name,ret,arg1,arg2,arg3,arg4,arg5) \
__asm__ volatile ("push %%ebx; movl %2,%%ebx; int $0x80; pop %%ebx" \
	: "=a" (ret) \
	: "0" (__NR_##name),"m" ((long)(arg1)),"c" ((long)(arg2)), \
	  "d" ((long)(arg3)),"S" ((long)(arg4)),"D" ((long)(arg5)));

#undef __inline_syscall6
#define __inline_syscall6(name,ret,arg1,arg2,arg3,arg4,arg5,arg6) \
__asm__ volatile ("push %%ebx; lea 8(%%ebp),%%ebx; int $0x80; pop %%ebx" \
	: "=a" (ret) \
	: "0" (__NR_##name));

#undef _syscall0_base
#define _syscall0_base(type,name) \
type __libc_##name (void) \
{ \
long __res; \
__inline_syscall0(name,__res) \
__syscall_return(type,__res); \
}

#undef _syscall1_base
#define _syscall1_base(type,name,type1,arg1) \
type __libc_##name (type1 arg1) \
{ \
long __res; \
__inline_syscall1(name,__res,arg1) \
__syscall_return(type,__res); \
}

#undef _syscall2_base
#define _syscall2_base(type,name,type1,arg1,type2,arg2) \
type __libc_##name (type1 arg1,type2 arg2) \
{ \
long __res; \
__inline_syscall2(name,__res,arg1,arg2) \
__syscall_return(type,__res); \
}

#undef _syscall3_base
#define _syscall3_base(type,name,type1,arg1,type2,arg2,type3,arg3) \
type __libc_##name (type1 arg1,type2 arg2,type3 arg3) \
{ \
long __res; \
__inline_syscall3(name,__res,arg1,arg2,arg3) \
__syscall_return(type,__res); \
}

#undef _syscall4_base
#define _syscall4_base(type,name,type1,arg1,type2,arg2,type3,arg3,type4,arg4) \
type __libc_##name (type1 arg1, type2 arg2, type3 arg3, type4 arg4) \
{ \
long __res; \
__inline_syscall4(name,__res,arg1,arg2,arg3,arg4) \
__syscall_return(type,__res); \
}

#undef _syscall5_base
#define _syscall5_base(type,name,type1,arg1,type2,arg2,type3,arg3,type4,arg4, \
          type5,arg5) \
type __libc_##name (type1 arg1,type2 arg2,type3 arg3,type4 arg4,type5 arg5) \
{ \
long __res; \
__inline_syscall5(name,__res,arg1,arg2,arg3,arg4,arg5) \
__syscall_return(type,__res); \
} \

#undef _syscall6_base
#define _syscall6_base(type,name,type1,arg1,type2,arg2,type3,arg3,type4,arg4, \
          type5,arg5,type6,arg6) \
type __libc_##name (type1 arg1,type2 arg2,type3 arg3,type4 arg4,type5 arg5,type6 arg6) \
{ \
long __res; \
__inline_syscall6(name,__res,arg1,arg2,arg3,arg4,arg5,arg6) \
__syscall_return(type,__res); \
}

#undef _syscall0
#define _syscall0(type,name) \
_syscall0_base(type,name) \
weak_alias(__libc_##name,name);

#undef _syscall1
#define _syscall1(type,name,type1,arg1) \
_syscall1_base(type,name,type1,arg1) \
weak_alias(__libc_##name,name);

#undef _syscall2
#define _syscall2(type,name,type1,arg1,type2,arg2) \
_syscall2_base(type,name,type1,arg1,type2,arg2) \
weak_alias(__libc_##name,name);

#undef _syscall3
#define _syscall3(type,name,type1,arg1,type2,arg2,type3,arg3) \
_syscall3_base(type,name,type1,arg1,type2,arg2,type3,arg3) \
weak_alias(__libc_##name,name);

#undef _syscall4
#define _syscall4(type,name,type1,arg1,type2,arg2,type3,arg3,type4,arg4) \
_syscall4_base(type,name,type1,arg1,type2,arg2,type3,arg3,type4,arg4) \
weak_alias(__libc_##name,name);

#undef _syscall5
#define _syscall5(type,name,type1,arg1,type2,arg2,type3,arg3,type4,arg4, \
          type5,arg5) \
_syscall5_base(type,name,type1,arg1,type2,arg2,type3,arg3,type4,arg4,type5,arg5) \
weak_alias(__libc_##name,name);

#undef _syscall6
#define _syscall6(type,name,type1,arg1,type2,arg2,type3,arg3,type4,arg4, \
          type5,arg5,type6,arg6) \
_syscall6_base(type,name,type1,arg1,type2,arg2,type3,arg3,type4,arg4,type5,arg5,type6,arg6) \
weak_alias(__libc_##name,name);

#endif /* __PIC__ && __i386__ */

#endif /* SYSCALL_H */
