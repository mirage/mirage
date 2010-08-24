#ifndef _ASSERT_H
#define _ASSERT_H

#include <sys/cdefs.h>

__BEGIN_DECLS

#ifdef __PRETTY_FUNCTION__
#define __ASSERT_FUNCTION __PRETTY_FUNCTION__
#else
#  if defined __STDC_VERSION__ && __STDC_VERSION__ >= 199901L
#   define __ASSERT_FUNCTION	__func__
#  else
#   define __ASSERT_FUNCTION	((const char *) 0)
#  endif
#endif

#undef assert
#ifdef NDEBUG
#define assert(expr) ((void)0)
#else

/* This prints an "Assertion failed" message and aborts.  */
extern void __assert_fail (const char *__assertion, const char *__file,
			   unsigned int __line, const char *__function)
     __THROW __attribute__ ((__noreturn__));

#ifdef expect
# define assert(expr)							      \
  ((void) (expect((long)(expr),0) ? 0 :					      \
	   (__assert_fail (#expr,				      \
			   __FILE__, __LINE__, __ASSERT_FUNCTION), 0)))
#else
# define assert(expr)							      \
  ((void) ((expr) ? 0 :							      \
	   (__assert_fail (#expr,				      \
			   __FILE__, __LINE__, __ASSERT_FUNCTION), 0)))
#endif
#endif

__END_DECLS

#endif
