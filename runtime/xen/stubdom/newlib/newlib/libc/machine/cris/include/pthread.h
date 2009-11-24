/* pthread.h dummy.
   Copyright (C) 2001, 2004, 2005 Axis Communications AB.
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:

   1. Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

   2. Neither the name of Axis Communications nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY AXIS COMMUNICATIONS AND ITS CONTRIBUTORS
   ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL AXIS
   COMMUNICATIONS OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
   INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
   (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
   SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
   STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
   IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
   POSSIBILITY OF SUCH DAMAGE.  */

/* Simple fallback-include to enable thread-enabled exception support
   for libgcc, but with posix-interface to a default-dummy, so a posix
   library can optionally be linked in, which isn't possible if
   gthr-single.h is used.  No other use is supported; *DO NOT* think
   this gives you a valid pthread interface to use in your applications.  */

#ifndef _PTHREAD_FAKE
#define _PTHREAD_FAKE

#ifdef __cplusplus
extern "C" {
# ifndef __THROW
#  define __THROW throw ()
# endif
#else
# ifndef __THROW
#  define __THROW
# endif
#endif

typedef int pthread_once_t;
typedef unsigned int pthread_key_t;

/* This must be layout-compatible with the linuxthreads type.  */
typedef struct
{
  int a, b;
  void *c;
  int d;
  struct { long int e; int f; } g;
} pthread_mutex_t;

/* This give bits equal to the linuxthreads initializer.  */
#define PTHREAD_MUTEX_INITIALIZER \
  {0, 0, 0, 0, {0, 0}}

#define PTHREAD_ONCE_INIT 0

/* This isn't the right prototype, but it let's us get away with not
   defining a lot of datatypes.  */
extern int pthread_create (void) __THROW;

extern int pthread_once (pthread_once_t *, void (*) (void)) __THROW;

extern int pthread_key_create (pthread_key_t *, void (*) (void *)) __THROW;

extern int pthread_setspecific (pthread_key_t, const void *) __THROW;

extern void *pthread_getspecific (pthread_key_t) __THROW;

extern int pthread_mutex_lock (pthread_mutex_t *) __THROW;

extern int pthread_key_delete (pthread_key_t) __THROW;

extern int pthread_mutex_trylock (pthread_mutex_t *) __THROW;

extern int pthread_mutex_unlock (pthread_mutex_t *) __THROW;

#ifdef __cplusplus
}
#endif

#undef __THROW

#endif /* not _PTHREAD_FAKE */
