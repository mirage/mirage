/* libc/sys/linux/profile.c - profiling system call */

#include <errno.h>
#include <sys/types.h>
#include <machine/syscall.h>

#define __NR_profil 98

int  profil(u_short  *buf,  size_t  bufsiz, size_t offset,
            u_int scale);

_syscall4(int,profil,unsigned short *,buf,size_t,bufsiz,size_t,offset,unsigned int, scale)
