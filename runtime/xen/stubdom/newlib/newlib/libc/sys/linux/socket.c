/* libc/sys/linux/socket.c - socket system calls */

/* Copyright 2002, Red Hat Inc. */

#define __KERNEL_PROTOTYPES

#include <stdarg.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <machine/socketcall.h>

_sockcall3(int,accept,int,fd,struct sockaddr *,addr,socklen_t *,addr_len)
_sockcall3(int,bind,int,fd,const struct sockaddr *,addr,socklen_t,len)
_sockcall3(int,connect,int,fd,const struct sockaddr *,addr,socklen_t,len)
_sockcall3(int,getpeername,int,fd,struct sockaddr *,addr,socklen_t *,len)
_sockcall3(int,getsockname,int,fd,struct sockaddr *,addr,socklen_t *,len)
_sockcall5(int,getsockopt,int,fd,int,level,int,opt,void *,optval,socklen_t *,optlen)
_sockcall2(int,listen,int,fd,int,n)
_sockcall4(ssize_t,recv,int,fd,void *,buf,size_t,n,int,flags)
_sockcall6(ssize_t,recvfrom,int,fd,void *,buf,size_t,n,int,flags,struct sockaddr *,addr,socklen_t *,addr_len)
_sockcall3(ssize_t,recvmsg,int,fd,struct msghdr *,message,int,flags)
_sockcall4(ssize_t,send,int,fd,const void *,buf,size_t,n,int,flags)
_sockcall6(ssize_t,sendto,int,fd,const void *,buf,size_t,n,int,flags,const struct sockaddr *,addr,socklen_t,addr_len)
_sockcall5(int,setsockopt,int,fd,int,level,int,opt,const void *,optval,socklen_t,optlen)
_sockcall2(int,shutdown,int,fd,int,how)
_sockcall3(int,socket,int,domain,int,type,int,protocol)
_sockcall4(int,socketpair,int,domain,int,type,int,protocol,int,fds[2])
_sockcall3(ssize_t,sendmsg,int,fd,const struct msghdr *,message,int,flags)

weak_alias(__libc_connect,__connect);
weak_alias(__libc_send,__send);
