/* libc/sys/linux/io64.c - large file input/output system calls */

/* Copyright 2002, Red Hat Inc. */


#define __KERNEL_PROTOTYPES

#include <stdarg.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <machine/syscall.h>

#define __NR___truncate64 __NR_truncate64
#define __NR___ftruncate64 __NR_ftruncate64

_syscall2(int,fstat64,int,fd,struct stat64 *,st)
_syscall2(int,lstat64,const char *,name,struct stat64 *,st)
_syscall2(int,stat64,const char *,name,struct stat64 *,st)

static _syscall3(int,__truncate64,const char *,name,int,high,int,low)

int __libc_truncate64(const char *name, off64_t length)
{
  return __truncate64(name,(length >> 32), (length & 0xffffffff));
}
weak_alias(__libc_truncate64,truncate64)

static _syscall3(int,__ftruncate64,int,fd,int,high,int,low);

int __libc_ftruncate64(int fd, off64_t length)
{
  return __ftruncate64(fd,(length >> 32),(length & 0xffffffff));
}
weak_alias(__libc_ftruncate64,ftruncate64)

static _syscall5(void,_llseek,int,fd,off_t,hi,off_t,lo,loff_t *,pos,int,whence)

loff_t __libc_lseek64(int fd, loff_t offset, int whence)
{
  loff_t pos;
  __libc__llseek(fd, offset >> 32, offset & 0xffffffff, &pos, whence);
  return pos;
}
weak_alias(__libc_lseek64,lseek64);
weak_alias(__libc_lseek64,_lseek64);

int __libc_open64(const char *path, int oflag, ...)
{
   mode_t mode = 0;
   if (oflag & O_CREAT)
     {
       va_list list;
       va_start(list, oflag);
       mode = va_arg(list, int);
       va_end(list);
     }
   return __libc_open(path, oflag | O_LARGEFILE, mode);
}
weak_alias(__libc_open64,open64);
weak_alias(__libc_open64,_open64);
weak_alias(__libc_open64,__open64);
weak_alias(__libc_fstat64,_fstat64);


