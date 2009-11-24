/* libc/sys/linux/stack.c - Basic stack system calls */

/* Copyright 2002, Red Hat Inc. */

#include <signal.h>
#include <unistd.h>
#include <sys/types.h>
#include <machine/syscall.h>

_syscall2(int,sigaltstack,const stack_t *,ss,stack_t *,oss)
