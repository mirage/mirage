/* libc/sys/linux/process.c - Process-related system calls */

/* Written 2000 by Werner Almesberger */


#include <sys/unistd.h>
#include <sys/wait.h>
#include <machine/syscall.h>


#define __NR__exit __NR_exit
#define __NR__execve __NR_execve

_syscall0(int,getpid)
_syscall0(pid_t,getppid)

weak_alias(__libc_getpid,__getpid);

#if !defined(_ELIX_LEVEL) || _ELIX_LEVEL >= 3
_syscall3(int,_execve,const char *,file,char * const *,argv,char * const *,envp)
_syscall0(int,fork)
#endif /* _ELIX_LEVEL >= 3 */

#if !defined(_ELIX_LEVEL) || _ELIX_LEVEL >= 4
_syscall0(pid_t,getpgrp)
_syscall2(int,setpgid,pid_t,pid,pid_t,pgid)
_syscall0(pid_t,setsid)

/* Here we implement vfork in terms of fork, since
 * Linux's vfork system call is not reliable.
 */
pid_t vfork(void)
{
  pid_t pid;

  pid = fork();
  
  if(!pid)
    {
      /* In child. */
      return 0;
    }
  else
    {
      /* In parent.  Wait for child to finish. */
      if (waitpid (pid, NULL, 0) < 0)
        return pid;
    }
}
#endif /* !_ELIX_LEVEL || _ELIX_LEVEL >= 4 */


/* Although _exit is listed as level 3, we use it from level 1 interfaces */
/* FIXME: get rid of noreturn warning */

#define return for (;;)
_syscall1(void,_exit,int,exitcode)
#undef return
