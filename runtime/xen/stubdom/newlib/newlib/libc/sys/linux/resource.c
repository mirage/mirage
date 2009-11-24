/* libc/sys/linux/resource.c - Process resource functions */

/* Copyright 2002, Red Hat Inc. */

#include <sys/resource.h>
#include <machine/syscall.h>

_syscall2(int,getrusage,int,who,struct rusage *,r_usage)
_syscall2(int,getrlimit,int,resource,struct rlimit *,rlp)

weak_alias(__libc_getrlimit,__getrlimit)

#if !defined(_ELIX_LEVEL) || _ELIX_LEVEL >= 2
_syscall2(int,setrlimit,int,resource,const struct rlimit *,rlp)
weak_alias(__libc_setrlimit,__setrlimit)
#endif

