#ifndef _STDARG_H
#define _STDARG_H

#include <sys/cdefs.h>
#include <endian.h>

__BEGIN_DECLS

#if (__GNUC__ > 2) || ((__GNUC__ == 2) && (__GNUC_MINOR__ >= 96))

typedef __builtin_va_list va_list;
#define va_start(v,l)	__builtin_va_start((v),(l))
#define va_end		__builtin_va_end
#define va_arg		__builtin_va_arg
#define __va_copy(d,s)	__builtin_va_copy((d),(s))

#endif

#ifndef va_end
#include <stdarg-cruft.h>
#endif

#if !defined(__STRICT_ANSI__) || __STDC_VERSION__ + 0 >= 199900L
#define va_copy(d,s)	__va_copy(d,s)
#endif

__END_DECLS

#endif
