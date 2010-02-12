#ifndef _ALLOCA_H
#define _ALLOCA_H

#include <sys/cdefs.h>
#include <sys/types.h>

__BEGIN_DECLS

#ifdef __GNUC__
#define alloca(x) __builtin_alloca(x)
#else
void *alloca(size_t size) __THROW;
#endif

__END_DECLS

#endif
