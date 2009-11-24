/* libc/sys/linux/io.c - Basic input/output system calls */

/* Written 2000 by Werner Almesberger */


#define __KERNEL_PROTOTYPES

#include <stdarg.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <poll.h>
#include <machine/syscall.h>


#define __NR___ioctl __NR_ioctl
#define __NR___flock __NR_flock
#define __NR___mknod __NR_mknod

_syscall3(ssize_t,read,int,fd,void *,buf,size_t,count)
_syscall3(ssize_t,write,int,fd,const void *,buf,size_t,count)
_syscall3(int,open,const char *,file,int,flag,mode_t,mode)
_syscall1(int,close,int,fd)
_syscall3(off_t,lseek,int,fd,off_t,offset,int,count)
_syscall0(int,sync)
_syscall1(int,dup,int,fd)
_syscall2(int,dup2,int,oldfd,int,newfd)
_syscall3(int,fcntl,int,fd,int,cmd,long,arg)
_syscall1(int,fdatasync,int,fd)
_syscall1(int,fsync,int,fd)
_syscall3(int,poll,struct pollfd *,fds,nfds_t,nfds,int,timeout)

#if !defined(_ELIX_LEVEL) || _ELIX_LEVEL >= 2
_syscall3(ssize_t,readv,int,fd,const struct iovec *,vec,int,count)
_syscall3(ssize_t,writev,int,fd,const struct iovec *,buf,int,count)
#endif

#if !defined(_ELIX_LEVEL) || _ELIX_LEVEL >= 4
_syscall2(int,ftruncate,int,fd,off_t,len)
_syscall2(int,truncate,const char *,path,off_t,len)
#endif

static _syscall3(int,__ioctl,int,fd,int,request,void *,arg)

int ioctl(int fd,int request,...)
{
    va_list ap;
    int res;

    va_start(ap,request);
    res = __ioctl(fd,request,va_arg(ap,void *));
    va_end(ap);
    return res;
}

static _syscall2(long,__flock,unsigned int,fd,unsigned int,cmd)

int flock(int fd,int operation)
{
    return __flock(fd,operation);
}

#if !defined(_ELIX_LEVEL) || _ELIX_LEVEL >= 3

static _syscall3(int,__mknod,const char *,path,mode_t,mode,dev_t,dev)

int mkfifo(const char *path, mode_t mode)
{
   dev_t dev = 0;
   return __mknod(path, mode | S_IFIFO, dev);
}
#endif

weak_alias(__libc_close,__close);
weak_alias(__libc_fcntl,__fcntl);
weak_alias(__libc_lseek,__lseek);
weak_alias(__libc_open,__open);
weak_alias(__libc_read,__read);
weak_alias(__libc_write,__write);
weak_alias(__libc_poll,__poll);

