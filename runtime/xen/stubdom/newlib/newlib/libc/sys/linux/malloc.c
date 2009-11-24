/* Malloc implementation for multiple threads without lock contention.
   Copyright (C) 1996-2001, 2002 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by Wolfram Gloger <wmglo@dent.med.uni-muenchen.de>
   and Doug Lea <dl@cs.oswego.edu>, 1996.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
   02111-1307 USA.  */

/* $Id: malloc.c,v 1.2 2003/06/20 23:57:47 jjohnstn Exp $

  This work is mainly derived from malloc-2.6.4 by Doug Lea
  <dl@cs.oswego.edu>, which is available from:

                 ftp://g.oswego.edu/pub/misc/malloc.c

  Most of the original comments are reproduced in the code below.

* Why use this malloc?

  This is not the fastest, most space-conserving, most portable, or
  most tunable malloc ever written. However it is among the fastest
  while also being among the most space-conserving, portable and tunable.
  Consistent balance across these factors results in a good general-purpose
  allocator. For a high-level description, see
     http://g.oswego.edu/dl/html/malloc.html

  On many systems, the standard malloc implementation is by itself not
  thread-safe, and therefore wrapped with a single global lock around
  all malloc-related functions.  In some applications, especially with
  multiple available processors, this can lead to contention problems
  and bad performance.  This malloc version was designed with the goal
  to avoid waiting for locks as much as possible.  Statistics indicate
  that this goal is achieved in many cases.

* Synopsis of public routines

  (Much fuller descriptions are contained in the program documentation below.)

  ptmalloc_init();
     Initialize global configuration.  When compiled for multiple threads,
     this function must be called once before any other function in the
     package.  It is not required otherwise.  It is called automatically
     in the Linux/GNU C libray or when compiling with MALLOC_HOOKS.
  malloc(size_t n);
     Return a pointer to a newly allocated chunk of at least n bytes, or null
     if no space is available.
  free(Void_t* p);
     Release the chunk of memory pointed to by p, or no effect if p is null.
  realloc(Void_t* p, size_t n);
     Return a pointer to a chunk of size n that contains the same data
     as does chunk p up to the minimum of (n, p's size) bytes, or null
     if no space is available. The returned pointer may or may not be
     the same as p. If p is null, equivalent to malloc.  Unless the
     #define REALLOC_ZERO_BYTES_FREES below is set, realloc with a
     size argument of zero (re)allocates a minimum-sized chunk.
  memalign(size_t alignment, size_t n);
     Return a pointer to a newly allocated chunk of n bytes, aligned
     in accord with the alignment argument, which must be a power of
     two.
  valloc(size_t n);
     Equivalent to memalign(pagesize, n), where pagesize is the page
     size of the system (or as near to this as can be figured out from
     all the includes/defines below.)
  pvalloc(size_t n);
     Equivalent to valloc(minimum-page-that-holds(n)), that is,
     round up n to nearest pagesize.
  calloc(size_t unit, size_t quantity);
     Returns a pointer to quantity * unit bytes, with all locations
     set to zero.
  cfree(Void_t* p);
     Equivalent to free(p).
  malloc_trim(size_t pad);
     Release all but pad bytes of freed top-most memory back
     to the system. Return 1 if successful, else 0.
  malloc_usable_size(Void_t* p);
     Report the number usable allocated bytes associated with allocated
     chunk p. This may or may not report more bytes than were requested,
     due to alignment and minimum size constraints.
  malloc_stats();
     Prints brief summary statistics on stderr.
  mallinfo()
     Returns (by copy) a struct containing various summary statistics.
  mallopt(int parameter_number, int parameter_value)
     Changes one of the tunable parameters described below. Returns
     1 if successful in changing the parameter, else 0.

* Vital statistics:

  Alignment:                            8-byte
       8 byte alignment is currently hardwired into the design.  This
       seems to suffice for all current machines and C compilers.

  Assumed pointer representation:       4 or 8 bytes
       Code for 8-byte pointers is untested by me but has worked
       reliably by Wolfram Gloger, who contributed most of the
       changes supporting this.

  Assumed size_t  representation:       4 or 8 bytes
       Note that size_t is allowed to be 4 bytes even if pointers are 8.

  Minimum overhead per allocated chunk: 4 or 8 bytes
       Each malloced chunk has a hidden overhead of 4 bytes holding size
       and status information.

  Minimum allocated size: 4-byte ptrs:  16 bytes    (including 4 overhead)
                          8-byte ptrs:  24/32 bytes (including, 4/8 overhead)

       When a chunk is freed, 12 (for 4byte ptrs) or 20 (for 8 byte
       ptrs but 4 byte size) or 24 (for 8/8) additional bytes are
       needed; 4 (8) for a trailing size field
       and 8 (16) bytes for free list pointers. Thus, the minimum
       allocatable size is 16/24/32 bytes.

       Even a request for zero bytes (i.e., malloc(0)) returns a
       pointer to something of the minimum allocatable size.

  Maximum allocated size: 4-byte size_t: 2^31 -  8 bytes
                          8-byte size_t: 2^63 - 16 bytes

       It is assumed that (possibly signed) size_t bit values suffice to
       represent chunk sizes. `Possibly signed' is due to the fact
       that `size_t' may be defined on a system as either a signed or
       an unsigned type. To be conservative, values that would appear
       as negative numbers are avoided.
       Requests for sizes with a negative sign bit will return a
       minimum-sized chunk.

  Maximum overhead wastage per allocated chunk: normally 15 bytes

       Alignment demands, plus the minimum allocatable size restriction
       make the normal worst-case wastage 15 bytes (i.e., up to 15
       more bytes will be allocated than were requested in malloc), with
       two exceptions:
         1. Because requests for zero bytes allocate non-zero space,
            the worst case wastage for a request of zero bytes is 24 bytes.
         2. For requests >= mmap_threshold that are serviced via
            mmap(), the worst case wastage is 8 bytes plus the remainder
            from a system page (the minimal mmap unit); typically 4096 bytes.

* Limitations

    Here are some features that are NOT currently supported

    * No automated mechanism for fully checking that all accesses
      to malloced memory stay within their bounds.
    * No support for compaction.

* Synopsis of compile-time options:

    People have reported using previous versions of this malloc on all
    versions of Unix, sometimes by tweaking some of the defines
    below. It has been tested most extensively on Solaris and
    Linux. People have also reported adapting this malloc for use in
    stand-alone embedded systems.

    The implementation is in straight, hand-tuned ANSI C.  Among other
    consequences, it uses a lot of macros.  Because of this, to be at
    all usable, this code should be compiled using an optimizing compiler
    (for example gcc -O2) that can simplify expressions and control
    paths.

  __STD_C                  (default: derived from C compiler defines)
     Nonzero if using ANSI-standard C compiler, a C++ compiler, or
     a C compiler sufficiently close to ANSI to get away with it.
  MALLOC_DEBUG             (default: NOT defined)
     Define to enable debugging. Adds fairly extensive assertion-based
     checking to help track down memory errors, but noticeably slows down
     execution.
  MALLOC_HOOKS             (default: NOT defined)
     Define to enable support run-time replacement of the allocation
     functions through user-defined `hooks'.
  REALLOC_ZERO_BYTES_FREES (default: defined)
     Define this if you think that realloc(p, 0) should be equivalent
     to free(p).  (The C standard requires this behaviour, therefore
     it is the default.)  Otherwise, since malloc returns a unique
     pointer for malloc(0), so does realloc(p, 0).
  HAVE_MEMCPY               (default: defined)
     Define if you are not otherwise using ANSI STD C, but still
     have memcpy and memset in your C library and want to use them.
     Otherwise, simple internal versions are supplied.
  USE_MEMCPY               (default: 1 if HAVE_MEMCPY is defined, 0 otherwise)
     Define as 1 if you want the C library versions of memset and
     memcpy called in realloc and calloc (otherwise macro versions are used).
     At least on some platforms, the simple macro versions usually
     outperform libc versions.
  HAVE_MMAP                 (default: defined as 1)
     Define to non-zero to optionally make malloc() use mmap() to
     allocate very large blocks.
  HAVE_MREMAP                 (default: defined as 0 unless Linux libc set)
     Define to non-zero to optionally make realloc() use mremap() to
     reallocate very large blocks.
  USE_ARENAS                (default: the same as HAVE_MMAP)
     Enable support for multiple arenas, allocated using mmap().
  malloc_getpagesize        (default: derived from system #includes)
     Either a constant or routine call returning the system page size.
  HAVE_USR_INCLUDE_MALLOC_H (default: NOT defined)
     Optionally define if you are on a system with a /usr/include/malloc.h
     that declares struct mallinfo. It is not at all necessary to
     define this even if you do, but will ensure consistency.
  INTERNAL_SIZE_T           (default: size_t)
     Define to a 32-bit type (probably `unsigned int') if you are on a
     64-bit machine, yet do not want or need to allow malloc requests of
     greater than 2^31 to be handled. This saves space, especially for
     very small chunks.
  _LIBC                     (default: NOT defined)
     Defined only when compiled as part of the Linux libc/glibc.
     Also note that there is some odd internal name-mangling via defines
     (for example, internally, `malloc' is named `mALLOc') needed
     when compiling in this case. These look funny but don't otherwise
     affect anything.
  LACKS_UNISTD_H            (default: undefined)
     Define this if your system does not have a <unistd.h>.
  MORECORE                  (default: sbrk)
     The name of the routine to call to obtain more memory from the system.
  MORECORE_FAILURE          (default: -1)
     The value returned upon failure of MORECORE.
  MORECORE_CLEARS           (default 1)
     The degree to which the routine mapped to MORECORE zeroes out
     memory: never (0), only for newly allocated space (1) or always
     (2).  The distinction between (1) and (2) is necessary because on
     some systems, if the application first decrements and then
     increments the break value, the contents of the reallocated space
     are unspecified.
  DEFAULT_TRIM_THRESHOLD
  DEFAULT_TOP_PAD
  DEFAULT_MMAP_THRESHOLD
  DEFAULT_MMAP_MAX
     Default values of tunable parameters (described in detail below)
     controlling interaction with host system routines (sbrk, mmap, etc).
     These values may also be changed dynamically via mallopt(). The
     preset defaults are those that give best performance for typical
     programs/systems.
  DEFAULT_CHECK_ACTION
     When the standard debugging hooks are in place, and a pointer is
     detected as corrupt, do nothing (0), print an error message (1),
     or call abort() (2).


*/

/*

* Compile-time options for multiple threads:

  USE_PTHREADS, USE_THR, USE_SPROC
     Define one of these as 1 to select the thread interface:
     POSIX threads, Solaris threads or SGI sproc's, respectively.
     If none of these is defined as non-zero, you get a `normal'
     malloc implementation which is not thread-safe.  Support for
     multiple threads requires HAVE_MMAP=1.  As an exception, when
     compiling for GNU libc, i.e. when _LIBC is defined, then none of
     the USE_... symbols have to be defined.

  HEAP_MIN_SIZE
  HEAP_MAX_SIZE
     When thread support is enabled, additional `heap's are created
     with mmap calls.  These are limited in size; HEAP_MIN_SIZE should
     be a multiple of the page size, while HEAP_MAX_SIZE must be a power
     of two for alignment reasons.  HEAP_MAX_SIZE should be at least
     twice as large as the mmap threshold.
  THREAD_STATS
     When this is defined as non-zero, some statistics on mutex locking
     are computed.

*/




/* Preliminaries */

#ifndef __STD_C
#if defined (__STDC__)
#define __STD_C     1
#else
#if __cplusplus
#define __STD_C     1
#else
#define __STD_C     0
#endif /*__cplusplus*/
#endif /*__STDC__*/
#endif /*__STD_C*/

#ifndef Void_t
#if __STD_C
#define Void_t      void
#else
#define Void_t      char
#endif
#endif /*Void_t*/

#define _GNU_SOURCE
#include <features.h>
#define _LIBC 1
#define NOT_IN_libc 1

#if __STD_C
# include <stddef.h>   /* for size_t */
# if defined _LIBC || defined MALLOC_HOOKS
#  include <stdlib.h>  /* for getenv(), abort() */
# endif
#else
# include <sys/types.h>
# if defined _LIBC || defined MALLOC_HOOKS
extern char* getenv();
# endif
#endif

/* newlib modifications */

#include <libc-symbols.h>
#include <sys/types.h>

extern void __pthread_initialize (void) __attribute__((weak));
extern void *__mmap (void *__addr, size_t __len, int __prot,
                     int __flags, int __fd, off_t __offset);
extern int __munmap (void *__addr, size_t __len);
extern void *__mremap (void *__addr, size_t __old_len, size_t __new_len,
                       int __may_move);
extern int __getpagesize (void);

#define __libc_enable_secure 1

/* Macros for handling mutexes and thread-specific data.  This is
   included early, because some thread-related header files (such as
   pthread.h) should be included before any others. */
#include <bits/libc-lock.h>
#include "thread-m.h"

void *(*__malloc_internal_tsd_get) (enum __libc_tsd_key_t) = NULL;
int (*__malloc_internal_tsd_set) (enum __libc_tsd_key_t,
                                       __const void *) = NULL;

weak_alias(__malloc_internal_tsd_get, __libc_internal_tsd_get)
weak_alias(__malloc_internal_tsd_set, __libc_internal_tsd_set)


#ifdef __cplusplus
extern "C" {
#endif

#include <errno.h>
#include <stdio.h>    /* needed for malloc_stats */


/*
  Compile-time options
*/


/*
    Debugging:

    Because freed chunks may be overwritten with link fields, this
    malloc will often die when freed memory is overwritten by user
    programs.  This can be very effective (albeit in an annoying way)
    in helping track down dangling pointers.

    If you compile with -DMALLOC_DEBUG, a number of assertion checks are
    enabled that will catch more memory errors. You probably won't be
    able to make much sense of the actual assertion errors, but they
    should help you locate incorrectly overwritten memory.  The
    checking is fairly extensive, and will slow down execution
    noticeably. Calling malloc_stats or mallinfo with MALLOC_DEBUG set will
    attempt to check every non-mmapped allocated and free chunk in the
    course of computing the summaries. (By nature, mmapped regions
    cannot be checked very much automatically.)

    Setting MALLOC_DEBUG may also be helpful if you are trying to modify
    this code. The assertions in the check routines spell out in more
    detail the assumptions and invariants underlying the algorithms.

*/

#if MALLOC_DEBUG
#include <assert.h>
#else
#define assert(x) ((void)0)
#endif


/*
  INTERNAL_SIZE_T is the word-size used for internal bookkeeping
  of chunk sizes. On a 64-bit machine, you can reduce malloc
  overhead by defining INTERNAL_SIZE_T to be a 32 bit `unsigned int'
  at the expense of not being able to handle requests greater than
  2^31. This limitation is hardly ever a concern; you are encouraged
  to set this. However, the default version is the same as size_t.
*/

#ifndef INTERNAL_SIZE_T
#define INTERNAL_SIZE_T size_t
#endif

/*
  REALLOC_ZERO_BYTES_FREES should be set if a call to realloc with
  zero bytes should be the same as a call to free.  The C standard
  requires this. Otherwise, since this malloc returns a unique pointer
  for malloc(0), so does realloc(p, 0).
*/


#define REALLOC_ZERO_BYTES_FREES


/*
  HAVE_MEMCPY should be defined if you are not otherwise using
  ANSI STD C, but still have memcpy and memset in your C library
  and want to use them in calloc and realloc. Otherwise simple
  macro versions are defined here.

  USE_MEMCPY should be defined as 1 if you actually want to
  have memset and memcpy called. People report that the macro
  versions are often enough faster than libc versions on many
  systems that it is better to use them.

*/

#define HAVE_MEMCPY 1

#ifndef USE_MEMCPY
#ifdef HAVE_MEMCPY
#define USE_MEMCPY 1
#else
#define USE_MEMCPY 0
#endif
#endif

#if (__STD_C || defined(HAVE_MEMCPY))

#if __STD_C
void* memset(void*, int, size_t);
void* memcpy(void*, const void*, size_t);
void* memmove(void*, const void*, size_t);
#else
Void_t* memset();
Void_t* memcpy();
Void_t* memmove();
#endif
#endif

/* The following macros are only invoked with (2n+1)-multiples of
   INTERNAL_SIZE_T units, with a positive integer n. This is exploited
   for fast inline execution when n is small.  If the regions to be
   copied do overlap, the destination lies always _below_ the source.  */

#if USE_MEMCPY

#define MALLOC_ZERO(charp, nbytes)                                            \
do {                                                                          \
  INTERNAL_SIZE_T mzsz = (nbytes);                                            \
  if(mzsz <= 9*sizeof(mzsz)) {                                                \
    INTERNAL_SIZE_T* mz = (INTERNAL_SIZE_T*) (charp);                         \
    if(mzsz >= 5*sizeof(mzsz)) {     *mz++ = 0;                               \
                                     *mz++ = 0;                               \
      if(mzsz >= 7*sizeof(mzsz)) {   *mz++ = 0;                               \
                                     *mz++ = 0;                               \
        if(mzsz >= 9*sizeof(mzsz)) { *mz++ = 0;                               \
                                     *mz++ = 0; }}}                           \
                                     *mz++ = 0;                               \
                                     *mz++ = 0;                               \
                                     *mz   = 0;                               \
  } else memset((charp), 0, mzsz);                                            \
} while(0)

/* If the regions overlap, dest is always _below_ src.  */

#define MALLOC_COPY(dest,src,nbytes,overlap)                                  \
do {                                                                          \
  INTERNAL_SIZE_T mcsz = (nbytes);                                            \
  if(mcsz <= 9*sizeof(mcsz)) {                                                \
    INTERNAL_SIZE_T* mcsrc = (INTERNAL_SIZE_T*) (src);                        \
    INTERNAL_SIZE_T* mcdst = (INTERNAL_SIZE_T*) (dest);                       \
    if(mcsz >= 5*sizeof(mcsz)) {     *mcdst++ = *mcsrc++;                     \
                                     *mcdst++ = *mcsrc++;                     \
      if(mcsz >= 7*sizeof(mcsz)) {   *mcdst++ = *mcsrc++;                     \
                                     *mcdst++ = *mcsrc++;                     \
        if(mcsz >= 9*sizeof(mcsz)) { *mcdst++ = *mcsrc++;                     \
                                     *mcdst++ = *mcsrc++; }}}                 \
                                     *mcdst++ = *mcsrc++;                     \
                                     *mcdst++ = *mcsrc++;                     \
                                     *mcdst   = *mcsrc  ;                     \
  } else if(overlap)                                                          \
    memmove(dest, src, mcsz);                                                 \
  else                                                                        \
    memcpy(dest, src, mcsz);                                                  \
} while(0)

#else /* !USE_MEMCPY */

/* Use Duff's device for good zeroing/copying performance. */

#define MALLOC_ZERO(charp, nbytes)                                            \
do {                                                                          \
  INTERNAL_SIZE_T* mzp = (INTERNAL_SIZE_T*)(charp);                           \
  long mctmp = (nbytes)/sizeof(INTERNAL_SIZE_T), mcn;                         \
  if (mctmp < 8) mcn = 0; else { mcn = (mctmp-1)/8; mctmp %= 8; }             \
  switch (mctmp) {                                                            \
    case 0: for(;;) { *mzp++ = 0;                                             \
    case 7:           *mzp++ = 0;                                             \
    case 6:           *mzp++ = 0;                                             \
    case 5:           *mzp++ = 0;                                             \
    case 4:           *mzp++ = 0;                                             \
    case 3:           *mzp++ = 0;                                             \
    case 2:           *mzp++ = 0;                                             \
    case 1:           *mzp++ = 0; if(mcn <= 0) break; mcn--; }                \
  }                                                                           \
} while(0)

/* If the regions overlap, dest is always _below_ src.  */

#define MALLOC_COPY(dest,src,nbytes,overlap)                                  \
do {                                                                          \
  INTERNAL_SIZE_T* mcsrc = (INTERNAL_SIZE_T*) src;                            \
  INTERNAL_SIZE_T* mcdst = (INTERNAL_SIZE_T*) dest;                           \
  long mctmp = (nbytes)/sizeof(INTERNAL_SIZE_T), mcn;                         \
  if (mctmp < 8) mcn = 0; else { mcn = (mctmp-1)/8; mctmp %= 8; }             \
  switch (mctmp) {                                                            \
    case 0: for(;;) { *mcdst++ = *mcsrc++;                                    \
    case 7:           *mcdst++ = *mcsrc++;                                    \
    case 6:           *mcdst++ = *mcsrc++;                                    \
    case 5:           *mcdst++ = *mcsrc++;                                    \
    case 4:           *mcdst++ = *mcsrc++;                                    \
    case 3:           *mcdst++ = *mcsrc++;                                    \
    case 2:           *mcdst++ = *mcsrc++;                                    \
    case 1:           *mcdst++ = *mcsrc++; if(mcn <= 0) break; mcn--; }       \
  }                                                                           \
} while(0)

#endif


#ifndef LACKS_UNISTD_H
#  include <unistd.h>
#endif

/*
  Define HAVE_MMAP to optionally make malloc() use mmap() to allocate
  very large blocks.  These will be returned to the operating system
  immediately after a free().  HAVE_MMAP is also a prerequisite to
  support multiple `arenas' (see USE_ARENAS below).
*/

#ifndef HAVE_MMAP
# ifdef _POSIX_MAPPED_FILES
#  define HAVE_MMAP 1
# endif
#endif

/*
  Define HAVE_MREMAP to make realloc() use mremap() to re-allocate
  large blocks.  This is currently only possible on Linux with
  kernel versions newer than 1.3.77.
*/

#ifndef HAVE_MREMAP
#define HAVE_MREMAP defined(__linux__)
#endif

/* Define USE_ARENAS to enable support for multiple `arenas'.  These
   are allocated using mmap(), are necessary for threads and
   occasionally useful to overcome address space limitations affecting
   sbrk(). */

#ifndef USE_ARENAS
#define USE_ARENAS HAVE_MMAP
#endif

#if HAVE_MMAP

#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

#if !defined(MAP_ANONYMOUS) && defined(MAP_ANON)
#define MAP_ANONYMOUS MAP_ANON
#endif
#if !defined(MAP_FAILED)
#define MAP_FAILED ((char*)-1)
#endif

#ifndef MAP_NORESERVE
# ifdef MAP_AUTORESRV
#  define MAP_NORESERVE MAP_AUTORESRV
# else
#  define MAP_NORESERVE 0
# endif
#endif

#endif /* HAVE_MMAP */

/*
  Access to system page size. To the extent possible, this malloc
  manages memory from the system in page-size units.

  The following mechanics for getpagesize were adapted from
  bsd/gnu getpagesize.h
*/

#ifndef malloc_getpagesize
#  ifdef _SC_PAGESIZE         /* some SVR4 systems omit an underscore */
#    ifndef _SC_PAGE_SIZE
#      define _SC_PAGE_SIZE _SC_PAGESIZE
#    endif
#  endif
#  ifdef _SC_PAGE_SIZE
#    define malloc_getpagesize sysconf(_SC_PAGE_SIZE)
#  else
#    if defined(BSD) || defined(DGUX) || defined(HAVE_GETPAGESIZE)
       extern size_t getpagesize();
#      define malloc_getpagesize getpagesize()
#    else
#      include <sys/param.h>
#      ifdef EXEC_PAGESIZE
#        define malloc_getpagesize EXEC_PAGESIZE
#      else
#        ifdef NBPG
#          ifndef CLSIZE
#            define malloc_getpagesize NBPG
#          else
#            define malloc_getpagesize (NBPG * CLSIZE)
#          endif
#        else
#          ifdef NBPC
#            define malloc_getpagesize NBPC
#          else
#            ifdef PAGESIZE
#              define malloc_getpagesize PAGESIZE
#            else
#              define malloc_getpagesize (4096) /* just guess */
#            endif
#          endif
#        endif
#      endif
#    endif
#  endif
#endif



/*

  This version of malloc supports the standard SVID/XPG mallinfo
  routine that returns a struct containing the same kind of
  information you can get from malloc_stats. It should work on
  any SVID/XPG compliant system that has a /usr/include/malloc.h
  defining struct mallinfo. (If you'd like to install such a thing
  yourself, cut out the preliminary declarations as described above
  and below and save them in a malloc.h file. But there's no
  compelling reason to bother to do this.)

  The main declaration needed is the mallinfo struct that is returned
  (by-copy) by mallinfo().  The SVID/XPG malloinfo struct contains a
  bunch of fields, most of which are not even meaningful in this
  version of malloc. Some of these fields are are instead filled by
  mallinfo() with other numbers that might possibly be of interest.

  HAVE_USR_INCLUDE_MALLOC_H should be set if you have a
  /usr/include/malloc.h file that includes a declaration of struct
  mallinfo.  If so, it is included; else an SVID2/XPG2 compliant
  version is declared below.  These must be precisely the same for
  mallinfo() to work.

*/

/* #define HAVE_USR_INCLUDE_MALLOC_H */

#if HAVE_USR_INCLUDE_MALLOC_H
# include "/usr/include/malloc.h"
#else
# ifdef _LIBC
#  include "malloc.h"
# else
#  include "ptmalloc.h"
# endif
#endif

#include <bp-checks.h>

#ifndef DEFAULT_TRIM_THRESHOLD
#define DEFAULT_TRIM_THRESHOLD (128 * 1024)
#endif

/*
    M_TRIM_THRESHOLD is the maximum amount of unused top-most memory
      to keep before releasing via malloc_trim in free().

      Automatic trimming is mainly useful in long-lived programs.
      Because trimming via sbrk can be slow on some systems, and can
      sometimes be wasteful (in cases where programs immediately
      afterward allocate more large chunks) the value should be high
      enough so that your overall system performance would improve by
      releasing.

      The trim threshold and the mmap control parameters (see below)
      can be traded off with one another. Trimming and mmapping are
      two different ways of releasing unused memory back to the
      system. Between these two, it is often possible to keep
      system-level demands of a long-lived program down to a bare
      minimum. For example, in one test suite of sessions measuring
      the XF86 X server on Linux, using a trim threshold of 128K and a
      mmap threshold of 192K led to near-minimal long term resource
      consumption.

      If you are using this malloc in a long-lived program, it should
      pay to experiment with these values.  As a rough guide, you
      might set to a value close to the average size of a process
      (program) running on your system.  Releasing this much memory
      would allow such a process to run in memory.  Generally, it's
      worth it to tune for trimming rather than memory mapping when a
      program undergoes phases where several large chunks are
      allocated and released in ways that can reuse each other's
      storage, perhaps mixed with phases where there are no such
      chunks at all.  And in well-behaved long-lived programs,
      controlling release of large blocks via trimming versus mapping
      is usually faster.

      However, in most programs, these parameters serve mainly as
      protection against the system-level effects of carrying around
      massive amounts of unneeded memory. Since frequent calls to
      sbrk, mmap, and munmap otherwise degrade performance, the default
      parameters are set to relatively high values that serve only as
      safeguards.

      The default trim value is high enough to cause trimming only in
      fairly extreme (by current memory consumption standards) cases.
      It must be greater than page size to have any useful effect.  To
      disable trimming completely, you can set to (unsigned long)(-1);


*/


#ifndef DEFAULT_TOP_PAD
#define DEFAULT_TOP_PAD        (0)
#endif

/*
    M_TOP_PAD is the amount of extra `padding' space to allocate or
      retain whenever sbrk is called. It is used in two ways internally:

      * When sbrk is called to extend the top of the arena to satisfy
        a new malloc request, this much padding is added to the sbrk
        request.

      * When malloc_trim is called automatically from free(),
        it is used as the `pad' argument.

      In both cases, the actual amount of padding is rounded
      so that the end of the arena is always a system page boundary.

      The main reason for using padding is to avoid calling sbrk so
      often. Having even a small pad greatly reduces the likelihood
      that nearly every malloc request during program start-up (or
      after trimming) will invoke sbrk, which needlessly wastes
      time.

      Automatic rounding-up to page-size units is normally sufficient
      to avoid measurable overhead, so the default is 0.  However, in
      systems where sbrk is relatively slow, it can pay to increase
      this value, at the expense of carrying around more memory than
      the program needs.

*/


#ifndef DEFAULT_MMAP_THRESHOLD
#define DEFAULT_MMAP_THRESHOLD (128 * 1024)
#endif

/*

    M_MMAP_THRESHOLD is the request size threshold for using mmap()
      to service a request. Requests of at least this size that cannot
      be allocated using already-existing space will be serviced via mmap.
      (If enough normal freed space already exists it is used instead.)

      Using mmap segregates relatively large chunks of memory so that
      they can be individually obtained and released from the host
      system. A request serviced through mmap is never reused by any
      other request (at least not directly; the system may just so
      happen to remap successive requests to the same locations).

      Segregating space in this way has the benefit that mmapped space
      can ALWAYS be individually released back to the system, which
      helps keep the system level memory demands of a long-lived
      program low. Mapped memory can never become `locked' between
      other chunks, as can happen with normally allocated chunks, which
      menas that even trimming via malloc_trim would not release them.

      However, it has the disadvantages that:

         1. The space cannot be reclaimed, consolidated, and then
            used to service later requests, as happens with normal chunks.
         2. It can lead to more wastage because of mmap page alignment
            requirements
         3. It causes malloc performance to be more dependent on host
            system memory management support routines which may vary in
            implementation quality and may impose arbitrary
            limitations. Generally, servicing a request via normal
            malloc steps is faster than going through a system's mmap.

      All together, these considerations should lead you to use mmap
      only for relatively large requests.


*/



#ifndef DEFAULT_MMAP_MAX
#if HAVE_MMAP
#define DEFAULT_MMAP_MAX       (1024)
#else
#define DEFAULT_MMAP_MAX       (0)
#endif
#endif

/*
    M_MMAP_MAX is the maximum number of requests to simultaneously
      service using mmap. This parameter exists because:

         1. Some systems have a limited number of internal tables for
            use by mmap.
         2. In most systems, overreliance on mmap can degrade overall
            performance.
         3. If a program allocates many large regions, it is probably
            better off using normal sbrk-based allocation routines that
            can reclaim and reallocate normal heap memory. Using a
            small value allows transition into this mode after the
            first few allocations.

      Setting to 0 disables all use of mmap.  If HAVE_MMAP is not set,
      the default value is 0, and attempts to set it to non-zero values
      in mallopt will fail.
*/



#ifndef DEFAULT_CHECK_ACTION
#define DEFAULT_CHECK_ACTION 1
#endif

/* What to do if the standard debugging hooks are in place and a
   corrupt pointer is detected: do nothing (0), print an error message
   (1), or call abort() (2). */



#define HEAP_MIN_SIZE (32*1024)
#define HEAP_MAX_SIZE (1024*1024) /* must be a power of two */

/* HEAP_MIN_SIZE and HEAP_MAX_SIZE limit the size of mmap()ed heaps
      that are dynamically created for multi-threaded programs.  The
      maximum size must be a power of two, for fast determination of
      which heap belongs to a chunk.  It should be much larger than
      the mmap threshold, so that requests with a size just below that
      threshold can be fulfilled without creating too many heaps.
*/



#ifndef THREAD_STATS
#define THREAD_STATS 0
#endif

/* If THREAD_STATS is non-zero, some statistics on mutex locking are
   computed. */


/* Macro to set errno.  */
#ifndef __set_errno
# define __set_errno(val) errno = (val)
#endif

/* On some platforms we can compile internal, not exported functions better.
   Let the environment provide a macro and define it to be empty if it
   is not available.  */
#ifndef internal_function
# define internal_function
#endif


/*

  Special defines for the Linux/GNU C library.

*/


#ifdef _LIBC

#if __STD_C

Void_t * __default_morecore (ptrdiff_t);
Void_t *(*__morecore)(ptrdiff_t) = __default_morecore;

#else

Void_t * __default_morecore ();
Void_t *(*__morecore)() = __default_morecore;

#endif

#define MORECORE (*__morecore)
#define MORECORE_FAILURE 0

#ifndef MORECORE_CLEARS
#define MORECORE_CLEARS 1
#endif

static size_t __libc_pagesize;

#define access	__access
#define mmap    __mmap
#define munmap  __munmap
#define mremap  __mremap
#define mprotect __mprotect
#undef malloc_getpagesize
#define malloc_getpagesize __libc_pagesize

#else /* _LIBC */

#if __STD_C
extern Void_t*     sbrk(ptrdiff_t);
#else
extern Void_t*     sbrk();
#endif

#ifndef MORECORE
#define MORECORE sbrk
#endif

#ifndef MORECORE_FAILURE
#define MORECORE_FAILURE -1
#endif

#ifndef MORECORE_CLEARS
#define MORECORE_CLEARS 1
#endif

#endif /* _LIBC */

#ifdef _LIBC

#define cALLOc          __libc_calloc
#define fREe            __libc_free
#define mALLOc          __libc_malloc
#define mEMALIGn        __libc_memalign
#define rEALLOc         __libc_realloc
#define vALLOc          __libc_valloc
#define pvALLOc         __libc_pvalloc
#define mALLINFo        __libc_mallinfo
#define mALLOPt         __libc_mallopt
#define mALLOC_STATs    __malloc_stats
#define mALLOC_USABLE_SIZe __malloc_usable_size
#define mALLOC_TRIm     __malloc_trim
#define mALLOC_GET_STATe __malloc_get_state
#define mALLOC_SET_STATe __malloc_set_state

#else

#define cALLOc          calloc
#define fREe            free
#define mALLOc          malloc
#define mEMALIGn        memalign
#define rEALLOc         realloc
#define vALLOc          valloc
#define pvALLOc         pvalloc
#define mALLINFo        mallinfo
#define mALLOPt         mallopt
#define mALLOC_STATs    malloc_stats
#define mALLOC_USABLE_SIZe malloc_usable_size
#define mALLOC_TRIm     malloc_trim
#define mALLOC_GET_STATe malloc_get_state
#define mALLOC_SET_STATe malloc_set_state

#endif

/* Public routines */

#if __STD_C

#ifndef _LIBC
void    ptmalloc_init(void);
#endif
Void_t* mALLOc(size_t);
void    fREe(Void_t*);
Void_t* rEALLOc(Void_t*, size_t);
Void_t* mEMALIGn(size_t, size_t);
Void_t* vALLOc(size_t);
Void_t* pvALLOc(size_t);
Void_t* cALLOc(size_t, size_t);
void    cfree(Void_t*);
int     mALLOC_TRIm(size_t);
size_t  mALLOC_USABLE_SIZe(Void_t*);
void    mALLOC_STATs(void);
int     mALLOPt(int, int);
struct mallinfo mALLINFo(void);
Void_t* mALLOC_GET_STATe(void);
int     mALLOC_SET_STATe(Void_t*);

#else /* !__STD_C */

#ifndef _LIBC
void    ptmalloc_init();
#endif
Void_t* mALLOc();
void    fREe();
Void_t* rEALLOc();
Void_t* mEMALIGn();
Void_t* vALLOc();
Void_t* pvALLOc();
Void_t* cALLOc();
void    cfree();
int     mALLOC_TRIm();
size_t  mALLOC_USABLE_SIZe();
void    mALLOC_STATs();
int     mALLOPt();
struct mallinfo mALLINFo();
Void_t* mALLOC_GET_STATe();
int     mALLOC_SET_STATe();

#endif /* __STD_C */


#ifdef __cplusplus
} /* end of extern "C" */
#endif

#if !defined(NO_THREADS) && !HAVE_MMAP
"Can't have threads support without mmap"
#endif
#if USE_ARENAS && !HAVE_MMAP
"Can't have multiple arenas without mmap"
#endif


/*
  Type declarations
*/


struct malloc_chunk
{
  INTERNAL_SIZE_T prev_size; /* Size of previous chunk (if free). */
  INTERNAL_SIZE_T size;      /* Size in bytes, including overhead. */
  struct malloc_chunk* fd;   /* double links -- used only if free. */
  struct malloc_chunk* bk;
};

typedef struct malloc_chunk* mchunkptr;

/*

   malloc_chunk details:

    (The following includes lightly edited explanations by Colin Plumb.)

    Chunks of memory are maintained using a `boundary tag' method as
    described in e.g., Knuth or Standish.  (See the paper by Paul
    Wilson ftp://ftp.cs.utexas.edu/pub/garbage/allocsrv.ps for a
    survey of such techniques.)  Sizes of free chunks are stored both
    in the front of each chunk and at the end.  This makes
    consolidating fragmented chunks into bigger chunks very fast.  The
    size fields also hold bits representing whether chunks are free or
    in use.

    An allocated chunk looks like this:


    chunk-> +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
            |             Size of previous chunk, if allocated            | |
            +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
            |             Size of chunk, in bytes                         |P|
      mem-> +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
            |             User data starts here...                          .
            .                                                               .
            .             (malloc_usable_space() bytes)                     .
            .                                                               |
nextchunk-> +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
            |             Size of chunk                                     |
            +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


    Where "chunk" is the front of the chunk for the purpose of most of
    the malloc code, but "mem" is the pointer that is returned to the
    user.  "Nextchunk" is the beginning of the next contiguous chunk.

    Chunks always begin on even word boundaries, so the mem portion
    (which is returned to the user) is also on an even word boundary, and
    thus double-word aligned.

    Free chunks are stored in circular doubly-linked lists, and look like this:

    chunk-> +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
            |             Size of previous chunk                            |
            +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    `head:' |             Size of chunk, in bytes                         |P|
      mem-> +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
            |             Forward pointer to next chunk in list             |
            +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
            |             Back pointer to previous chunk in list            |
            +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
            |             Unused space (may be 0 bytes long)                .
            .                                                               .
            .                                                               |
nextchunk-> +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    `foot:' |             Size of chunk, in bytes                           |
            +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

    The P (PREV_INUSE) bit, stored in the unused low-order bit of the
    chunk size (which is always a multiple of two words), is an in-use
    bit for the *previous* chunk.  If that bit is *clear*, then the
    word before the current chunk size contains the previous chunk
    size, and can be used to find the front of the previous chunk.
    (The very first chunk allocated always has this bit set,
    preventing access to non-existent (or non-owned) memory.)

    Note that the `foot' of the current chunk is actually represented
    as the prev_size of the NEXT chunk. (This makes it easier to
    deal with alignments etc).

    The two exceptions to all this are

     1. The special chunk `top', which doesn't bother using the
        trailing size field since there is no
        next contiguous chunk that would have to index off it. (After
        initialization, `top' is forced to always exist.  If it would
        become less than MINSIZE bytes long, it is replenished via
        malloc_extend_top.)

     2. Chunks allocated via mmap, which have the second-lowest-order
        bit (IS_MMAPPED) set in their size fields.  Because they are
        never merged or traversed from any other chunk, they have no
        foot size or inuse information.

    Available chunks are kept in any of several places (all declared below):

    * `av': An array of chunks serving as bin headers for consolidated
       chunks. Each bin is doubly linked.  The bins are approximately
       proportionally (log) spaced.  There are a lot of these bins
       (128). This may look excessive, but works very well in
       practice.  All procedures maintain the invariant that no
       consolidated chunk physically borders another one. Chunks in
       bins are kept in size order, with ties going to the
       approximately least recently used chunk.

       The chunks in each bin are maintained in decreasing sorted order by
       size.  This is irrelevant for the small bins, which all contain
       the same-sized chunks, but facilitates best-fit allocation for
       larger chunks. (These lists are just sequential. Keeping them in
       order almost never requires enough traversal to warrant using
       fancier ordered data structures.)  Chunks of the same size are
       linked with the most recently freed at the front, and allocations
       are taken from the back.  This results in LRU or FIFO allocation
       order, which tends to give each chunk an equal opportunity to be
       consolidated with adjacent freed chunks, resulting in larger free
       chunks and less fragmentation.

    * `top': The top-most available chunk (i.e., the one bordering the
       end of available memory) is treated specially. It is never
       included in any bin, is used only if no other chunk is
       available, and is released back to the system if it is very
       large (see M_TRIM_THRESHOLD).

    * `last_remainder': A bin holding only the remainder of the
       most recently split (non-top) chunk. This bin is checked
       before other non-fitting chunks, so as to provide better
       locality for runs of sequentially allocated chunks.

    *  Implicitly, through the host system's memory mapping tables.
       If supported, requests greater than a threshold are usually
       serviced via calls to mmap, and then later released via munmap.

*/

/*
   Bins

    The bins are an array of pairs of pointers serving as the
    heads of (initially empty) doubly-linked lists of chunks, laid out
    in a way so that each pair can be treated as if it were in a
    malloc_chunk. (This way, the fd/bk offsets for linking bin heads
    and chunks are the same).

    Bins for sizes < 512 bytes contain chunks of all the same size, spaced
    8 bytes apart. Larger bins are approximately logarithmically
    spaced. (See the table below.)

    Bin layout:

    64 bins of size       8
    32 bins of size      64
    16 bins of size     512
     8 bins of size    4096
     4 bins of size   32768
     2 bins of size  262144
     1 bin  of size what's left

    There is actually a little bit of slop in the numbers in bin_index
    for the sake of speed. This makes no difference elsewhere.

    The special chunks `top' and `last_remainder' get their own bins,
    (this is implemented via yet more trickery with the av array),
    although `top' is never properly linked to its bin since it is
    always handled specially.

*/

#define NAV             128   /* number of bins */

typedef struct malloc_chunk* mbinptr;

/* An arena is a configuration of malloc_chunks together with an array
   of bins.  With multiple threads, it must be locked via a mutex
   before changing its data structures.  One or more `heaps' are
   associated with each arena, except for the main_arena, which is
   associated only with the `main heap', i.e.  the conventional free
   store obtained with calls to MORECORE() (usually sbrk).  The `av'
   array is never mentioned directly in the code, but instead used via
   bin access macros. */

typedef struct _arena {
  mbinptr av[2*NAV + 2];
  struct _arena *next;
  size_t size;
#if THREAD_STATS
  long stat_lock_direct, stat_lock_loop, stat_lock_wait;
#endif
  mutex_t mutex;
} arena;


/* A heap is a single contiguous memory region holding (coalesceable)
   malloc_chunks.  It is allocated with mmap() and always starts at an
   address aligned to HEAP_MAX_SIZE.  Not used unless compiling with
   USE_ARENAS. */

typedef struct _heap_info {
  arena *ar_ptr; /* Arena for this heap. */
  struct _heap_info *prev; /* Previous heap. */
  size_t size;   /* Current size in bytes. */
  size_t pad;    /* Make sure the following data is properly aligned. */
} heap_info;


/*
  Static functions (forward declarations)
*/

#if __STD_C

static void      chunk_free(arena *ar_ptr, mchunkptr p) internal_function;
static mchunkptr chunk_alloc(arena *ar_ptr, INTERNAL_SIZE_T size)
     internal_function;
static mchunkptr chunk_realloc(arena *ar_ptr, mchunkptr oldp,
                               INTERNAL_SIZE_T oldsize, INTERNAL_SIZE_T nb)
     internal_function;
static mchunkptr chunk_align(arena *ar_ptr, INTERNAL_SIZE_T nb,
                             size_t alignment) internal_function;
static int       main_trim(size_t pad) internal_function;
#if USE_ARENAS
static int       heap_trim(heap_info *heap, size_t pad) internal_function;
#endif
#if defined _LIBC || defined MALLOC_HOOKS
static Void_t*   malloc_check(size_t sz, const Void_t *caller);
static void      free_check(Void_t* mem, const Void_t *caller);
static Void_t*   realloc_check(Void_t* oldmem, size_t bytes,
			       const Void_t *caller);
static Void_t*   memalign_check(size_t alignment, size_t bytes,
				const Void_t *caller);
#ifndef NO_THREADS
static Void_t*   malloc_starter(size_t sz, const Void_t *caller);
static void      free_starter(Void_t* mem, const Void_t *caller);
static Void_t*   malloc_atfork(size_t sz, const Void_t *caller);
static void      free_atfork(Void_t* mem, const Void_t *caller);
#endif
#endif

#else

static void      chunk_free();
static mchunkptr chunk_alloc();
static mchunkptr chunk_realloc();
static mchunkptr chunk_align();
static int       main_trim();
#if USE_ARENAS
static int       heap_trim();
#endif
#if defined _LIBC || defined MALLOC_HOOKS
static Void_t*   malloc_check();
static void      free_check();
static Void_t*   realloc_check();
static Void_t*   memalign_check();
#ifndef NO_THREADS
static Void_t*   malloc_starter();
static void      free_starter();
static Void_t*   malloc_atfork();
static void      free_atfork();
#endif
#endif

#endif



/* sizes, alignments */

#define SIZE_SZ                (sizeof(INTERNAL_SIZE_T))
/* Allow the default to be overwritten on the compiler command line.  */
#ifndef MALLOC_ALIGNMENT
# define MALLOC_ALIGNMENT      (SIZE_SZ + SIZE_SZ)
#endif
#define MALLOC_ALIGN_MASK      (MALLOC_ALIGNMENT - 1)
#define MINSIZE                (sizeof(struct malloc_chunk))

/* conversion from malloc headers to user pointers, and back */

#define chunk2mem(p) ((Void_t*)((char*)(p) + 2*SIZE_SZ))
#define mem2chunk(mem) chunk_at_offset((mem), -2*SIZE_SZ)

/* pad request bytes into a usable size, return non-zero on overflow */

#define request2size(req, nb) \
 ((nb = (req) + (SIZE_SZ + MALLOC_ALIGN_MASK)),\
  ((long)nb <= 0 || nb < (INTERNAL_SIZE_T) (req) \
   ? (__set_errno (ENOMEM), 1) \
   : ((nb < (MINSIZE + MALLOC_ALIGN_MASK) \
	   ? (nb = MINSIZE) : (nb &= ~MALLOC_ALIGN_MASK)), 0)))

/* Check if m has acceptable alignment */

#define aligned_OK(m)    (((unsigned long)((m)) & (MALLOC_ALIGN_MASK)) == 0)




/*
  Physical chunk operations
*/


/* size field is or'ed with PREV_INUSE when previous adjacent chunk in use */

#define PREV_INUSE 0x1UL

/* size field is or'ed with IS_MMAPPED if the chunk was obtained with mmap() */

#define IS_MMAPPED 0x2UL

/* Bits to mask off when extracting size */

#define SIZE_BITS (PREV_INUSE|IS_MMAPPED)


/* Ptr to next physical malloc_chunk. */

#define next_chunk(p) chunk_at_offset((p), (p)->size & ~PREV_INUSE)

/* Ptr to previous physical malloc_chunk */

#define prev_chunk(p) chunk_at_offset((p), -(p)->prev_size)


/* Treat space at ptr + offset as a chunk */

#define chunk_at_offset(p, s)  BOUNDED_1((mchunkptr)(((char*)(p)) + (s)))




/*
  Dealing with use bits
*/

/* extract p's inuse bit */

#define inuse(p) (next_chunk(p)->size & PREV_INUSE)

/* extract inuse bit of previous chunk */

#define prev_inuse(p)  ((p)->size & PREV_INUSE)

/* check for mmap()'ed chunk */

#define chunk_is_mmapped(p) ((p)->size & IS_MMAPPED)

/* set/clear chunk as in use without otherwise disturbing */

#define set_inuse(p) (next_chunk(p)->size |= PREV_INUSE)

#define clear_inuse(p) (next_chunk(p)->size &= ~PREV_INUSE)

/* check/set/clear inuse bits in known places */

#define inuse_bit_at_offset(p, s) \
  (chunk_at_offset((p), (s))->size & PREV_INUSE)

#define set_inuse_bit_at_offset(p, s) \
  (chunk_at_offset((p), (s))->size |= PREV_INUSE)

#define clear_inuse_bit_at_offset(p, s) \
  (chunk_at_offset((p), (s))->size &= ~(PREV_INUSE))




/*
  Dealing with size fields
*/

/* Get size, ignoring use bits */

#define chunksize(p)          ((p)->size & ~(SIZE_BITS))

/* Set size at head, without disturbing its use bit */

#define set_head_size(p, s)   ((p)->size = (((p)->size & PREV_INUSE) | (s)))

/* Set size/use ignoring previous bits in header */

#define set_head(p, s)        ((p)->size = (s))

/* Set size at footer (only when chunk is not in use) */

#define set_foot(p, s)   (chunk_at_offset(p, s)->prev_size = (s))





/* access macros */

#define bin_at(a, i)   BOUNDED_1(_bin_at(a, i))
#define _bin_at(a, i)  ((mbinptr)((char*)&(((a)->av)[2*(i)+2]) - 2*SIZE_SZ))
#define init_bin(a, i) ((a)->av[2*(i)+2] = (a)->av[2*(i)+3] = bin_at((a), (i)))
#define next_bin(b)    ((mbinptr)((char*)(b) + 2 * sizeof(((arena*)0)->av[0])))
#define prev_bin(b)    ((mbinptr)((char*)(b) - 2 * sizeof(((arena*)0)->av[0])))

/*
   The first 2 bins are never indexed. The corresponding av cells are instead
   used for bookkeeping. This is not to save space, but to simplify
   indexing, maintain locality, and avoid some initialization tests.
*/

#define binblocks(a)      (bin_at(a,0)->size)/* bitvector of nonempty blocks */
#define top(a)            (bin_at(a,0)->fd)  /* The topmost chunk */
#define last_remainder(a) (bin_at(a,1))      /* remainder from last split */

/*
   Because top initially points to its own bin with initial
   zero size, thus forcing extension on the first malloc request,
   we avoid having any special code in malloc to check whether
   it even exists yet. But we still need to in malloc_extend_top.
*/

#define initial_top(a)    ((mchunkptr)bin_at(a, 0))



/* field-extraction macros */

#define first(b) ((b)->fd)
#define last(b)  ((b)->bk)

/*
  Indexing into bins
*/

#define bin_index(sz)                                                         \
(((((unsigned long)(sz)) >> 9) ==    0) ?       (((unsigned long)(sz)) >>  3):\
 ((((unsigned long)(sz)) >> 9) <=    4) ?  56 + (((unsigned long)(sz)) >>  6):\
 ((((unsigned long)(sz)) >> 9) <=   20) ?  91 + (((unsigned long)(sz)) >>  9):\
 ((((unsigned long)(sz)) >> 9) <=   84) ? 110 + (((unsigned long)(sz)) >> 12):\
 ((((unsigned long)(sz)) >> 9) <=  340) ? 119 + (((unsigned long)(sz)) >> 15):\
 ((((unsigned long)(sz)) >> 9) <= 1364) ? 124 + (((unsigned long)(sz)) >> 18):\
                                          126)
/*
  bins for chunks < 512 are all spaced 8 bytes apart, and hold
  identically sized chunks. This is exploited in malloc.
*/

#define MAX_SMALLBIN         63
#define MAX_SMALLBIN_SIZE   512
#define SMALLBIN_WIDTH        8

#define smallbin_index(sz)  (((unsigned long)(sz)) >> 3)

/*
   Requests are `small' if both the corresponding and the next bin are small
*/

#define is_small_request(nb) ((nb) < MAX_SMALLBIN_SIZE - SMALLBIN_WIDTH)



/*
    To help compensate for the large number of bins, a one-level index
    structure is used for bin-by-bin searching.  `binblocks' is a
    one-word bitvector recording whether groups of BINBLOCKWIDTH bins
    have any (possibly) non-empty bins, so they can be skipped over
    all at once during during traversals. The bits are NOT always
    cleared as soon as all bins in a block are empty, but instead only
    when all are noticed to be empty during traversal in malloc.
*/

#define BINBLOCKWIDTH     4   /* bins per block */

/* bin<->block macros */

#define idx2binblock(ix)      ((unsigned)1 << ((ix) / BINBLOCKWIDTH))
#define mark_binblock(a, ii)  (binblocks(a) |= idx2binblock(ii))
#define clear_binblock(a, ii) (binblocks(a) &= ~(idx2binblock(ii)))




/* Static bookkeeping data */

/* Helper macro to initialize bins */
#define IAV(i) _bin_at(&main_arena, i), _bin_at(&main_arena, i)

static arena main_arena = {
    {
 0, 0,
 IAV(0),   IAV(1),   IAV(2),   IAV(3),   IAV(4),   IAV(5),   IAV(6),   IAV(7),
 IAV(8),   IAV(9),   IAV(10),  IAV(11),  IAV(12),  IAV(13),  IAV(14),  IAV(15),
 IAV(16),  IAV(17),  IAV(18),  IAV(19),  IAV(20),  IAV(21),  IAV(22),  IAV(23),
 IAV(24),  IAV(25),  IAV(26),  IAV(27),  IAV(28),  IAV(29),  IAV(30),  IAV(31),
 IAV(32),  IAV(33),  IAV(34),  IAV(35),  IAV(36),  IAV(37),  IAV(38),  IAV(39),
 IAV(40),  IAV(41),  IAV(42),  IAV(43),  IAV(44),  IAV(45),  IAV(46),  IAV(47),
 IAV(48),  IAV(49),  IAV(50),  IAV(51),  IAV(52),  IAV(53),  IAV(54),  IAV(55),
 IAV(56),  IAV(57),  IAV(58),  IAV(59),  IAV(60),  IAV(61),  IAV(62),  IAV(63),
 IAV(64),  IAV(65),  IAV(66),  IAV(67),  IAV(68),  IAV(69),  IAV(70),  IAV(71),
 IAV(72),  IAV(73),  IAV(74),  IAV(75),  IAV(76),  IAV(77),  IAV(78),  IAV(79),
 IAV(80),  IAV(81),  IAV(82),  IAV(83),  IAV(84),  IAV(85),  IAV(86),  IAV(87),
 IAV(88),  IAV(89),  IAV(90),  IAV(91),  IAV(92),  IAV(93),  IAV(94),  IAV(95),
 IAV(96),  IAV(97),  IAV(98),  IAV(99),  IAV(100), IAV(101), IAV(102), IAV(103),
 IAV(104), IAV(105), IAV(106), IAV(107), IAV(108), IAV(109), IAV(110), IAV(111),
 IAV(112), IAV(113), IAV(114), IAV(115), IAV(116), IAV(117), IAV(118), IAV(119),
 IAV(120), IAV(121), IAV(122), IAV(123), IAV(124), IAV(125), IAV(126), IAV(127)
    },
    &main_arena, /* next */
    0, /* size */
#if THREAD_STATS
    0, 0, 0, /* stat_lock_direct, stat_lock_loop, stat_lock_wait */
#endif
    MUTEX_INITIALIZER /* mutex */
};

#undef IAV

/* Thread specific data */

static tsd_key_t arena_key;
static mutex_t list_lock = MUTEX_INITIALIZER;

#if THREAD_STATS
static int stat_n_heaps;
#define THREAD_STAT(x) x
#else
#define THREAD_STAT(x) do ; while(0)
#endif

/* variables holding tunable values */

static unsigned long trim_threshold   = DEFAULT_TRIM_THRESHOLD;
static unsigned long top_pad          = DEFAULT_TOP_PAD;
static unsigned int  n_mmaps_max      = DEFAULT_MMAP_MAX;
static unsigned long mmap_threshold   = DEFAULT_MMAP_THRESHOLD;
static int           check_action     = DEFAULT_CHECK_ACTION;

/* The first value returned from sbrk */
static char* sbrk_base = (char*)(-1);

/* The maximum memory obtained from system via sbrk */
static unsigned long max_sbrked_mem;

/* The maximum via either sbrk or mmap (too difficult to track with threads) */
#ifdef NO_THREADS
static unsigned long max_total_mem;
#endif

/* The total memory obtained from system via sbrk */
#define sbrked_mem (main_arena.size)

/* Tracking mmaps */

static unsigned int n_mmaps;
static unsigned int max_n_mmaps;
static unsigned long mmapped_mem;
static unsigned long max_mmapped_mem;

/* Mapped memory in non-main arenas (reliable only for NO_THREADS). */
static unsigned long arena_mem;



#ifndef _LIBC
#define weak_variable
#else
/* In GNU libc we want the hook variables to be weak definitions to
   avoid a problem with Emacs.  */
#define weak_variable weak_function
#endif

/* Already initialized? */
int __malloc_initialized = -1;


#ifndef NO_THREADS

/* Magic value for the thread-specific arena pointer when
   malloc_atfork() is in use.  */

#define ATFORK_ARENA_PTR ((Void_t*)-1)

/* The following two functions are registered via thread_atfork() to
   make sure that the mutexes remain in a consistent state in the
   fork()ed version of a thread.  Also adapt the malloc and free hooks
   temporarily, because the `atfork' handler mechanism may use
   malloc/free internally (e.g. in LinuxThreads). */

#if defined _LIBC || defined MALLOC_HOOKS
static __malloc_ptr_t (*save_malloc_hook) __MALLOC_P ((size_t __size,
						       const __malloc_ptr_t));
static void           (*save_free_hook) __MALLOC_P ((__malloc_ptr_t __ptr,
						     const __malloc_ptr_t));
static Void_t*        save_arena;
#endif

static void
ptmalloc_lock_all __MALLOC_P((void))
{
  arena *ar_ptr;

  (void)mutex_lock(&list_lock);
  for(ar_ptr = &main_arena;;) {
    (void)mutex_lock(&ar_ptr->mutex);
    ar_ptr = ar_ptr->next;
    if(ar_ptr == &main_arena) break;
  }
#if defined _LIBC || defined MALLOC_HOOKS
  save_malloc_hook = __malloc_hook;
  save_free_hook = __free_hook;
  __malloc_hook = malloc_atfork;
  __free_hook = free_atfork;
  /* Only the current thread may perform malloc/free calls now. */
  tsd_getspecific(arena_key, save_arena);
  tsd_setspecific(arena_key, ATFORK_ARENA_PTR);
#endif
}

static void
ptmalloc_unlock_all __MALLOC_P((void))
{
  arena *ar_ptr;

#if defined _LIBC || defined MALLOC_HOOKS
  tsd_setspecific(arena_key, save_arena);
  __malloc_hook = save_malloc_hook;
  __free_hook = save_free_hook;
#endif
  for(ar_ptr = &main_arena;;) {
    (void)mutex_unlock(&ar_ptr->mutex);
    ar_ptr = ar_ptr->next;
    if(ar_ptr == &main_arena) break;
  }
  (void)mutex_unlock(&list_lock);
}

static void
ptmalloc_init_all __MALLOC_P((void))
{
  arena *ar_ptr;

#if defined _LIBC || defined MALLOC_HOOKS
  tsd_setspecific(arena_key, save_arena);
  __malloc_hook = save_malloc_hook;
  __free_hook = save_free_hook;
#endif
  for(ar_ptr = &main_arena;;) {
    (void)mutex_init(&ar_ptr->mutex);
    ar_ptr = ar_ptr->next;
    if(ar_ptr == &main_arena) break;
  }
  (void)mutex_init(&list_lock);
}

#endif /* !defined NO_THREADS */

/* Initialization routine. */
#if defined(_LIBC)
#if 0
static void ptmalloc_init __MALLOC_P ((void)) __attribute__ ((constructor));
#endif

#ifdef _LIBC
#include <string.h>
extern char **environ;

static char *
internal_function
next_env_entry (char ***position)
{
  char **current = *position;
  char *result = NULL;

  while (*current != NULL)
    {
      if (__builtin_expect ((*current)[0] == 'M', 0)
	  && (*current)[1] == 'A'
	  && (*current)[2] == 'L'
	  && (*current)[3] == 'L'
	  && (*current)[4] == 'O'
	  && (*current)[5] == 'C'
	  && (*current)[6] == '_')
	{
	  result = &(*current)[7];

	  /* Save current position for next visit.  */
	  *position = ++current;

	  break;
	}

      ++current;
    }

  return result;
}
#endif

static void
ptmalloc_init __MALLOC_P((void))
#else
void
ptmalloc_init __MALLOC_P((void))
#endif
{
#if defined _LIBC || defined MALLOC_HOOKS
# if __STD_C
  const char* s;
# else
  char* s;
# endif
#endif
  int secure;

  if(__malloc_initialized >= 0) return;
  __malloc_initialized = 0;
#ifdef _LIBC
  __libc_pagesize = __getpagesize();
#endif
#ifndef NO_THREADS
#if defined _LIBC || defined MALLOC_HOOKS
  /* With some threads implementations, creating thread-specific data
     or initializing a mutex may call malloc() itself.  Provide a
     simple starter version (realloc() won't work). */
  save_malloc_hook = __malloc_hook;
  save_free_hook = __free_hook;
  __malloc_hook = malloc_starter;
  __free_hook = free_starter;
#endif
#ifdef _LIBC
  /* Initialize the pthreads interface. */
  if (__pthread_initialize != NULL)
    __pthread_initialize();
#endif
#endif /* !defined NO_THREADS */
  mutex_init(&main_arena.mutex);
  mutex_init(&list_lock);
  tsd_key_create(&arena_key, NULL);
  tsd_setspecific(arena_key, (Void_t *)&main_arena);
  thread_atfork(ptmalloc_lock_all, ptmalloc_unlock_all, ptmalloc_init_all);
#if defined _LIBC || defined MALLOC_HOOKS
#ifndef NO_THREADS
  __malloc_hook = save_malloc_hook;
  __free_hook = save_free_hook;
#endif
  secure = __libc_enable_secure;
#ifdef _LIBC
  s = NULL;
  if (environ != NULL)
    {
      char **runp = environ;
      char *envline;

      while (__builtin_expect ((envline = next_env_entry (&runp)) != NULL, 0))
	{
	  size_t len = strcspn (envline, "=");

	  if (envline[len] != '=')
	    /* This is a "MALLOC_" variable at the end of the string
	       without a '=' character.  Ignore it since otherwise we
	       will access invalid memory below.  */
	    continue;

	  switch (len)
	    {
	    case 6:
	      if (memcmp (envline, "CHECK_", 6) == 0)
		s = &envline[7];
	      break;
	    case 8:
	      if (! secure && memcmp (envline, "TOP_PAD_", 8) == 0)
		mALLOPt(M_TOP_PAD, atoi(&envline[9]));
	      break;
	    case 9:
	      if (! secure && memcmp (envline, "MMAP_MAX_", 9) == 0)
		mALLOPt(M_MMAP_MAX, atoi(&envline[10]));
	      break;
	    case 15:
	      if (! secure)
		{
		  if (memcmp (envline, "TRIM_THRESHOLD_", 15) == 0)
		    mALLOPt(M_TRIM_THRESHOLD, atoi(&envline[16]));
		  else if (memcmp (envline, "MMAP_THRESHOLD_", 15) == 0)
		    mALLOPt(M_MMAP_THRESHOLD, atoi(&envline[16]));
		}
	      break;
	    default:
	      break;
	    }
	}
    }
#else
  if (! secure)
    {
      if((s = getenv("MALLOC_TRIM_THRESHOLD_")))
	mALLOPt(M_TRIM_THRESHOLD, atoi(s));
      if((s = getenv("MALLOC_TOP_PAD_")))
	mALLOPt(M_TOP_PAD, atoi(s));
      if((s = getenv("MALLOC_MMAP_THRESHOLD_")))
	mALLOPt(M_MMAP_THRESHOLD, atoi(s));
      if((s = getenv("MALLOC_MMAP_MAX_")))
	mALLOPt(M_MMAP_MAX, atoi(s));
    }
  s = getenv("MALLOC_CHECK_");
#endif
  if(s) {
    if(s[0]) mALLOPt(M_CHECK_ACTION, (int)(s[0] - '0'));
    __malloc_check_init();
  }
  if(__malloc_initialize_hook != NULL)
    (*__malloc_initialize_hook)();
#endif
  __malloc_initialized = 1;
}

/* There are platforms (e.g. Hurd) with a link-time hook mechanism. */
#ifdef thread_atfork_static
thread_atfork_static(ptmalloc_lock_all, ptmalloc_unlock_all, \
                     ptmalloc_init_all)
#endif

#if defined _LIBC || defined MALLOC_HOOKS

/* Hooks for debugging versions.  The initial hooks just call the
   initialization routine, then do the normal work. */

static Void_t*
#if __STD_C
malloc_hook_ini(size_t sz, const __malloc_ptr_t caller)
#else
malloc_hook_ini(sz, caller)
     size_t sz; const __malloc_ptr_t caller;
#endif
{
  __malloc_hook = NULL;
  ptmalloc_init();
  return mALLOc(sz);
}

static Void_t*
#if __STD_C
realloc_hook_ini(Void_t* ptr, size_t sz, const __malloc_ptr_t caller)
#else
realloc_hook_ini(ptr, sz, caller)
     Void_t* ptr; size_t sz; const __malloc_ptr_t caller;
#endif
{
  __malloc_hook = NULL;
  __realloc_hook = NULL;
  ptmalloc_init();
  return rEALLOc(ptr, sz);
}

static Void_t*
#if __STD_C
memalign_hook_ini(size_t alignment, size_t sz, const __malloc_ptr_t caller)
#else
memalign_hook_ini(alignment, sz, caller)
     size_t alignment; size_t sz; const __malloc_ptr_t caller;
#endif
{
  __memalign_hook = NULL;
  ptmalloc_init();
  return mEMALIGn(alignment, sz);
}

void weak_variable (*__malloc_initialize_hook) __MALLOC_P ((void)) = NULL;
void weak_variable (*__free_hook) __MALLOC_P ((__malloc_ptr_t __ptr,
					       const __malloc_ptr_t)) = NULL;
__malloc_ptr_t weak_variable (*__malloc_hook)
 __MALLOC_P ((size_t __size, const __malloc_ptr_t)) = malloc_hook_ini;
__malloc_ptr_t weak_variable (*__realloc_hook)
 __MALLOC_P ((__malloc_ptr_t __ptr, size_t __size, const __malloc_ptr_t))
     = realloc_hook_ini;
__malloc_ptr_t weak_variable (*__memalign_hook)
 __MALLOC_P ((size_t __alignment, size_t __size, const __malloc_ptr_t))
     = memalign_hook_ini;
void weak_variable (*__after_morecore_hook) __MALLOC_P ((void)) = NULL;

/* Whether we are using malloc checking.  */
static int using_malloc_checking;

/* A flag that is set by malloc_set_state, to signal that malloc checking
   must not be enabled on the request from the user (via the MALLOC_CHECK_
   environment variable).  It is reset by __malloc_check_init to tell
   malloc_set_state that the user has requested malloc checking.

   The purpose of this flag is to make sure that malloc checking is not
   enabled when the heap to be restored was constructed without malloc
   checking, and thus does not contain the required magic bytes.
   Otherwise the heap would be corrupted by calls to free and realloc.  If
   it turns out that the heap was created with malloc checking and the
   user has requested it malloc_set_state just calls __malloc_check_init
   again to enable it.  On the other hand, reusing such a heap without
   further malloc checking is safe.  */
static int disallow_malloc_check;

/* Activate a standard set of debugging hooks. */
void
__malloc_check_init()
{
  if (disallow_malloc_check) {
    disallow_malloc_check = 0;
    return;
  }
  using_malloc_checking = 1;
  __malloc_hook = malloc_check;
  __free_hook = free_check;
  __realloc_hook = realloc_check;
  __memalign_hook = memalign_check;
  if(check_action & 1)
    fprintf(stderr, "malloc: using debugging hooks\n");
}

#endif





/* Routines dealing with mmap(). */

#if HAVE_MMAP

#ifndef MAP_ANONYMOUS

static int dev_zero_fd = -1; /* Cached file descriptor for /dev/zero. */

#define MMAP(addr, size, prot, flags) ((dev_zero_fd < 0) ? \
 (dev_zero_fd = open("/dev/zero", O_RDWR), \
  mmap((addr), (size), (prot), (flags), dev_zero_fd, 0)) : \
   mmap((addr), (size), (prot), (flags), dev_zero_fd, 0))

#else

#define MMAP(addr, size, prot, flags) \
 (mmap((addr), (size), (prot), (flags)|MAP_ANONYMOUS, -1, 0))

#endif

#if defined __GNUC__ && __GNUC__ >= 2
/* This function is only called from one place, inline it.  */
__inline__
#endif
static mchunkptr
internal_function
#if __STD_C
mmap_chunk(size_t size)
#else
mmap_chunk(size) size_t size;
#endif
{
  size_t page_mask = malloc_getpagesize - 1;
  mchunkptr p;

  /* For mmapped chunks, the overhead is one SIZE_SZ unit larger, because
   * there is no following chunk whose prev_size field could be used.
   */
  size = (size + SIZE_SZ + page_mask) & ~page_mask;

  p = (mchunkptr)MMAP(0, size, PROT_READ|PROT_WRITE, MAP_PRIVATE);
  if(p == (mchunkptr) MAP_FAILED) return 0;

  n_mmaps++;
  if (n_mmaps > max_n_mmaps) max_n_mmaps = n_mmaps;

  /* We demand that eight bytes into a page must be 8-byte aligned. */
  assert(aligned_OK(chunk2mem(p)));

  /* The offset to the start of the mmapped region is stored
   * in the prev_size field of the chunk; normally it is zero,
   * but that can be changed in memalign().
   */
  p->prev_size = 0;
  set_head(p, size|IS_MMAPPED);

  mmapped_mem += size;
  if ((unsigned long)mmapped_mem > (unsigned long)max_mmapped_mem)
    max_mmapped_mem = mmapped_mem;
#ifdef NO_THREADS
  if ((unsigned long)(mmapped_mem + arena_mem + sbrked_mem) > max_total_mem)
    max_total_mem = mmapped_mem + arena_mem + sbrked_mem;
#endif
  return p;
}

static void
internal_function
#if __STD_C
munmap_chunk(mchunkptr p)
#else
munmap_chunk(p) mchunkptr p;
#endif
{
  INTERNAL_SIZE_T size = chunksize(p);
  int ret;

  assert (chunk_is_mmapped(p));
  assert(! ((char*)p >= sbrk_base && (char*)p < sbrk_base + sbrked_mem));
  assert((n_mmaps > 0));
  assert(((p->prev_size + size) & (malloc_getpagesize-1)) == 0);

  n_mmaps--;
  mmapped_mem -= (size + p->prev_size);

  ret = munmap((char *)p - p->prev_size, size + p->prev_size);

  /* munmap returns non-zero on failure */
  assert(ret == 0);
}

#if HAVE_MREMAP

static mchunkptr
internal_function
#if __STD_C
mremap_chunk(mchunkptr p, size_t new_size)
#else
mremap_chunk(p, new_size) mchunkptr p; size_t new_size;
#endif
{
  size_t page_mask = malloc_getpagesize - 1;
  INTERNAL_SIZE_T offset = p->prev_size;
  INTERNAL_SIZE_T size = chunksize(p);
  char *cp;

  assert (chunk_is_mmapped(p));
  assert(! ((char*)p >= sbrk_base && (char*)p < sbrk_base + sbrked_mem));
  assert((n_mmaps > 0));
  assert(((size + offset) & (malloc_getpagesize-1)) == 0);

  /* Note the extra SIZE_SZ overhead as in mmap_chunk(). */
  new_size = (new_size + offset + SIZE_SZ + page_mask) & ~page_mask;

  cp = (char *)mremap((char *)p - offset, size + offset, new_size,
                      MREMAP_MAYMOVE);

  if (cp == MAP_FAILED) return 0;

  p = (mchunkptr)(cp + offset);

  assert(aligned_OK(chunk2mem(p)));

  assert((p->prev_size == offset));
  set_head(p, (new_size - offset)|IS_MMAPPED);

  mmapped_mem -= size + offset;
  mmapped_mem += new_size;
  if ((unsigned long)mmapped_mem > (unsigned long)max_mmapped_mem)
    max_mmapped_mem = mmapped_mem;
#ifdef NO_THREADS
  if ((unsigned long)(mmapped_mem + arena_mem + sbrked_mem) > max_total_mem)
    max_total_mem = mmapped_mem + arena_mem + sbrked_mem;
#endif
  return p;
}

#endif /* HAVE_MREMAP */

#endif /* HAVE_MMAP */



/* Managing heaps and arenas (for concurrent threads) */

#if USE_ARENAS

/* Create a new heap.  size is automatically rounded up to a multiple
   of the page size. */

static heap_info *
internal_function
#if __STD_C
new_heap(size_t size)
#else
new_heap(size) size_t size;
#endif
{
  size_t page_mask = malloc_getpagesize - 1;
  char *p1, *p2;
  unsigned long ul;
  heap_info *h;

  if(size+top_pad < HEAP_MIN_SIZE)
    size = HEAP_MIN_SIZE;
  else if(size+top_pad <= HEAP_MAX_SIZE)
    size += top_pad;
  else if(size > HEAP_MAX_SIZE)
    return 0;
  else
    size = HEAP_MAX_SIZE;
  size = (size + page_mask) & ~page_mask;

  /* A memory region aligned to a multiple of HEAP_MAX_SIZE is needed.
     No swap space needs to be reserved for the following large
     mapping (on Linux, this is the case for all non-writable mappings
     anyway). */
  p1 = (char *)MMAP(0, HEAP_MAX_SIZE<<1, PROT_NONE, MAP_PRIVATE|MAP_NORESERVE);
  if(p1 != MAP_FAILED) {
    p2 = (char *)(((unsigned long)p1 + (HEAP_MAX_SIZE-1)) & ~(HEAP_MAX_SIZE-1));
    ul = p2 - p1;
    if (ul)
      munmap(p1, ul);
    munmap(p2 + HEAP_MAX_SIZE, HEAP_MAX_SIZE - ul);
  } else {
    /* Try to take the chance that an allocation of only HEAP_MAX_SIZE
       is already aligned. */
    p2 = (char *)MMAP(0, HEAP_MAX_SIZE, PROT_NONE, MAP_PRIVATE|MAP_NORESERVE);
    if(p2 == MAP_FAILED)
      return 0;
    if((unsigned long)p2 & (HEAP_MAX_SIZE-1)) {
      munmap(p2, HEAP_MAX_SIZE);
      return 0;
    }
  }
  if(MMAP(p2, size, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED)
     == (char *) MAP_FAILED) {
    munmap(p2, HEAP_MAX_SIZE);
    return 0;
  }
  h = (heap_info *)p2;
  h->size = size;
  THREAD_STAT(stat_n_heaps++);
  return h;
}

/* Grow or shrink a heap.  size is automatically rounded up to a
   multiple of the page size if it is positive. */

static int
#if __STD_C
grow_heap(heap_info *h, long diff)
#else
grow_heap(h, diff) heap_info *h; long diff;
#endif
{
  size_t page_mask = malloc_getpagesize - 1;
  long new_size;

  if(diff >= 0) {
    diff = (diff + page_mask) & ~page_mask;
    new_size = (long)h->size + diff;
    if(new_size > HEAP_MAX_SIZE)
      return -1;
    if(MMAP((char *)h + h->size, diff, PROT_READ|PROT_WRITE,
	    MAP_PRIVATE|MAP_FIXED) == (char *) MAP_FAILED)
      return -2;
  } else {
    new_size = (long)h->size + diff;
    if(new_size < (long)sizeof(*h))
      return -1;
    /* Try to re-map the extra heap space freshly to save memory, and
       make it inaccessible. */
    if((char *)MMAP((char *)h + new_size, -diff, PROT_NONE,
                    MAP_PRIVATE|MAP_FIXED) == (char *) MAP_FAILED)
      return -2;
  }
  h->size = new_size;
  return 0;
}

/* Delete a heap. */

#define delete_heap(heap) munmap((char*)(heap), HEAP_MAX_SIZE)

/* arena_get() acquires an arena and locks the corresponding mutex.
   First, try the one last locked successfully by this thread.  (This
   is the common case and handled with a macro for speed.)  Then, loop
   once over the circularly linked list of arenas.  If no arena is
   readily available, create a new one.  In this latter case, `size'
   is just a hint as to how much memory will be required immediately
   in the new arena. */

#define arena_get(ptr, size) do { \
  Void_t *vptr = NULL; \
  ptr = (arena *)tsd_getspecific(arena_key, vptr); \
  if(ptr && !mutex_trylock(&ptr->mutex)) { \
    THREAD_STAT(++(ptr->stat_lock_direct)); \
  } else \
    ptr = arena_get2(ptr, (size)); \
} while(0)

static arena *
internal_function
#if __STD_C
arena_get2(arena *a_tsd, size_t size)
#else
arena_get2(a_tsd, size) arena *a_tsd; size_t size;
#endif
{
  arena *a;
  heap_info *h;
  char *ptr;
  int i;
  unsigned long misalign;

  if(!a_tsd)
    a = a_tsd = &main_arena;
  else {
    a = a_tsd->next;
    if(!a) {
      /* This can only happen while initializing the new arena. */
      (void)mutex_lock(&main_arena.mutex);
      THREAD_STAT(++(main_arena.stat_lock_wait));
      return &main_arena;
    }
  }

  /* Check the global, circularly linked list for available arenas. */
 repeat:
  do {
    if(!mutex_trylock(&a->mutex)) {
      THREAD_STAT(++(a->stat_lock_loop));
      tsd_setspecific(arena_key, (Void_t *)a);
      return a;
    }
    a = a->next;
  } while(a != a_tsd);

  /* If not even the list_lock can be obtained, try again.  This can
     happen during `atfork', or for example on systems where thread
     creation makes it temporarily impossible to obtain _any_
     locks. */
  if(mutex_trylock(&list_lock)) {
    a = a_tsd;
    goto repeat;
  }
  (void)mutex_unlock(&list_lock);

  /* Nothing immediately available, so generate a new arena. */
  h = new_heap(size + (sizeof(*h) + sizeof(*a) + MALLOC_ALIGNMENT));
  if(!h) {
    /* Maybe size is too large to fit in a single heap.  So, just try
       to create a minimally-sized arena and let chunk_alloc() attempt
       to deal with the large request via mmap_chunk(). */
    h = new_heap(sizeof(*h) + sizeof(*a) + MALLOC_ALIGNMENT);
    if(!h)
      return 0;
  }
  a = h->ar_ptr = (arena *)(h+1);
  for(i=0; i<NAV; i++)
    init_bin(a, i);
  a->next = NULL;
  a->size = h->size;
  arena_mem += h->size;
#ifdef NO_THREADS
  if((unsigned long)(mmapped_mem + arena_mem + sbrked_mem) > max_total_mem)
    max_total_mem = mmapped_mem + arena_mem + sbrked_mem;
#endif
  tsd_setspecific(arena_key, (Void_t *)a);
  mutex_init(&a->mutex);
  i = mutex_lock(&a->mutex); /* remember result */

  /* Set up the top chunk, with proper alignment. */
  ptr = (char *)(a + 1);
  misalign = (unsigned long)chunk2mem(ptr) & MALLOC_ALIGN_MASK;
  if (misalign > 0)
    ptr += MALLOC_ALIGNMENT - misalign;
  top(a) = (mchunkptr)ptr;
  set_head(top(a), (((char*)h + h->size) - ptr) | PREV_INUSE);

  /* Add the new arena to the list. */
  (void)mutex_lock(&list_lock);
  a->next = main_arena.next;
  main_arena.next = a;
  (void)mutex_unlock(&list_lock);

  if(i) /* locking failed; keep arena for further attempts later */
    return 0;

  THREAD_STAT(++(a->stat_lock_loop));
  return a;
}

/* find the heap and corresponding arena for a given ptr */

#define heap_for_ptr(ptr) \
 ((heap_info *)((unsigned long)(ptr) & ~(HEAP_MAX_SIZE-1)))
#define arena_for_ptr(ptr) \
 (((mchunkptr)(ptr) < top(&main_arena) && (char *)(ptr) >= sbrk_base) ? \
  &main_arena : heap_for_ptr(ptr)->ar_ptr)

#else /* !USE_ARENAS */

/* There is only one arena, main_arena. */

#define arena_get(ptr, sz) (ptr = &main_arena)
#define arena_for_ptr(ptr) (&main_arena)

#endif /* USE_ARENAS */



/*
  Debugging support
*/

#if MALLOC_DEBUG


/*
  These routines make a number of assertions about the states
  of data structures that should be true at all times. If any
  are not true, it's very likely that a user program has somehow
  trashed memory. (It's also possible that there is a coding error
  in malloc. In which case, please report it!)
*/

#if __STD_C
static void do_check_chunk(arena *ar_ptr, mchunkptr p)
#else
static void do_check_chunk(ar_ptr, p) arena *ar_ptr; mchunkptr p;
#endif
{
  INTERNAL_SIZE_T sz = p->size & ~PREV_INUSE;

  /* No checkable chunk is mmapped */
  assert(!chunk_is_mmapped(p));

#if USE_ARENAS
  if(ar_ptr != &main_arena) {
    heap_info *heap = heap_for_ptr(p);
    assert(heap->ar_ptr == ar_ptr);
    if(p != top(ar_ptr))
      assert((char *)p + sz <= (char *)heap + heap->size);
    else
      assert((char *)p + sz == (char *)heap + heap->size);
    return;
  }
#endif

  /* Check for legal address ... */
  assert((char*)p >= sbrk_base);
  if (p != top(ar_ptr))
    assert((char*)p + sz <= (char*)top(ar_ptr));
  else
    assert((char*)p + sz <= sbrk_base + sbrked_mem);

}


#if __STD_C
static void do_check_free_chunk(arena *ar_ptr, mchunkptr p)
#else
static void do_check_free_chunk(ar_ptr, p) arena *ar_ptr; mchunkptr p;
#endif
{
  INTERNAL_SIZE_T sz = p->size & ~PREV_INUSE;
  mchunkptr next = chunk_at_offset(p, sz);

  do_check_chunk(ar_ptr, p);

  /* Check whether it claims to be free ... */
  assert(!inuse(p));

  /* Must have OK size and fields */
  assert((long)sz >= (long)MINSIZE);
  assert((sz & MALLOC_ALIGN_MASK) == 0);
  assert(aligned_OK(chunk2mem(p)));
  /* ... matching footer field */
  assert(next->prev_size == sz);
  /* ... and is fully consolidated */
  assert(prev_inuse(p));
  assert (next == top(ar_ptr) || inuse(next));

  /* ... and has minimally sane links */
  assert(p->fd->bk == p);
  assert(p->bk->fd == p);
}

#if __STD_C
static void do_check_inuse_chunk(arena *ar_ptr, mchunkptr p)
#else
static void do_check_inuse_chunk(ar_ptr, p) arena *ar_ptr; mchunkptr p;
#endif
{
  mchunkptr next = next_chunk(p);
  do_check_chunk(ar_ptr, p);

  /* Check whether it claims to be in use ... */
  assert(inuse(p));

  /* ... whether its size is OK (it might be a fencepost) ... */
  assert(chunksize(p) >= MINSIZE || next->size == (0|PREV_INUSE));

  /* ... and is surrounded by OK chunks.
    Since more things can be checked with free chunks than inuse ones,
    if an inuse chunk borders them and debug is on, it's worth doing them.
  */
  if (!prev_inuse(p))
  {
    mchunkptr prv = prev_chunk(p);
    assert(next_chunk(prv) == p);
    do_check_free_chunk(ar_ptr, prv);
  }
  if (next == top(ar_ptr))
  {
    assert(prev_inuse(next));
    assert(chunksize(next) >= MINSIZE);
  }
  else if (!inuse(next))
    do_check_free_chunk(ar_ptr, next);

}

#if __STD_C
static void do_check_malloced_chunk(arena *ar_ptr,
                                    mchunkptr p, INTERNAL_SIZE_T s)
#else
static void do_check_malloced_chunk(ar_ptr, p, s)
arena *ar_ptr; mchunkptr p; INTERNAL_SIZE_T s;
#endif
{
  INTERNAL_SIZE_T sz = p->size & ~PREV_INUSE;
  long room = sz - s;

  do_check_inuse_chunk(ar_ptr, p);

  /* Legal size ... */
  assert((long)sz >= (long)MINSIZE);
  assert((sz & MALLOC_ALIGN_MASK) == 0);
  assert(room >= 0);
  assert(room < (long)MINSIZE);

  /* ... and alignment */
  assert(aligned_OK(chunk2mem(p)));


  /* ... and was allocated at front of an available chunk */
  assert(prev_inuse(p));

}


#define check_free_chunk(A,P) do_check_free_chunk(A,P)
#define check_inuse_chunk(A,P) do_check_inuse_chunk(A,P)
#define check_chunk(A,P) do_check_chunk(A,P)
#define check_malloced_chunk(A,P,N) do_check_malloced_chunk(A,P,N)
#else
#define check_free_chunk(A,P)
#define check_inuse_chunk(A,P)
#define check_chunk(A,P)
#define check_malloced_chunk(A,P,N)
#endif



/*
  Macro-based internal utilities
*/


/*
  Linking chunks in bin lists.
  Call these only with variables, not arbitrary expressions, as arguments.
*/

/*
  Place chunk p of size s in its bin, in size order,
  putting it ahead of others of same size.
*/


#define frontlink(A, P, S, IDX, BK, FD)                                       \
{                                                                             \
  if (S < MAX_SMALLBIN_SIZE)                                                  \
  {                                                                           \
    IDX = smallbin_index(S);                                                  \
    mark_binblock(A, IDX);                                                    \
    BK = bin_at(A, IDX);                                                      \
    FD = BK->fd;                                                              \
    P->bk = BK;                                                               \
    P->fd = FD;                                                               \
    FD->bk = BK->fd = P;                                                      \
  }                                                                           \
  else                                                                        \
  {                                                                           \
    IDX = bin_index(S);                                                       \
    BK = bin_at(A, IDX);                                                      \
    FD = BK->fd;                                                              \
    if (FD == BK) mark_binblock(A, IDX);                                      \
    else                                                                      \
    {                                                                         \
      while (FD != BK && S < chunksize(FD)) FD = FD->fd;                      \
      BK = FD->bk;                                                            \
    }                                                                         \
    P->bk = BK;                                                               \
    P->fd = FD;                                                               \
    FD->bk = BK->fd = P;                                                      \
  }                                                                           \
}


/* take a chunk off a list */

#define unlink(P, BK, FD)                                                     \
{                                                                             \
  BK = P->bk;                                                                 \
  FD = P->fd;                                                                 \
  FD->bk = BK;                                                                \
  BK->fd = FD;                                                                \
}                                                                             \

/* Place p as the last remainder */

#define link_last_remainder(A, P)                                             \
{                                                                             \
  last_remainder(A)->fd = last_remainder(A)->bk = P;                          \
  P->fd = P->bk = last_remainder(A);                                          \
}

/* Clear the last_remainder bin */

#define clear_last_remainder(A) \
  (last_remainder(A)->fd = last_remainder(A)->bk = last_remainder(A))





/*
  Extend the top-most chunk by obtaining memory from system.
  Main interface to sbrk (but see also malloc_trim).
*/

#if defined __GNUC__ && __GNUC__ >= 2
/* This function is called only from one place, inline it.  */
__inline__
#endif
static void
internal_function
#if __STD_C
malloc_extend_top(arena *ar_ptr, INTERNAL_SIZE_T nb)
#else
malloc_extend_top(ar_ptr, nb) arena *ar_ptr; INTERNAL_SIZE_T nb;
#endif
{
  unsigned long pagesz   = malloc_getpagesize;
  mchunkptr old_top      = top(ar_ptr);        /* Record state of old top */
  INTERNAL_SIZE_T old_top_size = chunksize(old_top);
  INTERNAL_SIZE_T top_size;                    /* new size of top chunk */

#if USE_ARENAS
  if(ar_ptr == &main_arena) {
#endif

    char*     brk;                  /* return value from sbrk */
    INTERNAL_SIZE_T front_misalign; /* unusable bytes at front of sbrked space */
    INTERNAL_SIZE_T correction;     /* bytes for 2nd sbrk call */
    char*     new_brk;              /* return of 2nd sbrk call */
    char*     old_end = (char*)(chunk_at_offset(old_top, old_top_size));

    /* Pad request with top_pad plus minimal overhead */
    INTERNAL_SIZE_T sbrk_size = nb + top_pad + MINSIZE;

    /* If not the first time through, round to preserve page boundary */
    /* Otherwise, we need to correct to a page size below anyway. */
    /* (We also correct below if an intervening foreign sbrk call.) */

    if (sbrk_base != (char*)(-1))
      sbrk_size = (sbrk_size + (pagesz - 1)) & ~(pagesz - 1);

    brk = (char*)(MORECORE (sbrk_size));

    /* Fail if sbrk failed or if a foreign sbrk call killed our space */
    if (brk == (char*)(MORECORE_FAILURE) ||
        (brk < old_end && old_top != initial_top(&main_arena)))
      return;

#if defined _LIBC || defined MALLOC_HOOKS
    /* Call the `morecore' hook if necessary.  */
    if (__after_morecore_hook)
      (*__after_morecore_hook) ();
#endif

    sbrked_mem += sbrk_size;

    if (brk == old_end) { /* can just add bytes to current top */
      top_size = sbrk_size + old_top_size;
      set_head(old_top, top_size | PREV_INUSE);
      old_top = 0; /* don't free below */
    } else {
      if (sbrk_base == (char*)(-1)) /* First time through. Record base */
        sbrk_base = brk;
      else
        /* Someone else called sbrk().  Count those bytes as sbrked_mem. */
        sbrked_mem += brk - (char*)old_end;

      /* Guarantee alignment of first new chunk made from this space */
      front_misalign = (unsigned long)chunk2mem(brk) & MALLOC_ALIGN_MASK;
      if (front_misalign > 0) {
        correction = (MALLOC_ALIGNMENT) - front_misalign;
        brk += correction;
      } else
        correction = 0;

      /* Guarantee the next brk will be at a page boundary */
      correction += pagesz - ((unsigned long)(brk + sbrk_size) & (pagesz - 1));

      /* Allocate correction */
      new_brk = (char*)(MORECORE (correction));
      if (new_brk == (char*)(MORECORE_FAILURE)) return;

#if defined _LIBC || defined MALLOC_HOOKS
      /* Call the `morecore' hook if necessary.  */
      if (__after_morecore_hook)
        (*__after_morecore_hook) ();
#endif

      sbrked_mem += correction;

      top(&main_arena) = chunk_at_offset(brk, 0);
      top_size = new_brk - brk + correction;
      set_head(top(&main_arena), top_size | PREV_INUSE);

      if (old_top == initial_top(&main_arena))
        old_top = 0; /* don't free below */
    }

    if ((unsigned long)sbrked_mem > (unsigned long)max_sbrked_mem)
      max_sbrked_mem = sbrked_mem;
#ifdef NO_THREADS
    if ((unsigned long)(mmapped_mem + arena_mem + sbrked_mem) > max_total_mem)
      max_total_mem = mmapped_mem + arena_mem + sbrked_mem;
#endif

#if USE_ARENAS
  } else { /* ar_ptr != &main_arena */
    heap_info *old_heap, *heap;
    size_t old_heap_size;

    if(old_top_size < MINSIZE) /* this should never happen */
      return;

    /* First try to extend the current heap. */
    if(MINSIZE + nb <= old_top_size)
      return;
    old_heap = heap_for_ptr(old_top);
    old_heap_size = old_heap->size;
    if(grow_heap(old_heap, MINSIZE + nb - old_top_size) == 0) {
      ar_ptr->size += old_heap->size - old_heap_size;
      arena_mem += old_heap->size - old_heap_size;
#ifdef NO_THREADS
      if(mmapped_mem + arena_mem + sbrked_mem > max_total_mem)
        max_total_mem = mmapped_mem + arena_mem + sbrked_mem;
#endif
      top_size = ((char *)old_heap + old_heap->size) - (char *)old_top;
      set_head(old_top, top_size | PREV_INUSE);
      return;
    }

    /* A new heap must be created. */
    heap = new_heap(nb + (MINSIZE + sizeof(*heap)));
    if(!heap)
      return;
    heap->ar_ptr = ar_ptr;
    heap->prev = old_heap;
    ar_ptr->size += heap->size;
    arena_mem += heap->size;
#ifdef NO_THREADS
    if((unsigned long)(mmapped_mem + arena_mem + sbrked_mem) > max_total_mem)
      max_total_mem = mmapped_mem + arena_mem + sbrked_mem;
#endif

    /* Set up the new top, so we can safely use chunk_free() below. */
    top(ar_ptr) = chunk_at_offset(heap, sizeof(*heap));
    top_size = heap->size - sizeof(*heap);
    set_head(top(ar_ptr), top_size | PREV_INUSE);
  }
#endif /* USE_ARENAS */

  /* We always land on a page boundary */
  assert(((unsigned long)((char*)top(ar_ptr) + top_size) & (pagesz-1)) == 0);

  /* Setup fencepost and free the old top chunk. */
  if(old_top) {
    /* The fencepost takes at least MINSIZE bytes, because it might
       become the top chunk again later.  Note that a footer is set
       up, too, although the chunk is marked in use. */
    old_top_size -= MINSIZE;
    set_head(chunk_at_offset(old_top, old_top_size + 2*SIZE_SZ), 0|PREV_INUSE);
    if(old_top_size >= MINSIZE) {
      set_head(chunk_at_offset(old_top, old_top_size), (2*SIZE_SZ)|PREV_INUSE);
      set_foot(chunk_at_offset(old_top, old_top_size), (2*SIZE_SZ));
      set_head_size(old_top, old_top_size);
      chunk_free(ar_ptr, old_top);
    } else {
      set_head(old_top, (old_top_size + 2*SIZE_SZ)|PREV_INUSE);
      set_foot(old_top, (old_top_size + 2*SIZE_SZ));
    }
  }
}




/* Main public routines */


/*
  Malloc Algorithm:

    The requested size is first converted into a usable form, `nb'.
    This currently means to add 4 bytes overhead plus possibly more to
    obtain 8-byte alignment and/or to obtain a size of at least
    MINSIZE (currently 16, 24, or 32 bytes), the smallest allocatable
    size.  (All fits are considered `exact' if they are within MINSIZE
    bytes.)

    From there, the first successful of the following steps is taken:

      1. The bin corresponding to the request size is scanned, and if
         a chunk of exactly the right size is found, it is taken.

      2. The most recently remaindered chunk is used if it is big
         enough.  This is a form of (roving) first fit, used only in
         the absence of exact fits. Runs of consecutive requests use
         the remainder of the chunk used for the previous such request
         whenever possible. This limited use of a first-fit style
         allocation strategy tends to give contiguous chunks
         coextensive lifetimes, which improves locality and can reduce
         fragmentation in the long run.

      3. Other bins are scanned in increasing size order, using a
         chunk big enough to fulfill the request, and splitting off
         any remainder.  This search is strictly by best-fit; i.e.,
         the smallest (with ties going to approximately the least
         recently used) chunk that fits is selected.

      4. If large enough, the chunk bordering the end of memory
         (`top') is split off. (This use of `top' is in accord with
         the best-fit search rule.  In effect, `top' is treated as
         larger (and thus less well fitting) than any other available
         chunk since it can be extended to be as large as necessary
         (up to system limitations).

      5. If the request size meets the mmap threshold and the
         system supports mmap, and there are few enough currently
         allocated mmapped regions, and a call to mmap succeeds,
         the request is allocated via direct memory mapping.

      6. Otherwise, the top of memory is extended by
         obtaining more space from the system (normally using sbrk,
         but definable to anything else via the MORECORE macro).
         Memory is gathered from the system (in system page-sized
         units) in a way that allows chunks obtained across different
         sbrk calls to be consolidated, but does not require
         contiguous memory. Thus, it should be safe to intersperse
         mallocs with other sbrk calls.


      All allocations are made from the `lowest' part of any found
      chunk. (The implementation invariant is that prev_inuse is
      always true of any allocated chunk; i.e., that each allocated
      chunk borders either a previously allocated and still in-use chunk,
      or the base of its memory arena.)

*/

#if __STD_C
Void_t* mALLOc(size_t bytes)
#else
Void_t* mALLOc(bytes) size_t bytes;
#endif
{
  arena *ar_ptr;
  INTERNAL_SIZE_T nb; /* padded request size */
  mchunkptr victim;

#if defined _LIBC || defined MALLOC_HOOKS
  __malloc_ptr_t (*hook) __MALLOC_PMT ((size_t, __const __malloc_ptr_t)) =
      __malloc_hook;
  if (hook != NULL) {
    Void_t* result;

#if defined __GNUC__ && __GNUC__ >= 2
    result = (*hook)(bytes, RETURN_ADDRESS (0));
#else
    result = (*hook)(bytes, NULL);
#endif
    return result;
  }
#endif

  if(request2size(bytes, nb))
    return 0;
  arena_get(ar_ptr, nb);
  if(!ar_ptr)
    return 0;
  victim = chunk_alloc(ar_ptr, nb);
  if(!victim) {
    /* Maybe the failure is due to running out of mmapped areas. */
    if(ar_ptr != &main_arena) {
      (void)mutex_unlock(&ar_ptr->mutex);
      (void)mutex_lock(&main_arena.mutex);
      victim = chunk_alloc(&main_arena, nb);
      (void)mutex_unlock(&main_arena.mutex);
    } else {
#if USE_ARENAS
      /* ... or sbrk() has failed and there is still a chance to mmap() */
      ar_ptr = arena_get2(ar_ptr->next ? ar_ptr : 0, nb);
      (void)mutex_unlock(&main_arena.mutex);
      if(ar_ptr) {
        victim = chunk_alloc(ar_ptr, nb);
        (void)mutex_unlock(&ar_ptr->mutex);
      }
#endif
    }
    if(!victim) return 0;
  } else
    (void)mutex_unlock(&ar_ptr->mutex);
  return BOUNDED_N(chunk2mem(victim), bytes);
}

static mchunkptr
internal_function
#if __STD_C
chunk_alloc(arena *ar_ptr, INTERNAL_SIZE_T nb)
#else
chunk_alloc(ar_ptr, nb) arena *ar_ptr; INTERNAL_SIZE_T nb;
#endif
{
  mchunkptr victim;                  /* inspected/selected chunk */
  INTERNAL_SIZE_T victim_size;       /* its size */
  int       idx;                     /* index for bin traversal */
  mbinptr   bin;                     /* associated bin */
  mchunkptr remainder;               /* remainder from a split */
  long      remainder_size;          /* its size */
  int       remainder_index;         /* its bin index */
  unsigned long block;               /* block traverser bit */
  int       startidx;                /* first bin of a traversed block */
  mchunkptr fwd;                     /* misc temp for linking */
  mchunkptr bck;                     /* misc temp for linking */
  mbinptr q;                         /* misc temp */


  /* Check for exact match in a bin */

  if (is_small_request(nb))  /* Faster version for small requests */
  {
    idx = smallbin_index(nb);

    /* No traversal or size check necessary for small bins.  */

    q = _bin_at(ar_ptr, idx);
    victim = last(q);

    /* Also scan the next one, since it would have a remainder < MINSIZE */
    if (victim == q)
    {
      q = next_bin(q);
      victim = last(q);
    }
    if (victim != q)
    {
      victim_size = chunksize(victim);
      unlink(victim, bck, fwd);
      set_inuse_bit_at_offset(victim, victim_size);
      check_malloced_chunk(ar_ptr, victim, nb);
      return victim;
    }

    idx += 2; /* Set for bin scan below. We've already scanned 2 bins. */

  }
  else
  {
    idx = bin_index(nb);
    bin = bin_at(ar_ptr, idx);

    for (victim = last(bin); victim != bin; victim = victim->bk)
    {
      victim_size = chunksize(victim);
      remainder_size = victim_size - nb;

      if (remainder_size >= (long)MINSIZE) /* too big */
      {
        --idx; /* adjust to rescan below after checking last remainder */
        break;
      }

      else if (remainder_size >= 0) /* exact fit */
      {
        unlink(victim, bck, fwd);
        set_inuse_bit_at_offset(victim, victim_size);
        check_malloced_chunk(ar_ptr, victim, nb);
        return victim;
      }
    }

    ++idx;

  }

  /* Try to use the last split-off remainder */

  if ( (victim = last_remainder(ar_ptr)->fd) != last_remainder(ar_ptr))
  {
    victim_size = chunksize(victim);
    remainder_size = victim_size - nb;

    if (remainder_size >= (long)MINSIZE) /* re-split */
    {
      remainder = chunk_at_offset(victim, nb);
      set_head(victim, nb | PREV_INUSE);
      link_last_remainder(ar_ptr, remainder);
      set_head(remainder, remainder_size | PREV_INUSE);
      set_foot(remainder, remainder_size);
      check_malloced_chunk(ar_ptr, victim, nb);
      return victim;
    }

    clear_last_remainder(ar_ptr);

    if (remainder_size >= 0)  /* exhaust */
    {
      set_inuse_bit_at_offset(victim, victim_size);
      check_malloced_chunk(ar_ptr, victim, nb);
      return victim;
    }

    /* Else place in bin */

    frontlink(ar_ptr, victim, victim_size, remainder_index, bck, fwd);
  }

  /*
     If there are any possibly nonempty big-enough blocks,
     search for best fitting chunk by scanning bins in blockwidth units.
  */

  if ( (block = idx2binblock(idx)) <= binblocks(ar_ptr))
  {

    /* Get to the first marked block */

    if ( (block & binblocks(ar_ptr)) == 0)
    {
      /* force to an even block boundary */
      idx = (idx & ~(BINBLOCKWIDTH - 1)) + BINBLOCKWIDTH;
      block <<= 1;
      while ((block & binblocks(ar_ptr)) == 0)
      {
        idx += BINBLOCKWIDTH;
        block <<= 1;
      }
    }

    /* For each possibly nonempty block ... */
    for (;;)
    {
      startidx = idx;          /* (track incomplete blocks) */
      q = bin = _bin_at(ar_ptr, idx);

      /* For each bin in this block ... */
      do
      {
        /* Find and use first big enough chunk ... */

        for (victim = last(bin); victim != bin; victim = victim->bk)
        {
          victim_size = chunksize(victim);
          remainder_size = victim_size - nb;

          if (remainder_size >= (long)MINSIZE) /* split */
          {
            remainder = chunk_at_offset(victim, nb);
            set_head(victim, nb | PREV_INUSE);
            unlink(victim, bck, fwd);
            link_last_remainder(ar_ptr, remainder);
            set_head(remainder, remainder_size | PREV_INUSE);
            set_foot(remainder, remainder_size);
            check_malloced_chunk(ar_ptr, victim, nb);
            return victim;
          }

          else if (remainder_size >= 0)  /* take */
          {
            set_inuse_bit_at_offset(victim, victim_size);
            unlink(victim, bck, fwd);
            check_malloced_chunk(ar_ptr, victim, nb);
            return victim;
          }

        }

       bin = next_bin(bin);

      } while ((++idx & (BINBLOCKWIDTH - 1)) != 0);

      /* Clear out the block bit. */

      do   /* Possibly backtrack to try to clear a partial block */
      {
        if ((startidx & (BINBLOCKWIDTH - 1)) == 0)
        {
          binblocks(ar_ptr) &= ~block;
          break;
        }
        --startidx;
        q = prev_bin(q);
      } while (first(q) == q);

      /* Get to the next possibly nonempty block */

      if ( (block <<= 1) <= binblocks(ar_ptr) && (block != 0) )
      {
        while ((block & binblocks(ar_ptr)) == 0)
        {
          idx += BINBLOCKWIDTH;
          block <<= 1;
        }
      }
      else
        break;
    }
  }


  /* Try to use top chunk */

  /* Require that there be a remainder, ensuring top always exists  */
  if ( (remainder_size = chunksize(top(ar_ptr)) - nb) < (long)MINSIZE)
  {

#if HAVE_MMAP
    /* If the request is big and there are not yet too many regions,
       and we would otherwise need to extend, try to use mmap instead.  */
    if ((unsigned long)nb >= (unsigned long)mmap_threshold &&
        n_mmaps < n_mmaps_max &&
        (victim = mmap_chunk(nb)) != 0)
      return victim;
#endif

    /* Try to extend */
    malloc_extend_top(ar_ptr, nb);
    if ((remainder_size = chunksize(top(ar_ptr)) - nb) < (long)MINSIZE)
    {
#if HAVE_MMAP
      /* A last attempt: when we are out of address space in a
         non-main arena, try mmap anyway, as long as it is allowed at
         all.  */
      if (ar_ptr != &main_arena &&
          n_mmaps_max > 0 &&
          (victim = mmap_chunk(nb)) != 0)
        return victim;
#endif
      return 0; /* propagate failure */
    }
  }

  victim = top(ar_ptr);
  set_head(victim, nb | PREV_INUSE);
  top(ar_ptr) = chunk_at_offset(victim, nb);
  set_head(top(ar_ptr), remainder_size | PREV_INUSE);
  check_malloced_chunk(ar_ptr, victim, nb);
  return victim;

}




/*

  free() algorithm :

    cases:

       1. free(0) has no effect.

       2. If the chunk was allocated via mmap, it is released via munmap().

       3. If a returned chunk borders the current high end of memory,
          it is consolidated into the top, and if the total unused
          topmost memory exceeds the trim threshold, malloc_trim is
          called.

       4. Other chunks are consolidated as they arrive, and
          placed in corresponding bins. (This includes the case of
          consolidating with the current `last_remainder').

*/


#if __STD_C
void fREe(Void_t* mem)
#else
void fREe(mem) Void_t* mem;
#endif
{
  arena *ar_ptr;
  mchunkptr p;                          /* chunk corresponding to mem */

#if defined _LIBC || defined MALLOC_HOOKS
  void (*hook) __MALLOC_PMT ((__malloc_ptr_t, __const __malloc_ptr_t)) =
    __free_hook;

  if (hook != NULL) {
#if defined __GNUC__ && __GNUC__ >= 2
    (*hook)(mem, RETURN_ADDRESS (0));
#else
    (*hook)(mem, NULL);
#endif
    return;
  }
#endif

  if (mem == 0)                              /* free(0) has no effect */
    return;

  p = mem2chunk(mem);

#if HAVE_MMAP
  if (chunk_is_mmapped(p))                       /* release mmapped memory. */
  {
    munmap_chunk(p);
    return;
  }
#endif

  ar_ptr = arena_for_ptr(p);
#if THREAD_STATS
  if(!mutex_trylock(&ar_ptr->mutex))
    ++(ar_ptr->stat_lock_direct);
  else {
    (void)mutex_lock(&ar_ptr->mutex);
    ++(ar_ptr->stat_lock_wait);
  }
#else
  (void)mutex_lock(&ar_ptr->mutex);
#endif
  chunk_free(ar_ptr, p);
  (void)mutex_unlock(&ar_ptr->mutex);
}

static void
internal_function
#if __STD_C
chunk_free(arena *ar_ptr, mchunkptr p)
#else
chunk_free(ar_ptr, p) arena *ar_ptr; mchunkptr p;
#endif
{
  INTERNAL_SIZE_T hd = p->size; /* its head field */
  INTERNAL_SIZE_T sz;  /* its size */
  int       idx;       /* its bin index */
  mchunkptr next;      /* next contiguous chunk */
  INTERNAL_SIZE_T nextsz; /* its size */
  INTERNAL_SIZE_T prevsz; /* size of previous contiguous chunk */
  mchunkptr bck;       /* misc temp for linking */
  mchunkptr fwd;       /* misc temp for linking */
  int       islr;      /* track whether merging with last_remainder */

  check_inuse_chunk(ar_ptr, p);

  sz = hd & ~PREV_INUSE;
  next = chunk_at_offset(p, sz);
  nextsz = chunksize(next);

  if (next == top(ar_ptr))                         /* merge with top */
  {
    sz += nextsz;

    if (!(hd & PREV_INUSE))                    /* consolidate backward */
    {
      prevsz = p->prev_size;
      p = chunk_at_offset(p, -(long)prevsz);
      sz += prevsz;
      unlink(p, bck, fwd);
    }

    set_head(p, sz | PREV_INUSE);
    top(ar_ptr) = p;

#if USE_ARENAS
    if(ar_ptr == &main_arena) {
#endif
      if ((unsigned long)(sz) >= (unsigned long)trim_threshold)
        main_trim(top_pad);
#if USE_ARENAS
    } else {
      heap_info *heap = heap_for_ptr(p);

      assert(heap->ar_ptr == ar_ptr);

      /* Try to get rid of completely empty heaps, if possible. */
      if((unsigned long)(sz) >= (unsigned long)trim_threshold ||
         p == chunk_at_offset(heap, sizeof(*heap)))
        heap_trim(heap, top_pad);
    }
#endif
    return;
  }

  islr = 0;

  if (!(hd & PREV_INUSE))                    /* consolidate backward */
  {
    prevsz = p->prev_size;
    p = chunk_at_offset(p, -(long)prevsz);
    sz += prevsz;

    if (p->fd == last_remainder(ar_ptr))     /* keep as last_remainder */
      islr = 1;
    else
      unlink(p, bck, fwd);
  }

  if (!(inuse_bit_at_offset(next, nextsz)))   /* consolidate forward */
  {
    sz += nextsz;

    if (!islr && next->fd == last_remainder(ar_ptr))
                                              /* re-insert last_remainder */
    {
      islr = 1;
      link_last_remainder(ar_ptr, p);
    }
    else
      unlink(next, bck, fwd);

    next = chunk_at_offset(p, sz);
  }
  else
    set_head(next, nextsz);                  /* clear inuse bit */

  set_head(p, sz | PREV_INUSE);
  next->prev_size = sz;
  if (!islr)
    frontlink(ar_ptr, p, sz, idx, bck, fwd);

#if USE_ARENAS
  /* Check whether the heap containing top can go away now. */
  if(next->size < MINSIZE &&
     (unsigned long)sz > trim_threshold &&
     ar_ptr != &main_arena) {                /* fencepost */
    heap_info *heap = heap_for_ptr(top(ar_ptr));

    if(top(ar_ptr) == chunk_at_offset(heap, sizeof(*heap)) &&
       heap->prev == heap_for_ptr(p))
      heap_trim(heap, top_pad);
  }
#endif
}





/*

  Realloc algorithm:

    Chunks that were obtained via mmap cannot be extended or shrunk
    unless HAVE_MREMAP is defined, in which case mremap is used.
    Otherwise, if their reallocation is for additional space, they are
    copied.  If for less, they are just left alone.

    Otherwise, if the reallocation is for additional space, and the
    chunk can be extended, it is, else a malloc-copy-free sequence is
    taken.  There are several different ways that a chunk could be
    extended. All are tried:

       * Extending forward into following adjacent free chunk.
       * Shifting backwards, joining preceding adjacent space
       * Both shifting backwards and extending forward.
       * Extending into newly sbrked space

    Unless the #define REALLOC_ZERO_BYTES_FREES is set, realloc with a
    size argument of zero (re)allocates a minimum-sized chunk.

    If the reallocation is for less space, and the new request is for
    a `small' (<512 bytes) size, then the newly unused space is lopped
    off and freed.

    The old unix realloc convention of allowing the last-free'd chunk
    to be used as an argument to realloc is no longer supported.
    I don't know of any programs still relying on this feature,
    and allowing it would also allow too many other incorrect
    usages of realloc to be sensible.


*/


#if __STD_C
Void_t* rEALLOc(Void_t* oldmem, size_t bytes)
#else
Void_t* rEALLOc(oldmem, bytes) Void_t* oldmem; size_t bytes;
#endif
{
  arena *ar_ptr;
  INTERNAL_SIZE_T    nb;      /* padded request size */

  mchunkptr oldp;             /* chunk corresponding to oldmem */
  INTERNAL_SIZE_T    oldsize; /* its size */

  mchunkptr newp;             /* chunk to return */

#if defined _LIBC || defined MALLOC_HOOKS
  __malloc_ptr_t (*hook) __MALLOC_PMT ((__malloc_ptr_t, size_t,
                                        __const __malloc_ptr_t)) =
    __realloc_hook;
  if (hook != NULL) {
    Void_t* result;

#if defined __GNUC__ && __GNUC__ >= 2
    result = (*hook)(oldmem, bytes, RETURN_ADDRESS (0));
#else
    result = (*hook)(oldmem, bytes, NULL);
#endif
    return result;
  }
#endif

#ifdef REALLOC_ZERO_BYTES_FREES
  if (bytes == 0 && oldmem != NULL) { fREe(oldmem); return 0; }
#endif

  /* realloc of null is supposed to be same as malloc */
  if (oldmem == 0) return mALLOc(bytes);

  oldp    = mem2chunk(oldmem);
  oldsize = chunksize(oldp);

  if(request2size(bytes, nb))
    return 0;

#if HAVE_MMAP
  if (chunk_is_mmapped(oldp))
  {
    Void_t* newmem;

#if HAVE_MREMAP
    newp = mremap_chunk(oldp, nb);
    if(newp)
      return BOUNDED_N(chunk2mem(newp), bytes);
#endif
    /* Note the extra SIZE_SZ overhead. */
    if(oldsize - SIZE_SZ >= nb) return oldmem; /* do nothing */
    /* Must alloc, copy, free. */
    newmem = mALLOc(bytes);
    if (newmem == 0) return 0; /* propagate failure */
    MALLOC_COPY(newmem, oldmem, oldsize - 2*SIZE_SZ, 0);
    munmap_chunk(oldp);
    return newmem;
  }
#endif

  ar_ptr = arena_for_ptr(oldp);
#if THREAD_STATS
  if(!mutex_trylock(&ar_ptr->mutex))
    ++(ar_ptr->stat_lock_direct);
  else {
    (void)mutex_lock(&ar_ptr->mutex);
    ++(ar_ptr->stat_lock_wait);
  }
#else
  (void)mutex_lock(&ar_ptr->mutex);
#endif

#ifndef NO_THREADS
  /* As in malloc(), remember this arena for the next allocation. */
  tsd_setspecific(arena_key, (Void_t *)ar_ptr);
#endif

  newp = chunk_realloc(ar_ptr, oldp, oldsize, nb);

  (void)mutex_unlock(&ar_ptr->mutex);
  return newp ? BOUNDED_N(chunk2mem(newp), bytes) : NULL;
}

static mchunkptr
internal_function
#if __STD_C
chunk_realloc(arena* ar_ptr, mchunkptr oldp, INTERNAL_SIZE_T oldsize,
              INTERNAL_SIZE_T nb)
#else
chunk_realloc(ar_ptr, oldp, oldsize, nb)
arena* ar_ptr; mchunkptr oldp; INTERNAL_SIZE_T oldsize, nb;
#endif
{
  mchunkptr newp = oldp;      /* chunk to return */
  INTERNAL_SIZE_T newsize = oldsize; /* its size */

  mchunkptr next;             /* next contiguous chunk after oldp */
  INTERNAL_SIZE_T  nextsize;  /* its size */

  mchunkptr prev;             /* previous contiguous chunk before oldp */
  INTERNAL_SIZE_T  prevsize;  /* its size */

  mchunkptr remainder;        /* holds split off extra space from newp */
  INTERNAL_SIZE_T  remainder_size;   /* its size */

  mchunkptr bck;              /* misc temp for linking */
  mchunkptr fwd;              /* misc temp for linking */

  check_inuse_chunk(ar_ptr, oldp);

  if ((long)(oldsize) < (long)(nb))
  {
    Void_t* oldmem = BOUNDED_N(chunk2mem(oldp), oldsize);

    /* Try expanding forward */

    next = chunk_at_offset(oldp, oldsize);
    if (next == top(ar_ptr) || !inuse(next))
    {
      nextsize = chunksize(next);

      /* Forward into top only if a remainder */
      if (next == top(ar_ptr))
      {
        if ((long)(nextsize + newsize) >= (long)(nb + MINSIZE))
        {
          newsize += nextsize;
          top(ar_ptr) = chunk_at_offset(oldp, nb);
          set_head(top(ar_ptr), (newsize - nb) | PREV_INUSE);
          set_head_size(oldp, nb);
          return oldp;
        }
      }

      /* Forward into next chunk */
      else if (((long)(nextsize + newsize) >= (long)(nb)))
      {
        unlink(next, bck, fwd);
        newsize  += nextsize;
        goto split;
      }
    }
    else
    {
      next = 0;
      nextsize = 0;
    }

    oldsize -= SIZE_SZ;

    /* Try shifting backwards. */

    if (!prev_inuse(oldp))
    {
      prev = prev_chunk(oldp);
      prevsize = chunksize(prev);

      /* try forward + backward first to save a later consolidation */

      if (next != 0)
      {
        /* into top */
        if (next == top(ar_ptr))
        {
          if ((long)(nextsize + prevsize + newsize) >= (long)(nb + MINSIZE))
          {
            unlink(prev, bck, fwd);
            newp = prev;
            newsize += prevsize + nextsize;
            MALLOC_COPY(BOUNDED_N(chunk2mem(newp), oldsize), oldmem, oldsize,
                        1);
            top(ar_ptr) = chunk_at_offset(newp, nb);
            set_head(top(ar_ptr), (newsize - nb) | PREV_INUSE);
            set_head_size(newp, nb);
            return newp;
          }
        }

        /* into next chunk */
        else if (((long)(nextsize + prevsize + newsize) >= (long)(nb)))
        {
          unlink(next, bck, fwd);
          unlink(prev, bck, fwd);
          newp = prev;
          newsize += nextsize + prevsize;
          MALLOC_COPY(BOUNDED_N(chunk2mem(newp), oldsize), oldmem, oldsize, 1);
          goto split;
        }
      }

      /* backward only */
      if (prev != 0 && (long)(prevsize + newsize) >= (long)nb)
      {
        unlink(prev, bck, fwd);
        newp = prev;
        newsize += prevsize;
        MALLOC_COPY(BOUNDED_N(chunk2mem(newp), oldsize), oldmem, oldsize, 1);
        goto split;
      }
    }

    /* Must allocate */

    newp = chunk_alloc (ar_ptr, nb);

    if (newp == 0) {
      /* Maybe the failure is due to running out of mmapped areas. */
      if (ar_ptr != &main_arena) {
        (void)mutex_lock(&main_arena.mutex);
        newp = chunk_alloc(&main_arena, nb);
        (void)mutex_unlock(&main_arena.mutex);
      } else {
#if USE_ARENAS
        /* ... or sbrk() has failed and there is still a chance to mmap() */
        arena* ar_ptr2 = arena_get2(ar_ptr->next ? ar_ptr : 0, nb);
        if(ar_ptr2) {
          newp = chunk_alloc(ar_ptr2, nb);
          (void)mutex_unlock(&ar_ptr2->mutex);
        }
#endif
      }
      if (newp == 0) /* propagate failure */
        return 0;
    }

    /* Avoid copy if newp is next chunk after oldp. */
    /* (This can only happen when new chunk is sbrk'ed.) */

    if ( newp == next_chunk(oldp))
    {
      newsize += chunksize(newp);
      newp = oldp;
      goto split;
    }

    /* Otherwise copy, free, and exit */
    MALLOC_COPY(BOUNDED_N(chunk2mem(newp), oldsize), oldmem, oldsize, 0);
    chunk_free(ar_ptr, oldp);
    return newp;
  }


 split:  /* split off extra room in old or expanded chunk */

  if (newsize - nb >= MINSIZE) /* split off remainder */
  {
    remainder = chunk_at_offset(newp, nb);
    remainder_size = newsize - nb;
    set_head_size(newp, nb);
    set_head(remainder, remainder_size | PREV_INUSE);
    set_inuse_bit_at_offset(remainder, remainder_size);
    chunk_free(ar_ptr, remainder);
  }
  else
  {
    set_head_size(newp, newsize);
    set_inuse_bit_at_offset(newp, newsize);
  }

  check_inuse_chunk(ar_ptr, newp);
  return newp;
}




/*

  memalign algorithm:

    memalign requests more than enough space from malloc, finds a spot
    within that chunk that meets the alignment request, and then
    possibly frees the leading and trailing space.

    The alignment argument must be a power of two. This property is not
    checked by memalign, so misuse may result in random runtime errors.

    8-byte alignment is guaranteed by normal malloc calls, so don't
    bother calling memalign with an argument of 8 or less.

    Overreliance on memalign is a sure way to fragment space.

*/


#if __STD_C
Void_t* mEMALIGn(size_t alignment, size_t bytes)
#else
Void_t* mEMALIGn(alignment, bytes) size_t alignment; size_t bytes;
#endif
{
  arena *ar_ptr;
  INTERNAL_SIZE_T    nb;      /* padded  request size */
  mchunkptr p;

#if defined _LIBC || defined MALLOC_HOOKS
  __malloc_ptr_t (*hook) __MALLOC_PMT ((size_t, size_t,
                                        __const __malloc_ptr_t)) =
    __memalign_hook;
  if (hook != NULL) {
    Void_t* result;

#if defined __GNUC__ && __GNUC__ >= 2
    result = (*hook)(alignment, bytes, RETURN_ADDRESS (0));
#else
    result = (*hook)(alignment, bytes, NULL);
#endif
    return result;
  }
#endif

  /* If need less alignment than we give anyway, just relay to malloc */

  if (alignment <= MALLOC_ALIGNMENT) return mALLOc(bytes);

  /* Otherwise, ensure that it is at least a minimum chunk size */

  if (alignment <  MINSIZE) alignment = MINSIZE;

  if(request2size(bytes, nb))
    return 0;
  arena_get(ar_ptr, nb + alignment + MINSIZE);
  if(!ar_ptr)
    return 0;
  p = chunk_align(ar_ptr, nb, alignment);
  (void)mutex_unlock(&ar_ptr->mutex);
  if(!p) {
    /* Maybe the failure is due to running out of mmapped areas. */
    if(ar_ptr != &main_arena) {
      (void)mutex_lock(&main_arena.mutex);
      p = chunk_align(&main_arena, nb, alignment);
      (void)mutex_unlock(&main_arena.mutex);
    } else {
#if USE_ARENAS
      /* ... or sbrk() has failed and there is still a chance to mmap() */
      ar_ptr = arena_get2(ar_ptr->next ? ar_ptr : 0, nb);
      if(ar_ptr) {
        p = chunk_align(ar_ptr, nb, alignment);
        (void)mutex_unlock(&ar_ptr->mutex);
      }
#endif
    }
    if(!p) return 0;
  }
  return BOUNDED_N(chunk2mem(p), bytes);
}

static mchunkptr
internal_function
#if __STD_C
chunk_align(arena* ar_ptr, INTERNAL_SIZE_T nb, size_t alignment)
#else
chunk_align(ar_ptr, nb, alignment)
arena* ar_ptr; INTERNAL_SIZE_T nb; size_t alignment;
#endif
{
  unsigned long m;            /* memory returned by malloc call */
  mchunkptr p;                /* corresponding chunk */
  char*     brk;              /* alignment point within p */
  mchunkptr newp;             /* chunk to return */
  INTERNAL_SIZE_T  newsize;   /* its size */
  INTERNAL_SIZE_T  leadsize;  /* leading space befor alignment point */
  mchunkptr remainder;        /* spare room at end to split off */
  long      remainder_size;   /* its size */

  /* Call chunk_alloc with worst case padding to hit alignment. */
  p = chunk_alloc(ar_ptr, nb + alignment + MINSIZE);
  if (p == 0)
    return 0; /* propagate failure */

  m = (unsigned long)chunk2mem(p);

  if ((m % alignment) == 0) /* aligned */
  {
#if HAVE_MMAP
    if(chunk_is_mmapped(p)) {
      return p; /* nothing more to do */
    }
#endif
  }
  else /* misaligned */
  {
    /*
      Find an aligned spot inside chunk.
      Since we need to give back leading space in a chunk of at
      least MINSIZE, if the first calculation places us at
      a spot with less than MINSIZE leader, we can move to the
      next aligned spot -- we've allocated enough total room so that
      this is always possible.
    */

    brk = (char*)mem2chunk(((m + alignment - 1)) & -(long)alignment);
    if ((long)(brk - (char*)(p)) < (long)MINSIZE) brk += alignment;

    newp = chunk_at_offset(brk, 0);
    leadsize = brk - (char*)(p);
    newsize = chunksize(p) - leadsize;

#if HAVE_MMAP
    if(chunk_is_mmapped(p))
    {
      newp->prev_size = p->prev_size + leadsize;
      set_head(newp, newsize|IS_MMAPPED);
      return newp;
    }
#endif

    /* give back leader, use the rest */

    set_head(newp, newsize | PREV_INUSE);
    set_inuse_bit_at_offset(newp, newsize);
    set_head_size(p, leadsize);
    chunk_free(ar_ptr, p);
    p = newp;

    assert (newsize>=nb && (((unsigned long)(chunk2mem(p))) % alignment) == 0);
  }

  /* Also give back spare room at the end */

  remainder_size = chunksize(p) - nb;

  if (remainder_size >= (long)MINSIZE)
  {
    remainder = chunk_at_offset(p, nb);
    set_head(remainder, remainder_size | PREV_INUSE);
    set_head_size(p, nb);
    chunk_free(ar_ptr, remainder);
  }

  check_inuse_chunk(ar_ptr, p);
  return p;
}




/*
    valloc just invokes memalign with alignment argument equal
    to the page size of the system (or as near to this as can
    be figured out from all the includes/defines above.)
*/

#if __STD_C
Void_t* vALLOc(size_t bytes)
#else
Void_t* vALLOc(bytes) size_t bytes;
#endif
{
  if(__malloc_initialized < 0)
    ptmalloc_init ();
  return mEMALIGn (malloc_getpagesize, bytes);
}

/*
  pvalloc just invokes valloc for the nearest pagesize
  that will accommodate request
*/


#if __STD_C
Void_t* pvALLOc(size_t bytes)
#else
Void_t* pvALLOc(bytes) size_t bytes;
#endif
{
  size_t pagesize;
  if(__malloc_initialized < 0)
    ptmalloc_init ();
  pagesize = malloc_getpagesize;
  return mEMALIGn (pagesize, (bytes + pagesize - 1) & ~(pagesize - 1));
}

/*

  calloc calls chunk_alloc, then zeroes out the allocated chunk.

*/

#if __STD_C
Void_t* cALLOc(size_t n, size_t elem_size)
#else
Void_t* cALLOc(n, elem_size) size_t n; size_t elem_size;
#endif
{
  arena *ar_ptr;
  mchunkptr p, oldtop;
  INTERNAL_SIZE_T sz, csz, oldtopsize;
  Void_t* mem;

#if defined _LIBC || defined MALLOC_HOOKS
  __malloc_ptr_t (*hook) __MALLOC_PMT ((size_t, __const __malloc_ptr_t)) =
    __malloc_hook;
  if (hook != NULL) {
    sz = n * elem_size;
#if defined __GNUC__ && __GNUC__ >= 2
    mem = (*hook)(sz, RETURN_ADDRESS (0));
#else
    mem = (*hook)(sz, NULL);
#endif
    if(mem == 0)
      return 0;
#ifdef HAVE_MEMSET
    return memset(mem, 0, sz);
#else
    while(sz > 0) ((char*)mem)[--sz] = 0; /* rather inefficient */
    return mem;
#endif
  }
#endif

  if(request2size(n * elem_size, sz))
    return 0;
  arena_get(ar_ptr, sz);
  if(!ar_ptr)
    return 0;

  /* Check if expand_top called, in which case there may be
     no need to clear. */
#if MORECORE_CLEARS
  oldtop = top(ar_ptr);
  oldtopsize = chunksize(top(ar_ptr));
#if MORECORE_CLEARS < 2
  /* Only newly allocated memory is guaranteed to be cleared.  */
  if (ar_ptr == &main_arena &&
      oldtopsize < sbrk_base + max_sbrked_mem - (char *)oldtop)
    oldtopsize = (sbrk_base + max_sbrked_mem - (char *)oldtop);
#endif
#endif
  p = chunk_alloc (ar_ptr, sz);

  /* Only clearing follows, so we can unlock early. */
  (void)mutex_unlock(&ar_ptr->mutex);

  if (p == 0) {
    /* Maybe the failure is due to running out of mmapped areas. */
    if(ar_ptr != &main_arena) {
      (void)mutex_lock(&main_arena.mutex);
      p = chunk_alloc(&main_arena, sz);
      (void)mutex_unlock(&main_arena.mutex);
    } else {
#if USE_ARENAS
      /* ... or sbrk() has failed and there is still a chance to mmap() */
      (void)mutex_lock(&main_arena.mutex);
      ar_ptr = arena_get2(ar_ptr->next ? ar_ptr : 0, sz);
      (void)mutex_unlock(&main_arena.mutex);
      if(ar_ptr) {
        p = chunk_alloc(ar_ptr, sz);
        (void)mutex_unlock(&ar_ptr->mutex);
      }
#endif
    }
    if (p == 0) return 0;
  }
  mem = BOUNDED_N(chunk2mem(p), n * elem_size);

  /* Two optional cases in which clearing not necessary */

#if HAVE_MMAP
  if (chunk_is_mmapped(p)) return mem;
#endif

  csz = chunksize(p);

#if MORECORE_CLEARS
  if (p == oldtop && csz > oldtopsize) {
    /* clear only the bytes from non-freshly-sbrked memory */
    csz = oldtopsize;
  }
#endif

  csz -= SIZE_SZ;
  MALLOC_ZERO(BOUNDED_N(chunk2mem(p), csz), csz);
  return mem;
}

/*

  cfree just calls free. It is needed/defined on some systems
  that pair it with calloc, presumably for odd historical reasons.

*/

#if !defined(_LIBC)
#if __STD_C
void cfree(Void_t *mem)
#else
void cfree(mem) Void_t *mem;
#endif
{
  fREe(mem);
}
#endif



/*

    Malloc_trim gives memory back to the system (via negative
    arguments to sbrk) if there is unused memory at the `high' end of
    the malloc pool. You can call this after freeing large blocks of
    memory to potentially reduce the system-level memory requirements
    of a program. However, it cannot guarantee to reduce memory. Under
    some allocation patterns, some large free blocks of memory will be
    locked between two used chunks, so they cannot be given back to
    the system.

    The `pad' argument to malloc_trim represents the amount of free
    trailing space to leave untrimmed. If this argument is zero,
    only the minimum amount of memory to maintain internal data
    structures will be left (one page or less). Non-zero arguments
    can be supplied to maintain enough trailing space to service
    future expected allocations without having to re-obtain memory
    from the system.

    Malloc_trim returns 1 if it actually released any memory, else 0.

*/

#if __STD_C
int mALLOC_TRIm(size_t pad)
#else
int mALLOC_TRIm(pad) size_t pad;
#endif
{
  int res;

  (void)mutex_lock(&main_arena.mutex);
  res = main_trim(pad);
  (void)mutex_unlock(&main_arena.mutex);
  return res;
}

/* Trim the main arena. */

static int
internal_function
#if __STD_C
main_trim(size_t pad)
#else
main_trim(pad) size_t pad;
#endif
{
  mchunkptr top_chunk;   /* The current top chunk */
  long  top_size;        /* Amount of top-most memory */
  long  extra;           /* Amount to release */
  char* current_brk;     /* address returned by pre-check sbrk call */
  char* new_brk;         /* address returned by negative sbrk call */

  unsigned long pagesz = malloc_getpagesize;

  top_chunk = top(&main_arena);
  top_size = chunksize(top_chunk);
  extra = ((top_size - pad - MINSIZE + (pagesz-1)) / pagesz - 1) * pagesz;

  if (extra < (long)pagesz) /* Not enough memory to release */
    return 0;

  /* Test to make sure no one else called sbrk */
  current_brk = (char*)(MORECORE (0));
  if (current_brk != (char*)(top_chunk) + top_size)
    return 0;     /* Apparently we don't own memory; must fail */

  new_brk = (char*)(MORECORE (-extra));

#if defined _LIBC || defined MALLOC_HOOKS
  /* Call the `morecore' hook if necessary.  */
  if (__after_morecore_hook)
    (*__after_morecore_hook) ();
#endif

  if (new_brk == (char*)(MORECORE_FAILURE)) { /* sbrk failed? */
    /* Try to figure out what we have */
    current_brk = (char*)(MORECORE (0));
    top_size = current_brk - (char*)top_chunk;
    if (top_size >= (long)MINSIZE) /* if not, we are very very dead! */
    {
      sbrked_mem = current_brk - sbrk_base;
      set_head(top_chunk, top_size | PREV_INUSE);
    }
    check_chunk(&main_arena, top_chunk);
    return 0;
  }
  sbrked_mem -= extra;

  /* Success. Adjust top accordingly. */
  set_head(top_chunk, (top_size - extra) | PREV_INUSE);
  check_chunk(&main_arena, top_chunk);
  return 1;
}

#if USE_ARENAS

static int
internal_function
#if __STD_C
heap_trim(heap_info *heap, size_t pad)
#else
heap_trim(heap, pad) heap_info *heap; size_t pad;
#endif
{
  unsigned long pagesz = malloc_getpagesize;
  arena *ar_ptr = heap->ar_ptr;
  mchunkptr top_chunk = top(ar_ptr), p, bck, fwd;
  heap_info *prev_heap;
  long new_size, top_size, extra;

  /* Can this heap go away completely ? */
  while(top_chunk == chunk_at_offset(heap, sizeof(*heap))) {
    prev_heap = heap->prev;
    p = chunk_at_offset(prev_heap, prev_heap->size - (MINSIZE-2*SIZE_SZ));
    assert(p->size == (0|PREV_INUSE)); /* must be fencepost */
    p = prev_chunk(p);
    new_size = chunksize(p) + (MINSIZE-2*SIZE_SZ);
    assert(new_size>0 && new_size<(long)(2*MINSIZE));
    if(!prev_inuse(p))
      new_size += p->prev_size;
    assert(new_size>0 && new_size<HEAP_MAX_SIZE);
    if(new_size + (HEAP_MAX_SIZE - prev_heap->size) < pad + MINSIZE + pagesz)
      break;
    ar_ptr->size -= heap->size;
    arena_mem -= heap->size;
    delete_heap(heap);
    heap = prev_heap;
    if(!prev_inuse(p)) { /* consolidate backward */
      p = prev_chunk(p);
      unlink(p, bck, fwd);
    }
    assert(((unsigned long)((char*)p + new_size) & (pagesz-1)) == 0);
    assert( ((char*)p + new_size) == ((char*)heap + heap->size) );
    top(ar_ptr) = top_chunk = p;
    set_head(top_chunk, new_size | PREV_INUSE);
    check_chunk(ar_ptr, top_chunk);
  }
  top_size = chunksize(top_chunk);
  extra = ((top_size - pad - MINSIZE + (pagesz-1))/pagesz - 1) * pagesz;
  if(extra < (long)pagesz)
    return 0;
  /* Try to shrink. */
  if(grow_heap(heap, -extra) != 0)
    return 0;
  ar_ptr->size -= extra;
  arena_mem -= extra;

  /* Success. Adjust top accordingly. */
  set_head(top_chunk, (top_size - extra) | PREV_INUSE);
  check_chunk(ar_ptr, top_chunk);
  return 1;
}

#endif /* USE_ARENAS */



/*
  malloc_usable_size:

    This routine tells you how many bytes you can actually use in an
    allocated chunk, which may be more than you requested (although
    often not). You can use this many bytes without worrying about
    overwriting other allocated objects. Not a particularly great
    programming practice, but still sometimes useful.

*/

#if __STD_C
size_t mALLOC_USABLE_SIZe(Void_t* mem)
#else
size_t mALLOC_USABLE_SIZe(mem) Void_t* mem;
#endif
{
  mchunkptr p;

  if (mem == 0)
    return 0;
  else
  {
    p = mem2chunk(mem);
    if(!chunk_is_mmapped(p))
    {
      if (!inuse(p)) return 0;
      check_inuse_chunk(arena_for_ptr(mem), p);
      return chunksize(p) - SIZE_SZ;
    }
    return chunksize(p) - 2*SIZE_SZ;
  }
}




/* Utility to update mallinfo for malloc_stats() and mallinfo() */

static void
#if __STD_C
malloc_update_mallinfo(arena *ar_ptr, struct mallinfo *mi)
#else
malloc_update_mallinfo(ar_ptr, mi) arena *ar_ptr; struct mallinfo *mi;
#endif
{
  int i, navail;
  mbinptr b;
  mchunkptr p;
#if MALLOC_DEBUG
  mchunkptr q;
#endif
  INTERNAL_SIZE_T avail;

  (void)mutex_lock(&ar_ptr->mutex);
  avail = chunksize(top(ar_ptr));
  navail = ((long)(avail) >= (long)MINSIZE)? 1 : 0;

  for (i = 1; i < NAV; ++i)
  {
    b = bin_at(ar_ptr, i);
    for (p = last(b); p != b; p = p->bk)
    {
#if MALLOC_DEBUG
      check_free_chunk(ar_ptr, p);
      for (q = next_chunk(p);
           q != top(ar_ptr) && inuse(q) && (long)chunksize(q) > 0;
           q = next_chunk(q))
        check_inuse_chunk(ar_ptr, q);
#endif
      avail += chunksize(p);
      navail++;
    }
  }

  mi->arena = ar_ptr->size;
  mi->ordblks = navail;
  mi->smblks = mi->usmblks = mi->fsmblks = 0; /* clear unused fields */
  mi->uordblks = ar_ptr->size - avail;
  mi->fordblks = avail;
  mi->hblks = n_mmaps;
  mi->hblkhd = mmapped_mem;
  mi->keepcost = chunksize(top(ar_ptr));

  (void)mutex_unlock(&ar_ptr->mutex);
}

#if USE_ARENAS && MALLOC_DEBUG > 1

/* Print the complete contents of a single heap to stderr. */

static void
#if __STD_C
dump_heap(heap_info *heap)
#else
dump_heap(heap) heap_info *heap;
#endif
{
  char *ptr;
  mchunkptr p;

  fprintf(stderr, "Heap %p, size %10lx:\n", heap, (long)heap->size);
  ptr = (heap->ar_ptr != (arena*)(heap+1)) ?
    (char*)(heap + 1) : (char*)(heap + 1) + sizeof(arena);
  p = (mchunkptr)(((unsigned long)ptr + MALLOC_ALIGN_MASK) &
                  ~MALLOC_ALIGN_MASK);
  for(;;) {
    fprintf(stderr, "chunk %p size %10lx", p, (long)p->size);
    if(p == top(heap->ar_ptr)) {
      fprintf(stderr, " (top)\n");
      break;
    } else if(p->size == (0|PREV_INUSE)) {
      fprintf(stderr, " (fence)\n");
      break;
    }
    fprintf(stderr, "\n");
    p = next_chunk(p);
  }
}

#endif



/*

  malloc_stats:

    For all arenas separately and in total, prints on stderr the
    amount of space obtained from the system, and the current number
    of bytes allocated via malloc (or realloc, etc) but not yet
    freed. (Note that this is the number of bytes allocated, not the
    number requested. It will be larger than the number requested
    because of alignment and bookkeeping overhead.)  When not compiled
    for multiple threads, the maximum amount of allocated memory
    (which may be more than current if malloc_trim and/or munmap got
    called) is also reported.  When using mmap(), prints the maximum
    number of simultaneous mmap regions used, too.

*/

void mALLOC_STATs()
{
  int i;
  arena *ar_ptr;
  struct mallinfo mi;
  unsigned int in_use_b = mmapped_mem, system_b = in_use_b;
#if THREAD_STATS
  long stat_lock_direct = 0, stat_lock_loop = 0, stat_lock_wait = 0;
#endif

  for(i=0, ar_ptr = &main_arena;; i++) {
    malloc_update_mallinfo(ar_ptr, &mi);
    fprintf(stderr, "Arena %d:\n", i);
    fprintf(stderr, "system bytes     = %10u\n", (unsigned int)mi.arena);
    fprintf(stderr, "in use bytes     = %10u\n", (unsigned int)mi.uordblks);
    system_b += mi.arena;
    in_use_b += mi.uordblks;
#if THREAD_STATS
    stat_lock_direct += ar_ptr->stat_lock_direct;
    stat_lock_loop += ar_ptr->stat_lock_loop;
    stat_lock_wait += ar_ptr->stat_lock_wait;
#endif
#if USE_ARENAS && MALLOC_DEBUG > 1
    if(ar_ptr != &main_arena) {
      heap_info *heap;
      (void)mutex_lock(&ar_ptr->mutex);
      heap = heap_for_ptr(top(ar_ptr));
      while(heap) { dump_heap(heap); heap = heap->prev; }
      (void)mutex_unlock(&ar_ptr->mutex);
    }
#endif
    ar_ptr = ar_ptr->next;
    if(ar_ptr == &main_arena) break;
  }
#if HAVE_MMAP
  fprintf(stderr, "Total (incl. mmap):\n");
#else
  fprintf(stderr, "Total:\n");
#endif
  fprintf(stderr, "system bytes     = %10u\n", system_b);
  fprintf(stderr, "in use bytes     = %10u\n", in_use_b);
#ifdef NO_THREADS
  fprintf(stderr, "max system bytes = %10u\n", (unsigned int)max_total_mem);
#endif
#if HAVE_MMAP
  fprintf(stderr, "max mmap regions = %10u\n", (unsigned int)max_n_mmaps);
  fprintf(stderr, "max mmap bytes   = %10lu\n", max_mmapped_mem);
#endif
#if THREAD_STATS
  fprintf(stderr, "heaps created    = %10d\n",  stat_n_heaps);
  fprintf(stderr, "locked directly  = %10ld\n", stat_lock_direct);
  fprintf(stderr, "locked in loop   = %10ld\n", stat_lock_loop);
  fprintf(stderr, "locked waiting   = %10ld\n", stat_lock_wait);
  fprintf(stderr, "locked total     = %10ld\n",
          stat_lock_direct + stat_lock_loop + stat_lock_wait);
#endif
}

/*
  mallinfo returns a copy of updated current mallinfo.
  The information reported is for the arena last used by the thread.
*/

struct mallinfo mALLINFo()
{
  struct mallinfo mi;
  Void_t *vptr = NULL;

#ifndef NO_THREADS
  tsd_getspecific(arena_key, vptr);
  if(vptr == ATFORK_ARENA_PTR)
    vptr = (Void_t*)&main_arena;
#endif
  malloc_update_mallinfo((vptr ? (arena*)vptr : &main_arena), &mi);
  return mi;
}




/*
  mallopt:

    mallopt is the general SVID/XPG interface to tunable parameters.
    The format is to provide a (parameter-number, parameter-value) pair.
    mallopt then sets the corresponding parameter to the argument
    value if it can (i.e., so long as the value is meaningful),
    and returns 1 if successful else 0.

    See descriptions of tunable parameters above.

*/

#if __STD_C
int mALLOPt(int param_number, int value)
#else
int mALLOPt(param_number, value) int param_number; int value;
#endif
{
  switch(param_number)
  {
    case M_TRIM_THRESHOLD:
      trim_threshold = value; return 1;
    case M_TOP_PAD:
      top_pad = value; return 1;
    case M_MMAP_THRESHOLD:
#if USE_ARENAS
      /* Forbid setting the threshold too high. */
      if((unsigned long)value > HEAP_MAX_SIZE/2) return 0;
#endif
      mmap_threshold = value; return 1;
    case M_MMAP_MAX:
#if HAVE_MMAP
      n_mmaps_max = value; return 1;
#else
      if (value != 0) return 0; else  n_mmaps_max = value; return 1;
#endif
    case M_CHECK_ACTION:
      check_action = value; return 1;

    default:
      return 0;
  }
}



/* Get/set state: malloc_get_state() records the current state of all
   malloc variables (_except_ for the actual heap contents and `hook'
   function pointers) in a system dependent, opaque data structure.
   This data structure is dynamically allocated and can be free()d
   after use.  malloc_set_state() restores the state of all malloc
   variables to the previously obtained state.  This is especially
   useful when using this malloc as part of a shared library, and when
   the heap contents are saved/restored via some other method.  The
   primary example for this is GNU Emacs with its `dumping' procedure.
   `Hook' function pointers are never saved or restored by these
   functions, with two exceptions: If malloc checking was in use when
   malloc_get_state() was called, then malloc_set_state() calls
   __malloc_check_init() if possible; if malloc checking was not in
   use in the recorded state but the user requested malloc checking,
   then the hooks are reset to 0.  */

#define MALLOC_STATE_MAGIC   0x444c4541l
#define MALLOC_STATE_VERSION (0*0x100l + 1l) /* major*0x100 + minor */

struct malloc_state {
  long          magic;
  long          version;
  mbinptr       av[NAV * 2 + 2];
  char*         sbrk_base;
  int           sbrked_mem_bytes;
  unsigned long trim_threshold;
  unsigned long top_pad;
  unsigned int  n_mmaps_max;
  unsigned long mmap_threshold;
  int           check_action;
  unsigned long max_sbrked_mem;
  unsigned long max_total_mem;
  unsigned int  n_mmaps;
  unsigned int  max_n_mmaps;
  unsigned long mmapped_mem;
  unsigned long max_mmapped_mem;
  int           using_malloc_checking;
};

Void_t*
mALLOC_GET_STATe()
{
  struct malloc_state* ms;
  int i;
  mbinptr b;

  ms = (struct malloc_state*)mALLOc(sizeof(*ms));
  if (!ms)
    return 0;
  (void)mutex_lock(&main_arena.mutex);
  ms->magic = MALLOC_STATE_MAGIC;
  ms->version = MALLOC_STATE_VERSION;
  ms->av[0] = main_arena.av[0];
  ms->av[1] = main_arena.av[1];
  for(i=0; i<NAV; i++) {
    b = bin_at(&main_arena, i);
    if(first(b) == b)
      ms->av[2*i+2] = ms->av[2*i+3] = 0; /* empty bin (or initial top) */
    else {
      ms->av[2*i+2] = first(b);
      ms->av[2*i+3] = last(b);
    }
  }
  ms->sbrk_base = sbrk_base;
  ms->sbrked_mem_bytes = sbrked_mem;
  ms->trim_threshold = trim_threshold;
  ms->top_pad = top_pad;
  ms->n_mmaps_max = n_mmaps_max;
  ms->mmap_threshold = mmap_threshold;
  ms->check_action = check_action;
  ms->max_sbrked_mem = max_sbrked_mem;
#ifdef NO_THREADS
  ms->max_total_mem = max_total_mem;
#else
  ms->max_total_mem = 0;
#endif
  ms->n_mmaps = n_mmaps;
  ms->max_n_mmaps = max_n_mmaps;
  ms->mmapped_mem = mmapped_mem;
  ms->max_mmapped_mem = max_mmapped_mem;
#if defined _LIBC || defined MALLOC_HOOKS
  ms->using_malloc_checking = using_malloc_checking;
#else
  ms->using_malloc_checking = 0;
#endif
  (void)mutex_unlock(&main_arena.mutex);
  return (Void_t*)ms;
}

int
#if __STD_C
mALLOC_SET_STATe(Void_t* msptr)
#else
mALLOC_SET_STATe(msptr) Void_t* msptr;
#endif
{
  struct malloc_state* ms = (struct malloc_state*)msptr;
  int i;
  mbinptr b;

#if defined _LIBC || defined MALLOC_HOOKS
  disallow_malloc_check = 1;
#endif
  ptmalloc_init();
  if(ms->magic != MALLOC_STATE_MAGIC) return -1;
  /* Must fail if the major version is too high. */
  if((ms->version & ~0xffl) > (MALLOC_STATE_VERSION & ~0xffl)) return -2;
  (void)mutex_lock(&main_arena.mutex);
  main_arena.av[0] = ms->av[0];
  main_arena.av[1] = ms->av[1];
  for(i=0; i<NAV; i++) {
    b = bin_at(&main_arena, i);
    if(ms->av[2*i+2] == 0)
      first(b) = last(b) = b;
    else {
      first(b) = ms->av[2*i+2];
      last(b) = ms->av[2*i+3];
      if(i > 0) {
        /* Make sure the links to the `av'-bins in the heap are correct. */
        first(b)->bk = b;
        last(b)->fd = b;
      }
    }
  }
  sbrk_base = ms->sbrk_base;
  sbrked_mem = ms->sbrked_mem_bytes;
  trim_threshold = ms->trim_threshold;
  top_pad = ms->top_pad;
  n_mmaps_max = ms->n_mmaps_max;
  mmap_threshold = ms->mmap_threshold;
  check_action = ms->check_action;
  max_sbrked_mem = ms->max_sbrked_mem;
#ifdef NO_THREADS
  max_total_mem = ms->max_total_mem;
#endif
  n_mmaps = ms->n_mmaps;
  max_n_mmaps = ms->max_n_mmaps;
  mmapped_mem = ms->mmapped_mem;
  max_mmapped_mem = ms->max_mmapped_mem;
  /* add version-dependent code here */
  if (ms->version >= 1) {
#if defined _LIBC || defined MALLOC_HOOKS
    /* Check whether it is safe to enable malloc checking, or whether
       it is necessary to disable it.  */
    if (ms->using_malloc_checking && !using_malloc_checking &&
        !disallow_malloc_check)
      __malloc_check_init ();
    else if (!ms->using_malloc_checking && using_malloc_checking) {
      __malloc_hook = 0;
      __free_hook = 0;
      __realloc_hook = 0;
      __memalign_hook = 0;
      using_malloc_checking = 0;
    }
#endif
  }

  (void)mutex_unlock(&main_arena.mutex);
  return 0;
}



#if defined _LIBC || defined MALLOC_HOOKS

/* A simple, standard set of debugging hooks.  Overhead is `only' one
   byte per chunk; still this will catch most cases of double frees or
   overruns.  The goal here is to avoid obscure crashes due to invalid
   usage, unlike in the MALLOC_DEBUG code. */

#define MAGICBYTE(p) ( ( ((size_t)p >> 3) ^ ((size_t)p >> 11)) & 0xFF )

/* Instrument a chunk with overrun detector byte(s) and convert it
   into a user pointer with requested size sz. */

static Void_t*
internal_function
#if __STD_C
chunk2mem_check(mchunkptr p, size_t sz)
#else
chunk2mem_check(p, sz) mchunkptr p; size_t sz;
#endif
{
  unsigned char* m_ptr = (unsigned char*)BOUNDED_N(chunk2mem(p), sz);
  size_t i;

  for(i = chunksize(p) - (chunk_is_mmapped(p) ? 2*SIZE_SZ+1 : SIZE_SZ+1);
      i > sz;
      i -= 0xFF) {
    if(i-sz < 0x100) {
      m_ptr[i] = (unsigned char)(i-sz);
      break;
    }
    m_ptr[i] = 0xFF;
  }
  m_ptr[sz] = MAGICBYTE(p);
  return (Void_t*)m_ptr;
}

/* Convert a pointer to be free()d or realloc()ed to a valid chunk
   pointer.  If the provided pointer is not valid, return NULL. */

static mchunkptr
internal_function
#if __STD_C
mem2chunk_check(Void_t* mem)
#else
mem2chunk_check(mem) Void_t* mem;
#endif
{
  mchunkptr p;
  INTERNAL_SIZE_T sz, c;
  unsigned char magic;

  p = mem2chunk(mem);
  if(!aligned_OK(p)) return NULL;
  if( (char*)p>=sbrk_base && (char*)p<(sbrk_base+sbrked_mem) ) {
    /* Must be a chunk in conventional heap memory. */
    if(chunk_is_mmapped(p) ||
       ( (sz = chunksize(p)), ((char*)p + sz)>=(sbrk_base+sbrked_mem) ) ||
       sz<MINSIZE || sz&MALLOC_ALIGN_MASK || !inuse(p) ||
       ( !prev_inuse(p) && (p->prev_size&MALLOC_ALIGN_MASK ||
                            (long)prev_chunk(p)<(long)sbrk_base ||
                            next_chunk(prev_chunk(p))!=p) ))
      return NULL;
    magic = MAGICBYTE(p);
    for(sz += SIZE_SZ-1; (c = ((unsigned char*)p)[sz]) != magic; sz -= c) {
      if(c<=0 || sz<(c+2*SIZE_SZ)) return NULL;
    }
    ((unsigned char*)p)[sz] ^= 0xFF;
  } else {
    unsigned long offset, page_mask = malloc_getpagesize-1;

    /* mmap()ed chunks have MALLOC_ALIGNMENT or higher power-of-two
       alignment relative to the beginning of a page.  Check this
       first. */
    offset = (unsigned long)mem & page_mask;
    if((offset!=MALLOC_ALIGNMENT && offset!=0 && offset!=0x10 &&
        offset!=0x20 && offset!=0x40 && offset!=0x80 && offset!=0x100 &&
        offset!=0x200 && offset!=0x400 && offset!=0x800 && offset!=0x1000 &&
        offset<0x2000) ||
       !chunk_is_mmapped(p) || (p->size & PREV_INUSE) ||
       ( (((unsigned long)p - p->prev_size) & page_mask) != 0 ) ||
       ( (sz = chunksize(p)), ((p->prev_size + sz) & page_mask) != 0 ) )
      return NULL;
    magic = MAGICBYTE(p);
    for(sz -= 1; (c = ((unsigned char*)p)[sz]) != magic; sz -= c) {
      if(c<=0 || sz<(c+2*SIZE_SZ)) return NULL;
    }
    ((unsigned char*)p)[sz] ^= 0xFF;
  }
  return p;
}

/* Check for corruption of the top chunk, and try to recover if
   necessary. */

static int
internal_function
#if __STD_C
top_check(void)
#else
top_check()
#endif
{
  mchunkptr t = top(&main_arena);
  char* brk, * new_brk;
  INTERNAL_SIZE_T front_misalign, sbrk_size;
  unsigned long pagesz = malloc_getpagesize;

  if((char*)t + chunksize(t) == sbrk_base + sbrked_mem ||
     t == initial_top(&main_arena)) return 0;

  if(check_action & 1)
    fprintf(stderr, "malloc: top chunk is corrupt\n");
  if(check_action & 2)
    abort();

  /* Try to set up a new top chunk. */
  brk = MORECORE(0);
  front_misalign = (unsigned long)chunk2mem(brk) & MALLOC_ALIGN_MASK;
  if (front_misalign > 0)
    front_misalign = MALLOC_ALIGNMENT - front_misalign;
  sbrk_size = front_misalign + top_pad + MINSIZE;
  sbrk_size += pagesz - ((unsigned long)(brk + sbrk_size) & (pagesz - 1));
  new_brk = (char*)(MORECORE (sbrk_size));
  if (new_brk == (char*)(MORECORE_FAILURE)) return -1;
  sbrked_mem = (new_brk - sbrk_base) + sbrk_size;

  top(&main_arena) = (mchunkptr)(brk + front_misalign);
  set_head(top(&main_arena), (sbrk_size - front_misalign) | PREV_INUSE);

  return 0;
}

static Void_t*
#if __STD_C
malloc_check(size_t sz, const Void_t *caller)
#else
malloc_check(sz, caller) size_t sz; const Void_t *caller;
#endif
{
  mchunkptr victim;
  INTERNAL_SIZE_T nb;

  if(request2size(sz+1, nb))
    return 0;
  (void)mutex_lock(&main_arena.mutex);
  victim = (top_check() >= 0) ? chunk_alloc(&main_arena, nb) : NULL;
  (void)mutex_unlock(&main_arena.mutex);
  if(!victim) return NULL;
  return chunk2mem_check(victim, sz);
}

static void
#if __STD_C
free_check(Void_t* mem, const Void_t *caller)
#else
free_check(mem, caller) Void_t* mem; const Void_t *caller;
#endif
{
  mchunkptr p;

  if(!mem) return;
  (void)mutex_lock(&main_arena.mutex);
  p = mem2chunk_check(mem);
  if(!p) {
    (void)mutex_unlock(&main_arena.mutex);
    if(check_action & 1)
      fprintf(stderr, "free(): invalid pointer %p!\n", mem);
    if(check_action & 2)
      abort();
    return;
  }
#if HAVE_MMAP
  if (chunk_is_mmapped(p)) {
    (void)mutex_unlock(&main_arena.mutex);
    munmap_chunk(p);
    return;
  }
#endif
#if 0 /* Erase freed memory. */
  memset(mem, 0, chunksize(p) - (SIZE_SZ+1));
#endif
  chunk_free(&main_arena, p);
  (void)mutex_unlock(&main_arena.mutex);
}

static Void_t*
#if __STD_C
realloc_check(Void_t* oldmem, size_t bytes, const Void_t *caller)
#else
realloc_check(oldmem, bytes, caller)
     Void_t* oldmem; size_t bytes; const Void_t *caller;
#endif
{
  mchunkptr oldp, newp;
  INTERNAL_SIZE_T nb, oldsize;

  if (oldmem == 0) return malloc_check(bytes, NULL);
  (void)mutex_lock(&main_arena.mutex);
  oldp = mem2chunk_check(oldmem);
  if(!oldp) {
    (void)mutex_unlock(&main_arena.mutex);
    if(check_action & 1)
      fprintf(stderr, "realloc(): invalid pointer %p!\n", oldmem);
    if(check_action & 2)
      abort();
    return malloc_check(bytes, NULL);
  }
  oldsize = chunksize(oldp);

  if(request2size(bytes+1, nb)) {
    (void)mutex_unlock(&main_arena.mutex);
    return 0;
  }

#if HAVE_MMAP
  if (chunk_is_mmapped(oldp)) {
#if HAVE_MREMAP
    newp = mremap_chunk(oldp, nb);
    if(!newp) {
#endif
      /* Note the extra SIZE_SZ overhead. */
      if(oldsize - SIZE_SZ >= nb) newp = oldp; /* do nothing */
      else {
        /* Must alloc, copy, free. */
        newp = (top_check() >= 0) ? chunk_alloc(&main_arena, nb) : NULL;
        if (newp) {
          MALLOC_COPY(BOUNDED_N(chunk2mem(newp), nb),
		      oldmem, oldsize - 2*SIZE_SZ, 0);
          munmap_chunk(oldp);
        }
      }
#if HAVE_MREMAP
    }
#endif
  } else {
#endif /* HAVE_MMAP */
    newp = (top_check() >= 0) ?
      chunk_realloc(&main_arena, oldp, oldsize, nb) : NULL;
#if 0 /* Erase freed memory. */
    nb = chunksize(newp);
    if(oldp<newp || oldp>=chunk_at_offset(newp, nb)) {
      memset((char*)oldmem + 2*sizeof(mbinptr), 0,
             oldsize - (2*sizeof(mbinptr)+2*SIZE_SZ+1));
    } else if(nb > oldsize+SIZE_SZ) {
      memset((char*)BOUNDED_N(chunk2mem(newp), bytes) + oldsize,
	     0, nb - (oldsize+SIZE_SZ));
    }
#endif
#if HAVE_MMAP
  }
#endif
  (void)mutex_unlock(&main_arena.mutex);

  if(!newp) return NULL;
  return chunk2mem_check(newp, bytes);
}

static Void_t*
#if __STD_C
memalign_check(size_t alignment, size_t bytes, const Void_t *caller)
#else
memalign_check(alignment, bytes, caller)
     size_t alignment; size_t bytes; const Void_t *caller;
#endif
{
  INTERNAL_SIZE_T nb;
  mchunkptr p;

  if (alignment <= MALLOC_ALIGNMENT) return malloc_check(bytes, NULL);
  if (alignment <  MINSIZE) alignment = MINSIZE;

  if(request2size(bytes+1, nb))
    return 0;
  (void)mutex_lock(&main_arena.mutex);
  p = (top_check() >= 0) ? chunk_align(&main_arena, nb, alignment) : NULL;
  (void)mutex_unlock(&main_arena.mutex);
  if(!p) return NULL;
  return chunk2mem_check(p, bytes);
}

#ifndef NO_THREADS

/* The following hooks are used when the global initialization in
   ptmalloc_init() hasn't completed yet. */

static Void_t*
#if __STD_C
malloc_starter(size_t sz, const Void_t *caller)
#else
malloc_starter(sz, caller) size_t sz; const Void_t *caller;
#endif
{
  INTERNAL_SIZE_T nb;
  mchunkptr victim;

  if(request2size(sz, nb))
    return 0;
  victim = chunk_alloc(&main_arena, nb);

  return victim ? BOUNDED_N(chunk2mem(victim), sz) : 0;
}

static void
#if __STD_C
free_starter(Void_t* mem, const Void_t *caller)
#else
free_starter(mem, caller) Void_t* mem; const Void_t *caller;
#endif
{
  mchunkptr p;

  if(!mem) return;
  p = mem2chunk(mem);
#if HAVE_MMAP
  if (chunk_is_mmapped(p)) {
    munmap_chunk(p);
    return;
  }
#endif
  chunk_free(&main_arena, p);
}

/* The following hooks are used while the `atfork' handling mechanism
   is active. */

static Void_t*
#if __STD_C
malloc_atfork (size_t sz, const Void_t *caller)
#else
malloc_atfork(sz, caller) size_t sz; const Void_t *caller;
#endif
{
  Void_t *vptr = NULL;
  INTERNAL_SIZE_T nb;
  mchunkptr victim;

  tsd_getspecific(arena_key, vptr);
  if(vptr == ATFORK_ARENA_PTR) {
    /* We are the only thread that may allocate at all.  */
    if(save_malloc_hook != malloc_check) {
      if(request2size(sz, nb))
        return 0;
      victim = chunk_alloc(&main_arena, nb);
      return victim ? BOUNDED_N(chunk2mem(victim), sz) : 0;
    } else {
      if(top_check()<0 || request2size(sz+1, nb))
        return 0;
      victim = chunk_alloc(&main_arena, nb);
      return victim ? chunk2mem_check(victim, sz) : 0;
    }
  } else {
    /* Suspend the thread until the `atfork' handlers have completed.
       By that time, the hooks will have been reset as well, so that
       mALLOc() can be used again. */
    (void)mutex_lock(&list_lock);
    (void)mutex_unlock(&list_lock);
    return mALLOc(sz);
  }
}

static void
#if __STD_C
free_atfork(Void_t* mem, const Void_t *caller)
#else
free_atfork(mem, caller) Void_t* mem; const Void_t *caller;
#endif
{
  Void_t *vptr = NULL;
  arena *ar_ptr;
  mchunkptr p;                          /* chunk corresponding to mem */

  if (mem == 0)                              /* free(0) has no effect */
    return;

  p = mem2chunk(mem);         /* do not bother to replicate free_check here */

#if HAVE_MMAP
  if (chunk_is_mmapped(p))                       /* release mmapped memory. */
  {
    munmap_chunk(p);
    return;
  }
#endif

  ar_ptr = arena_for_ptr(p);
  tsd_getspecific(arena_key, vptr);
  if(vptr != ATFORK_ARENA_PTR)
    (void)mutex_lock(&ar_ptr->mutex);
  chunk_free(ar_ptr, p);
  if(vptr != ATFORK_ARENA_PTR)
    (void)mutex_unlock(&ar_ptr->mutex);
}

#endif /* !defined NO_THREADS */

#endif /* defined _LIBC || defined MALLOC_HOOKS */



#ifdef _LIBC

/* default method of getting more storage */
__malloc_ptr_t
__default_morecore (int inc)
{
  __malloc_ptr_t result = (__malloc_ptr_t)sbrk (inc);
  if (result == (__malloc_ptr_t)-1)
    return NULL;
  return result;
}
 
/* We need a wrapper function for one of the additions of POSIX.  */
int
__posix_memalign (void **memptr, size_t alignment, size_t size)
{
  void *mem;

  /* Test whether the ALIGNMENT argument is valid.  It must be a power
     of two multiple of sizeof (void *).  */
  if (alignment % sizeof (void *) != 0 || (alignment & (alignment - 1)) != 0)
    return EINVAL;

  mem = __libc_memalign (alignment, size);

  if (mem != NULL)
    {
      *memptr = mem;
      return 0;
    }

  return ENOMEM;
}
weak_alias (__posix_memalign, posix_memalign)

weak_alias (__libc_calloc, __calloc) weak_alias (__libc_calloc, calloc)
weak_alias (__libc_free, __cfree) weak_alias (__libc_free, cfree)
weak_alias (__libc_free, __free) weak_alias (__libc_free, free)
weak_alias (__libc_malloc, __malloc) weak_alias (__libc_malloc, malloc)
weak_alias (__libc_memalign, __memalign) weak_alias (__libc_memalign, memalign)
weak_alias (__libc_realloc, __realloc) weak_alias (__libc_realloc, realloc)
weak_alias (__libc_valloc, __valloc) weak_alias (__libc_valloc, valloc)
weak_alias (__libc_pvalloc, __pvalloc) weak_alias (__libc_pvalloc, pvalloc)
weak_alias (__libc_mallinfo, __mallinfo) weak_alias (__libc_mallinfo, mallinfo)
weak_alias (__libc_mallopt, __mallopt) weak_alias (__libc_mallopt, mallopt)

weak_alias (__malloc_stats, malloc_stats)
weak_alias (__malloc_usable_size, malloc_usable_size)
weak_alias (__malloc_trim, malloc_trim)
weak_alias (__malloc_get_state, malloc_get_state)
weak_alias (__malloc_set_state, malloc_set_state)
#endif

/*

History:

    V2.6.4-pt3 Thu Feb 20 1997 Wolfram Gloger (wmglo@dent.med.uni-muenchen.de)
      * Added malloc_get/set_state() (mainly for use in GNU emacs),
        using interface from Marcus Daniels
      * All parameters are now adjustable via environment variables

    V2.6.4-pt2 Sat Dec 14 1996 Wolfram Gloger (wmglo@dent.med.uni-muenchen.de)
      * Added debugging hooks
      * Fixed possible deadlock in realloc() when out of memory
      * Don't pollute namespace in glibc: use __getpagesize, __mmap, etc.

    V2.6.4-pt Wed Dec  4 1996 Wolfram Gloger (wmglo@dent.med.uni-muenchen.de)
      * Very minor updates from the released 2.6.4 version.
      * Trimmed include file down to exported data structures.
      * Changes from H.J. Lu for glibc-2.0.

    V2.6.3i-pt Sep 16 1996  Wolfram Gloger (wmglo@dent.med.uni-muenchen.de)
      * Many changes for multiple threads
      * Introduced arenas and heaps

    V2.6.3 Sun May 19 08:17:58 1996  Doug Lea  (dl at gee)
      * Added pvalloc, as recommended by H.J. Liu
      * Added 64bit pointer support mainly from Wolfram Gloger
      * Added anonymously donated WIN32 sbrk emulation
      * Malloc, calloc, getpagesize: add optimizations from Raymond Nijssen
      * malloc_extend_top: fix mask error that caused wastage after
        foreign sbrks
      * Add linux mremap support code from HJ Liu

    V2.6.2 Tue Dec  5 06:52:55 1995  Doug Lea  (dl at gee)
      * Integrated most documentation with the code.
      * Add support for mmap, with help from
        Wolfram Gloger (Gloger@lrz.uni-muenchen.de).
      * Use last_remainder in more cases.
      * Pack bins using idea from  colin@nyx10.cs.du.edu
      * Use ordered bins instead of best-fit threshold
      * Eliminate block-local decls to simplify tracing and debugging.
      * Support another case of realloc via move into top
      * Fix error occurring when initial sbrk_base not word-aligned.
      * Rely on page size for units instead of SBRK_UNIT to
        avoid surprises about sbrk alignment conventions.
      * Add mallinfo, mallopt. Thanks to Raymond Nijssen
        (raymond@es.ele.tue.nl) for the suggestion.
      * Add `pad' argument to malloc_trim and top_pad mallopt parameter.
      * More precautions for cases where other routines call sbrk,
        courtesy of Wolfram Gloger (Gloger@lrz.uni-muenchen.de).
      * Added macros etc., allowing use in linux libc from
        H.J. Lu (hjl@gnu.ai.mit.edu)
      * Inverted this history list

    V2.6.1 Sat Dec  2 14:10:57 1995  Doug Lea  (dl at gee)
      * Re-tuned and fixed to behave more nicely with V2.6.0 changes.
      * Removed all preallocation code since under current scheme
        the work required to undo bad preallocations exceeds
        the work saved in good cases for most test programs.
      * No longer use return list or unconsolidated bins since
        no scheme using them consistently outperforms those that don't
        given above changes.
      * Use best fit for very large chunks to prevent some worst-cases.
      * Added some support for debugging

    V2.6.0 Sat Nov  4 07:05:23 1995  Doug Lea  (dl at gee)
      * Removed footers when chunks are in use. Thanks to
        Paul Wilson (wilson@cs.texas.edu) for the suggestion.

    V2.5.4 Wed Nov  1 07:54:51 1995  Doug Lea  (dl at gee)
      * Added malloc_trim, with help from Wolfram Gloger
        (wmglo@Dent.MED.Uni-Muenchen.DE).

    V2.5.3 Tue Apr 26 10:16:01 1994  Doug Lea  (dl at g)

    V2.5.2 Tue Apr  5 16:20:40 1994  Doug Lea  (dl at g)
      * realloc: try to expand in both directions
      * malloc: swap order of clean-bin strategy;
      * realloc: only conditionally expand backwards
      * Try not to scavenge used bins
      * Use bin counts as a guide to preallocation
      * Occasionally bin return list chunks in first scan
      * Add a few optimizations from colin@nyx10.cs.du.edu

    V2.5.1 Sat Aug 14 15:40:43 1993  Doug Lea  (dl at g)
      * faster bin computation & slightly different binning
      * merged all consolidations to one part of malloc proper
         (eliminating old malloc_find_space & malloc_clean_bin)
      * Scan 2 returns chunks (not just 1)
      * Propagate failure in realloc if malloc returns 0
      * Add stuff to allow compilation on non-ANSI compilers
          from kpv@research.att.com

    V2.5 Sat Aug  7 07:41:59 1993  Doug Lea  (dl at g.oswego.edu)
      * removed potential for odd address access in prev_chunk
      * removed dependency on getpagesize.h
      * misc cosmetics and a bit more internal documentation
      * anticosmetics: mangled names in macros to evade debugger strangeness
      * tested on sparc, hp-700, dec-mips, rs6000
          with gcc & native cc (hp, dec only) allowing
          Detlefs & Zorn comparison study (in SIGPLAN Notices.)

    Trial version Fri Aug 28 13:14:29 1992  Doug Lea  (dl at g.oswego.edu)
      * Based loosely on libg++-1.2X malloc. (It retains some of the overall
         structure of old version,  but most details differ.)

*/
