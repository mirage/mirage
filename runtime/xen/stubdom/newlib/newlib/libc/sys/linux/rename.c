/* libc/sys/linux/rename.c - rename a file */

/* Copyright 2002, Red Hat Inc. */

#include <stdio.h>
#include <machine/syscall.h>

_syscall2(int,rename,const char *,old,const char *,new)

