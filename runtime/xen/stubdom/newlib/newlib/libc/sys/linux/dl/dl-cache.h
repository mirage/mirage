/* Support for reading /etc/ld.so.cache files written by Linux ldconfig.
   Copyright (C) 1999, 2000 Free Software Foundation, Inc.
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

#include <stdint.h>

#ifndef _DL_CACHE_DEFAULT_ID
# define _DL_CACHE_DEFAULT_ID	3
#endif

#ifndef _dl_cache_check_flags
# define _dl_cache_check_flags(flags)			\
  ((flags) == 1 || (flags) == _DL_CACHE_DEFAULT_ID)
#endif

#ifndef SYSCONFDIR
# define SYSCONFDIR "/etc"
#endif

#ifndef LD_SO_CACHE
# define LD_SO_CACHE SYSCONFDIR "/ld.so.cache"
#endif

#define CACHEMAGIC "ld.so-1.7.0"

/* libc5 and glibc 2.0/2.1 use the same format.  For glibc 2.2 another
   format has been added in a compatible way:
   The beginning of the string table is used for the new table:
	old_magic
	nlibs
	libs[0]
	...
	libs[nlibs-1]
	pad, new magic needs to be aligned
	     - this is string[0] for the old format
	new magic - this is string[0] for the new format
	newnlibs
	...
	newlibs[0]
	...
	newlibs[newnlibs-1]
	string 1
	string 2
	...
*/
struct file_entry
{
  int flags;		/* This is 1 for an ELF library.  */
  unsigned int key, value; /* String table indices.  */
};

struct cache_file
{
  char magic[sizeof CACHEMAGIC - 1];
  unsigned int nlibs;
  struct file_entry libs[0];
};

#define CACHEMAGIC_NEW "glibc-ld.so.cache"
#define CACHE_VERSION "1.1"
#define CACHEMAGIC_VERSION_NEW CACHEMAGIC_NEW CACHE_VERSION


struct file_entry_new
{
  int32_t flags;		/* This is 1 for an ELF library.  */
  uint32_t key, value;		/* String table indices.  */
  uint32_t osversion;		/* Required OS version.	 */
  uint64_t hwcap;		/* Hwcap entry.	 */
};

struct cache_file_new
{
  char magic[sizeof CACHEMAGIC_NEW - 1];
  char version[sizeof CACHE_VERSION - 1];
  uint32_t nlibs;		/* Number of entries.  */
  uint32_t len_strings;		/* Size of string table. */
  uint32_t unused[5];		/* Leave space for future extensions
				   and align to 8 byte boundary.  */
  struct file_entry_new libs[0]; /* Entries describing libraries.  */
  /* After this the string table of size len_strings is found.	*/
};

/* Used to align cache_file_new.  */
#define ALIGN_CACHE(addr)				\
(((addr) + __alignof__ (struct cache_file_new) -1)	\
 & (~(__alignof__ (struct cache_file_new) - 1)))

static int
_dl_cache_libcmp (const char *p1, const char *p2)
{
  while (*p1 != '\0')
    {
      if (*p1 >= '0' && *p1 <= '9')
        {
          if (*p2 >= '0' && *p2 <= '9')
            {
	      /* Must compare this numerically.  */
	      int val1;
	      int val2;

	      val1 = *p1++ - '0';
	      val2 = *p2++ - '0';
	      while (*p1 >= '0' && *p1 <= '9')
	        val1 = val1 * 10 + *p1++ - '0';
	      while (*p2 >= '0' && *p2 <= '9')
	        val2 = val2 * 10 + *p2++ - '0';
	      if (val1 != val2)
		return val1 - val2;
	    }
	  else
            return 1;
        }
      else if (*p2 >= '0' && *p2 <= '9')
        return -1;
      else if (*p1 != *p2)
        return *p1 - *p2;
      else
	{
	  ++p1;
	  ++p2;
	}
    }
  return *p1 - *p2;
}
