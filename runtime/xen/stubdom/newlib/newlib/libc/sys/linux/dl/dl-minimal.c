/* Minimal replacements for basic facilities used in the dynamic linker.
   Copyright (C) 1995,96,97,98,2000,2001 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

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

#include <errno.h>
#include <limits.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <ldsodefs.h>
#include <machine/weakalias.h>

#include <assert.h>

/* Minimal `malloc' allocator for use while loading shared libraries.
   No block is ever freed.  */

static void *alloc_ptr, *alloc_end, *alloc_last_block;

/* Declarations of global functions.  */
extern void weak_function free (void *ptr);
extern void * weak_function realloc (void *ptr, size_t n);
extern unsigned long int weak_function __strtoul_internal
(const char *nptr, char **endptr, int base, int group);
extern unsigned long int weak_function strtoul (const char *nptr,
						char **endptr, int base);


void * weak_function
malloc (size_t n)
{
#ifdef MAP_ANON
#define	_dl_zerofd (-1)
#else
  extern int _dl_zerofd;

  if (_dl_zerofd == -1)
    _dl_zerofd = _dl_sysdep_open_zero_fill ();
#define MAP_ANON 0
#endif

  if (alloc_end == 0)
    {
      /* Consume any unused space in the last page of our data segment.  */
      extern int _end;
      alloc_ptr = &_end;
      alloc_end = (void *) 0 + (((alloc_ptr - (void *) 0) + _dl_pagesize - 1)
				& ~(_dl_pagesize - 1));
    }

  /* Make sure the allocation pointer is ideally aligned.  */
  alloc_ptr = (void *) 0 + (((alloc_ptr - (void *) 0) + sizeof (double) - 1)
			    & ~(sizeof (double) - 1));

  if (alloc_ptr + n >= alloc_end)
    {
      /* Insufficient space left; allocate another page.  */
      caddr_t page;
      size_t nup = (n + _dl_pagesize - 1) & ~(_dl_pagesize - 1);
      page = __mmap (0, nup, PROT_READ|PROT_WRITE,
		     MAP_ANON|MAP_PRIVATE, _dl_zerofd, 0);
      assert (page != MAP_FAILED);
      if (page != alloc_end)
	alloc_ptr = page;
      alloc_end = page + nup;
    }

  alloc_last_block = (void *) alloc_ptr;
  alloc_ptr += n;
  return alloc_last_block;
}

/* We use this function occasionally since the real implementation may
   be optimized when it can assume the memory it returns already is
   set to NUL.  */
void * weak_function
calloc (size_t nmemb, size_t size)
{
  size_t total = nmemb * size;
  void *result = malloc (total);
  return memset (result, '\0', total);
}

/* This will rarely be called.  */
void weak_function
free (void *ptr)
{
  /* We can free only the last block allocated.  */
  if (ptr == alloc_last_block)
    alloc_ptr = alloc_last_block;
}

/* This is only called with the most recent block returned by malloc.  */
void * weak_function
realloc (void *ptr, size_t n)
{
  void *new;
  if (ptr == NULL)
    return malloc (n);
  assert (ptr == alloc_last_block);
  alloc_ptr = alloc_last_block;
  new = malloc (n);
  assert (new == ptr);
  return new;
}


/* Define our own version of the internal function used by strerror.  We
   only provide the messages for some common errors.  This avoids pulling
   in the whole error list.  */

char * weak_function
__strerror_r (int errnum, char *buf, size_t buflen)
{
  char *msg;

  switch (errnum)
    {
    case ENOMEM:
      msg = (char *) "Cannot allocate memory";
      break;
    case EINVAL:
      msg = (char *) "Invalid argument";
      break;
    case ENOENT:
      msg = (char *) "No such file or directory";
      break;
    case EPERM:
      msg = (char *) "Operation not permitted";
      break;
    case EIO:
      msg = (char *) "Input/output error";
      break;
    case EACCES:
      msg = (char *) "Permission denied";
      break;
    default:
      /* No need to check buffer size, all calls in the dynamic linker
	 provide enough space.  */
      msg = (char *) "Error";
      break;
    }

  return msg;
}

#ifndef NDEBUG

/* Define (weakly) our own assert failure function which doesn't use stdio.
   If we are linked into the user program (-ldl), the normal __assert_fail
   defn can override this one.  */

void weak_function
__assert_fail (const char *assertion,
	       const char *file, unsigned int line, const char *function)
{
  _dl_fatal_printf ("\
Inconsistency detected by ld.so: %s: %u: %s%sAssertion `%s' failed!\n",
		    file, line, function ?: "", function ? ": " : "",
		    assertion);

}

void weak_function
__assert_perror_fail (int errnum,
		      const char *file, unsigned int line,
		      const char *function)
{
  char errbuf[64];
  _dl_fatal_printf ("\
Inconsistency detected by ld.so: %s: %u: %s%sUnexpected error: %s\n",
		    file, line, function ?: "", function ? ": " : "",
		    __strerror_r (errnum, errbuf, sizeof (errbuf)));
}

#endif

unsigned long int weak_function
__strtoul_internal (const char *nptr, char **endptr, int base, int group)
{
  unsigned long int result = 0;
  long int sign = 1;

  while (*nptr == ' ' || *nptr == '\t')
    ++nptr;

  if (*nptr == '-')
    {
      sign = -1;
      ++nptr;
    }
  else if (*nptr == '+')
    ++nptr;

  if (*nptr < '0' || *nptr > '9')
    {
      if (endptr != NULL)
	*endptr = (char *) nptr;
      return 0UL;
    }

  assert (base == 0);
  base = 10;
  if (*nptr == '0')
    {
      if (nptr[1] == 'x' || nptr[1] == 'X')
	{
	  base = 16;
	  nptr += 2;
	}
      else
	base = 8;
    }

  while (*nptr >= '0' && *nptr <= '9')
    {
      unsigned long int digval = *nptr - '0';
      if (result > LONG_MAX / 10
	  || (result == ULONG_MAX / 10 && digval > ULONG_MAX % 10))
	{
	  errno = ERANGE;
	  if (endptr != NULL)
	    *endptr = (char *) nptr;
	  return ULONG_MAX;
	}
      result *= base;
      result += digval;
      ++nptr;
    }

  if (endptr != NULL)
    *endptr = (char *) nptr;
  return result * sign;
}
