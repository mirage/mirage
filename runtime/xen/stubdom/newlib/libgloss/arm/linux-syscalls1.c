/** Linux system call interface.
 * Written by Shaun Jackman <sjackman@gmail.com>.
 * Copyright 2006 Pathway Connectivity
 *
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

#include <errno.h>
#include <stdint.h>

extern char _end[];
static void *curbrk = _end;

extern void *_brk(void *addr);

int brk(void *addr)
{
	void *newbrk;
	if (curbrk == addr)
		return 0;
	newbrk = _brk(addr);
	curbrk = newbrk;
	if (newbrk < addr) {
		errno = ENOMEM;
		return -1;
	}
	return 0;
}

void *_sbrk(intptr_t incr)
{
	void *oldbrk = curbrk;
	if (brk(oldbrk + incr) == -1)
		return (void *)-1;
	return oldbrk;
}

void *sbrk(intptr_t incr) __attribute__((alias("_sbrk")));

int _set_errno(int n)
{
	if (n < 0) {
		errno = -n;
		return -1;
	}
	return n;
}

#include <sys/wait.h>

struct rusage;

pid_t wait4(pid_t pid, int *status, int options, struct rusage *rusage);

pid_t _wait(int *status)
{
	return wait4(-1, status, 0, NULL);
}

pid_t waitpid(pid_t pid, int *status, int options)
{
	return wait4(pid, status, options, NULL);
}

extern int _reboot(int magic, int magic2, int flag, void *arg);

int reboot(int flag)
{
	return _reboot(0xfee1dead, 0x28121969, flag, NULL);
}
