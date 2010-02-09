/* includes linux/sysctl.h, and we don't want to rely in Linux kernel
 * headers for building the diet libc: */
/* #include <sys/sysctl.h> */
#include <unistd.h>

struct __sysctl_args {
	int *name;
	int nlen;
	void *oldval;
	size_t *oldlenp;
	void *newval;
	size_t newlen;
	unsigned long __unused[4];
};

extern int sysctl (int *, int, void *, size_t *, void *, size_t);

int
sysctl (int *name, int nlen, void *oldval, size_t *oldlenp, void *newval, size_t newlen)
{
	struct __sysctl_args args;
	args.name = name;
	args.nlen = nlen;
	args.oldval = oldval;
	args.oldlenp = oldlenp;
	args.newval = newval;
	args.newlen = newlen;
	return (_sysctl (&args));
}
