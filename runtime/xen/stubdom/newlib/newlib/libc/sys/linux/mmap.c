/* libc/sys/linux/mmap.c - Memory mapping functions */

/* Copyright 2002, Red Hat Inc. */

#include <machine/syscall.h>

_syscall6(void *,mmap,void *,addr,size_t,len,int,prot,int,flags,int,fd,off_t,off);
_syscall2(int,munmap,void *,addr,size_t,len);
_syscall1(int,mlockall,int,flags);
_syscall0(int,munlockall);
_syscall2(int,mlock,const void *,addr,size_t,len);
_syscall2(int,munlock,const void *,addr,size_t,len);
_syscall3(int,mprotect,void *,addr,size_t,len,int,prot);
_syscall3(int,msync,void *,addr,size_t,len,int,flags);
_syscall4(void *,mremap,void *,addr,size_t,oldlen,size_t,newlen,int,maymove);

weak_alias(__libc_mmap,__mmap)
weak_alias(__libc_munmap,__munmap)
weak_alias(__libc_mremap,__mremap)
