/* libc/sys/linux/ids.c - System calls related to user and group ids  */

/* Written 2000 by Werner Almesberger */


#include <sys/types.h>
#include <sys/unistd.h>
#include <machine/syscall.h>


_syscall1(int,setfsuid,uid_t,uid)
_syscall0(uid_t,getuid)
_syscall1(int,setfsgid,gid_t,gid)
_syscall0(gid_t,getgid)
_syscall0(uid_t,geteuid)
_syscall0(gid_t,getegid)
_syscall3(int,setresuid,uid_t,ruid,uid_t,euid,uid_t,suid)
_syscall3(int,syslog,int,type,char *,bufp,int,len)

#if !defined(_ELIX_LEVEL) || _ELIX_LEVEL > 3
_syscall2(int,getgroups,int,size,gid_t *,list)
_syscall1(int,setgid,gid_t,gid)
_syscall1(int,setuid,uid_t,uid)
#endif

weak_alias(__libc_getuid,__getuid);
