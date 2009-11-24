/* libc/sys/linux/sethostname.c - Set host name */

/* Copyright 2002, Red Hat Inc. */

#include <unistd.h>
#include <machine/syscall.h>

_syscall2(int,sethostname,const char *,name,size_t,len);
