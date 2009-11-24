/* Standard debugging hooks for `malloc'.
   Copyright (C) 1990-1997, 1999, 2000, 2001 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Written May 1989 by Mike Haertel.

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

/* Modified for newlib, July 9, 2002 by Jeff Johnston */

#ifndef	_MALLOC_INTERNAL
# define _MALLOC_INTERNAL
# include <features.h>
# define _LIBC 1
# include <malloc.h>
# include <mcheck.h>
# include <stdint.h>
# include <stdio.h>
# include <stdlib.h>
# include <libintl.h>
# include <sys/cdefs.h>
#endif

/* Old hook values.  */
static void (*old_free_hook) __P ((__ptr_t ptr, __const __ptr_t));
static __ptr_t (*old_malloc_hook) __P ((__malloc_size_t size, const __ptr_t));
static __ptr_t (*old_realloc_hook) __P ((__ptr_t ptr, __malloc_size_t size,
					 __const __ptr_t));

/* Function to call when something awful happens.  */
static void (*abortfunc) __P ((enum mcheck_status));

/* Arbitrary magical numbers.  */
#define MAGICWORD	0xfedabeeb
#define MAGICFREE	0xd8675309
#define MAGICBYTE	((char) 0xd7)
#define MALLOCFLOOD	((char) 0x93)
#define FREEFLOOD	((char) 0x95)

struct hdr
  {
    __malloc_size_t size;	/* Exact size requested by user.  */
    unsigned long int magic;	/* Magic number to check header integrity.  */
    struct hdr *prev;
    struct hdr *next;
  };

/* This is the beginning of the list of all memory blocks allocated.
   It is only constructed if the pedantic testing is requested.  */
static struct hdr *root;

static int mcheck_used;

/* Nonzero if pedentic checking of all blocks is requested.  */
static int pedantic;

#if defined _LIBC || defined STDC_HEADERS || defined USG
# include <string.h>
# define flood memset
#else
static void flood __P ((__ptr_t, int, __malloc_size_t));
static void
flood (ptr, val, size)
     __ptr_t ptr;
     int val;
     __malloc_size_t size;
{
  char *cp = ptr;
  while (size--)
    *cp++ = val;
}
#endif

static enum mcheck_status checkhdr __P ((const struct hdr *));
static enum mcheck_status
checkhdr (hdr)
     const struct hdr *hdr;
{
  enum mcheck_status status;

  if (!mcheck_used)
    /* Maybe the mcheck used is disabled?  This happens when we find
       an error and report it.  */
    return MCHECK_OK;

  switch (hdr->magic ^ ((uintptr_t) hdr->prev + (uintptr_t) hdr->next))
    {
    default:
      status = MCHECK_HEAD;
      break;
    case MAGICFREE:
      status = MCHECK_FREE;
      break;
    case MAGICWORD:
      if (((char *) &hdr[1])[hdr->size] != MAGICBYTE)
	status = MCHECK_TAIL;
      else
	status = MCHECK_OK;
      break;
    }
  if (status != MCHECK_OK)
    {
      mcheck_used = 0;
      (*abortfunc) (status);
      mcheck_used = 1;
    }
  return status;
}

void
mcheck_check_all ()
{
  /* Walk through all the active blocks and test whether they were tempered
     with.  */
  struct hdr *runp = root;

  /* Temporarily turn off the checks.  */
  pedantic = 0;

  while (runp != NULL)
    {
      (void) checkhdr (runp);

      runp = runp->next;
    }

  /* Turn checks on again.  */
  pedantic = 1;
}

static void unlink_blk __P ((struct hdr *ptr));
static void
unlink_blk (ptr)
     struct hdr *ptr;
{
  if (ptr->next != NULL)
    {
      ptr->next->prev = ptr->prev;
      ptr->next->magic = MAGICWORD ^ ((uintptr_t) ptr->next->prev
				      + (uintptr_t) ptr->next->next);
    }
  if (ptr->prev != NULL)
    {
      ptr->prev->next = ptr->next;
      ptr->prev->magic = MAGICWORD ^ ((uintptr_t) ptr->prev->prev
				      + (uintptr_t) ptr->prev->next);
    }
  else
    root = ptr->next;
}

static void link_blk  __P ((struct hdr *ptr));
static void
link_blk (hdr)
     struct hdr *hdr;
{
  hdr->prev = NULL;
  hdr->next = root;
  root = hdr;
  hdr->magic = MAGICWORD ^ (uintptr_t) hdr->next;

  /* And the next block.  */
  if (hdr->next != NULL)
    {
      hdr->next->prev = hdr;
      hdr->next->magic = MAGICWORD ^ ((uintptr_t) hdr
				      + (uintptr_t) hdr->next->next);
    }
}

static void freehook __P ((__ptr_t, const __ptr_t));
static void
freehook (ptr, caller)
     __ptr_t ptr;
     const __ptr_t caller;
{
  if (pedantic)
    mcheck_check_all ();
  if (ptr)
    {
      struct hdr *hdr = ((struct hdr *) ptr) - 1;
      checkhdr (hdr);
      hdr->magic = MAGICFREE;
      unlink_blk (hdr);
      hdr->prev = hdr->next = NULL;
      flood (ptr, FREEFLOOD, hdr->size);
      ptr = (__ptr_t) hdr;
    }
  __free_hook = old_free_hook;
  if (old_free_hook != NULL)
    (*old_free_hook) (ptr, caller);
  else
    free (ptr);
  __free_hook = freehook;
}

static __ptr_t mallochook __P ((__malloc_size_t, const __ptr_t));
static __ptr_t
mallochook (size, caller)
     __malloc_size_t size;
     const __ptr_t caller;
{
  struct hdr *hdr;

  if (pedantic)
    mcheck_check_all ();

  __malloc_hook = old_malloc_hook;
  if (old_malloc_hook != NULL)
    hdr = (struct hdr *) (*old_malloc_hook) (sizeof (struct hdr) + size + 1,
					     caller);
  else
    hdr = (struct hdr *) malloc (sizeof (struct hdr) + size + 1);
  __malloc_hook = mallochook;
  if (hdr == NULL)
    return NULL;

  hdr->size = size;
  link_blk (hdr);
  ((char *) &hdr[1])[size] = MAGICBYTE;
  flood ((__ptr_t) (hdr + 1), MALLOCFLOOD, size);
  return (__ptr_t) (hdr + 1);
}

static __ptr_t reallochook __P ((__ptr_t, __malloc_size_t, const __ptr_t));
static __ptr_t
reallochook (ptr, size, caller)
     __ptr_t ptr;
     __malloc_size_t size;
     const __ptr_t caller;
{
  struct hdr *hdr;
  __malloc_size_t osize;

  if (pedantic)
    mcheck_check_all ();

  if (ptr)
    {
      hdr = ((struct hdr *) ptr) - 1;
      osize = hdr->size;

      checkhdr (hdr);
      unlink_blk (hdr);
      if (size < osize)
	flood ((char *) ptr + size, FREEFLOOD, osize - size);
    }
  else
    {
      osize = 0;
      hdr = NULL;
    }
  __free_hook = old_free_hook;
  __malloc_hook = old_malloc_hook;
  __realloc_hook = old_realloc_hook;
  if (old_realloc_hook != NULL)
    hdr = (struct hdr *) (*old_realloc_hook) ((__ptr_t) hdr,
					      sizeof (struct hdr) + size + 1,
					      caller);
  else
    hdr = (struct hdr *) realloc ((__ptr_t) hdr,
				  sizeof (struct hdr) + size + 1);
  __free_hook = freehook;
  __malloc_hook = mallochook;
  __realloc_hook = reallochook;
  if (hdr == NULL)
    return NULL;

  hdr->size = size;
  link_blk (hdr);
  ((char *) &hdr[1])[size] = MAGICBYTE;
  if (size > osize)
    flood ((char *) (hdr + 1) + osize, MALLOCFLOOD, size - osize);
  return (__ptr_t) (hdr + 1);
}

static void mabort __P ((enum mcheck_status status))
     __attribute__ ((noreturn));
static void
mabort (status)
     enum mcheck_status status;
{
  const char *msg;
  switch (status)
    {
    case MCHECK_OK:
      msg = _("memory is consistent, library is buggy\n");
      break;
    case MCHECK_HEAD:
      msg = _("memory clobbered before allocated block\n");
      break;
    case MCHECK_TAIL:
      msg = _("memory clobbered past end of allocated block\n");
      break;
    case MCHECK_FREE:
      msg = _("block freed twice\n");
      break;
    default:
      msg = _("bogus mcheck_status, library is buggy\n");
      break;
    }
  fprintf (stderr, "mcheck: %s", msg);
  fflush (stderr);
  abort ();
}

int
mcheck (func)
     void (*func) __P ((enum mcheck_status));
{
  abortfunc = (func != NULL) ? func : &mabort;

  /* These hooks may not be safely inserted if malloc is already in use.  */
  if (__malloc_initialized <= 0 && !mcheck_used)
    {
      /* We call malloc() once here to ensure it is initialized.  */
      void *p = malloc (0);
      free (p);

      old_free_hook = __free_hook;
      __free_hook = freehook;
      old_malloc_hook = __malloc_hook;
      __malloc_hook = mallochook;
      old_realloc_hook = __realloc_hook;
      __realloc_hook = reallochook;
      mcheck_used = 1;
    }

  return mcheck_used ? 0 : -1;
}

int
mcheck_pedantic (func)
      void (*func) __P ((enum mcheck_status));
{
  int res = mcheck (func);
  if (res == 0)
    pedantic = 1;
  return res;
}

enum mcheck_status
mprobe (__ptr_t ptr)
{
  return mcheck_used ? checkhdr (((struct hdr *) ptr) - 1) : MCHECK_DISABLED;
}
