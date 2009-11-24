/* libc/sys/linux/inode.c - Inode-related system calls */

/* Written 2000 by Werner Almesberger */


#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/utime.h>
#include <linux/dirent.h>
#include <machine/syscall.h>

#define _LIBC 1
#include <sys/lock.h>


#define __NR___umask __NR_umask

_syscall2(int,link,const char *,oldpath,const char *,newpath)
_syscall1(int,unlink,const char *,pathname)
_syscall1(int,chdir,const char *,path)
_syscall1(int,fchdir,int,fd)
_syscall2(int,access,const char *,filename,int,mode)
_syscall2(int,mkdir,const char *,pathname,mode_t,mode)
_syscall1(int,rmdir,const char *,pathname)
_syscall1(int,chroot,const char *,path)
_syscall2(int,stat,const char *,file_name,struct stat *,buf)
_syscall2(int,statfs,const char *,file_name,struct statfs *,buf)
_syscall2(int,fstat,int,filedes,struct stat *,buf)
_syscall2(int,fstatfs,int,filedes,struct statfs *,buf)
_syscall3(int,getdents,int,fd,struct dirent *,dirp,unsigned int,count)

#if !defined(_ELIX_LEVEL) || _ELIX_LEVEL >= 2
_syscall2(int,chmod,const char *,path,mode_t,mode)
_syscall3(int,chown,const char *,path,uid_t,owner,gid_t,group)
_syscall2(int,fchmod,int,filedes,mode_t,mode)
_syscall3(int,lchown,const char *,path,uid_t,owner,gid_t,group)
_syscall2(int,lstat,const char *,file_name,struct stat *,buf)
_syscall3(int,readlink,const char *,path,char *,buf,size_t,bufsiz)
_syscall2(int,symlink,const char *,oldpath,const char *,newpath)
_syscall2(int,utime,const char *,filename,const struct utimbuf *,buf)
#endif

#if !defined(_ELIX_LEVEL) || _ELIX_LEVEL >= 3
_syscall1(int,pipe,int *,filedes)
#endif

#if !defined(_ELIX_LEVEL) || _ELIX_LEVEL >= 4
_syscall3(int,mknod,const char *,pathname,mode_t,mode,dev_t,dev)
#endif

weak_alias(__libc_statfs,__statfs)
weak_alias(__libc_fstatfs,__fstatfs)

static _syscall3(int,fchown32,int,fd,uid_t,owner,gid_t,group)

int
fchown (int fd, uid_t owner, gid_t group)
{
  return __libc_fchown32 (fd, owner, group);
}

#if !defined(_ELIX_LEVEL) || _ELIX_LEVEL >= 2

__LOCK_INIT(static, umask_lock);

_syscall1(mode_t,__umask,mode_t,mask)

mode_t
umask (mode_t mask)
{
  mode_t old_mask;

  /* we need to lock so as to not interfere with getumask */
  __lock_acquire(umask_lock);
  old_mask = __umask (mask);
  __lock_release(umask_lock);

  return old_mask;
}

mode_t
getumask (void)
{
  mode_t mask;

  __lock_acquire(umask_lock);

  mask = __umask (0);
  mask = __umask (mask);

  __lock_release(umask_lock);

  return mask;
}

#endif /* !_ELIX_LEVEL || _ELIX_LEVEL >= 2 */
