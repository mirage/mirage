#ifndef	_SYS_KLOG_H
#define	_SYS_KLOG_H

#include <sys/cdefs.h>

__BEGIN_DECLS

extern int klogctl (int __type, char *__bufp, int __len) __THROW;

__END_DECLS

#endif 
