/* Support for reading /etc/ld.so.cache files written by Linux ldconfig.
   Copyright (C) 1996,1997,1998,1999,2000,2001 Free Software Foundation, Inc.
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

#include <assert.h>
#include <unistd.h>
#include <ldsodefs.h>
#include <sys/mman.h>
#include <dl-cache.h>
#include <machine/dl-procinfo.h>
#include <machine/weakalias.h>

extern const char *_dl_platform;

#ifndef _DL_PLATFORMS_COUNT
# define _DL_PLATFORMS_COUNT 0
#endif

/* This is the starting address and the size of the mmap()ed file.  */
static struct cache_file *cache;
static struct cache_file_new *cache_new;
static size_t cachesize;

/* 1 if cache_data + PTR points into the cache.  */
#define _dl_cache_verify_ptr(ptr) (ptr < cache_data_size)

/* This is the cache ID we expect.  Normally it is 3 for glibc linked
   binaries.  */
int _dl_correct_cache_id = _DL_CACHE_DEFAULT_ID;

#define SEARCH_CACHE(cache) \
/* We use binary search since the table is sorted in the cache file.	      \
   The first matching entry in the table is returned.			      \
   It is important to use the same algorithm as used while generating	      \
   the cache file.  */							      \
do									      \
  {									      \
    left = 0;								      \
    right = cache->nlibs - 1;						      \
									      \
    while (left <= right)						      \
      {									      \
	__typeof__ (cache->libs[0].key) key;				      \
									      \
	middle = (left + right) / 2;					      \
									      \
	key = cache->libs[middle].key;					      \
									      \
	/* Make sure string table indices are not bogus before using	      \
	   them.  */							      \
	if (! _dl_cache_verify_ptr (key))				      \
	  {								      \
	    cmpres = 1;							      \
	    break;							      \
	  }								      \
									      \
	/* Actually compare the entry with the key.  */			      \
	cmpres = _dl_cache_libcmp (name, cache_data + key);		      \
	if (__builtin_expect (cmpres == 0, 0))				      \
	  {								      \
	    /* Found it.  LEFT now marks the last entry for which we	      \
	       know the name is correct.  */				      \
	    left = middle;						      \
									      \
	    /* There might be entries with this name before the one we	      \
	       found.  So we have to find the beginning.  */		      \
	    while (middle > 0)						      \
	      {								      \
		__typeof__ (cache->libs[0].key) key;			      \
									      \
		key = cache->libs[middle - 1].key;			      \
		/* Make sure string table indices are not bogus before	      \
		   using them.  */					      \
		if (! _dl_cache_verify_ptr (key)			      \
		    /* Actually compare the entry.  */			      \
		    || _dl_cache_libcmp (name, cache_data + key) != 0)	      \
		  break;						      \
		--middle;						      \
	      }								      \
									      \
	    do								      \
	      {								      \
		int flags;						      \
		__typeof__ (cache->libs[0]) *lib = &cache->libs[middle];      \
									      \
		/* Only perform the name test if necessary.  */		      \
		if (middle > left					      \
		    /* We haven't seen this string so far.  Test whether the  \
		       index is ok and whether the name matches.  Otherwise   \
		       we are done.  */					      \
		    && (! _dl_cache_verify_ptr (lib->key)		      \
			|| (_dl_cache_libcmp (name, cache_data + lib->key)    \
			    != 0)))					      \
		  break;						      \
									      \
		flags = lib->flags;					      \
		if (_dl_cache_check_flags (flags)			      \
		    && _dl_cache_verify_ptr (lib->value))		      \
		  {							      \
		    if (best == NULL || flags == _dl_correct_cache_id)	      \
		      {							      \
			HWCAP_CHECK;					      \
			best = cache_data + lib->value;			      \
									      \
			if (flags == _dl_correct_cache_id)		      \
			  /* We've found an exact match for the shared	      \
			     object and no general `ELF' release.  Stop	      \
			     searching.  */				      \
			  break;					      \
		      }							      \
		  }							      \
	      }								      \
	    while (++middle <= right);					      \
	    break;							      \
	}								      \
									      \
	if (cmpres < 0)							      \
	  left = middle + 1;						      \
	else								      \
	  right = middle - 1;						      \
      }									      \
  }									      \
while (0)



/* Look up NAME in ld.so.cache and return the file name stored there,
   or null if none is found.  */

const char *
internal_function
_dl_load_cache_lookup (const char *name)
{
  int left, right, middle;
  int cmpres;
  const char *cache_data;
  uint32_t cache_data_size;
  const char *best;

  if (cache == NULL)
    {
      /* Read the contents of the file.  */
      void *file = _dl_sysdep_read_whole_file (LD_SO_CACHE, &cachesize,
					       PROT_READ);

      /* We can handle three different cache file formats here:
	 - the old libc5/glibc2.0/2.1 format
	 - the old format with the new format in it
	 - only the new format
	 The following checks if the cache contains any of these formats.  */
      if (file != MAP_FAILED && cachesize > sizeof *cache
	  && memcmp (file, CACHEMAGIC, sizeof CACHEMAGIC - 1) == 0)
	{
	  size_t offset;
	  /* Looks ok.  */
	  cache = file;

	  /* Check for new version.  */
	  offset = ALIGN_CACHE (sizeof (struct cache_file)
				+ cache->nlibs * sizeof (struct file_entry));

	  cache_new = (struct cache_file_new *) ((void *) cache + offset);
	  if (cachesize < (offset + sizeof (struct cache_file_new))
	      || memcmp (cache_new->magic, CACHEMAGIC_VERSION_NEW,
			 sizeof CACHEMAGIC_VERSION_NEW - 1) != 0)
	    cache_new = (void *) -1;
	}
      else if (file != MAP_FAILED && cachesize > sizeof *cache_new
	       && memcmp (file, CACHEMAGIC_VERSION_NEW,
			  sizeof CACHEMAGIC_VERSION_NEW - 1) == 0)
	{
	  cache_new = file;
	  cache = file;
	}
      else
	{
	  if (file != MAP_FAILED)
	    munmap (file, cachesize);
	  cache = (void *) -1;
	}

      assert (cache != NULL);
    }

  if (cache == (void *) -1)
    /* Previously looked for the cache file and didn't find it.  */
    return NULL;

  best = NULL;

  if (cache_new != (void *) -1)
    {
      /* This file ends in static libraries where we don't have a hwcap.  */
      unsigned long int *hwcap;
      uint64_t platform;
      #pragma weak _dl_hwcap

      /* This is where the strings start.  */
      cache_data = (const char *) cache_new;

      /* Now we can compute how large the string table is.  */
      cache_data_size = (const char *) cache + cachesize - cache_data;

      hwcap = &_dl_hwcap;
      platform = _dl_string_platform (_dl_platform);
      if (platform != -1)
	platform = 1ULL << platform;

      /* Only accept hwcap if it's for the right platform.  */
#define HWCAP_CHECK \
      if (_dl_osversion	&& cache_new->libs[middle].osversion > _dl_osversion) \
	continue;							      \
      if (_DL_PLATFORMS_COUNT && platform != -1				      \
	  && (lib->hwcap & _DL_HWCAP_PLATFORM) != 0			      \
	  && (lib->hwcap & _DL_HWCAP_PLATFORM) != platform)		      \
	continue;							      \
      if (hwcap								      \
	  && ((lib->hwcap & *hwcap & ~_DL_HWCAP_PLATFORM) > *hwcap))	      \
	continue
      SEARCH_CACHE (cache_new);
    }
  else
    {
      /* This is where the strings start.  */
      cache_data = (const char *) &cache->libs[cache->nlibs];

      /* Now we can compute how large the string table is.  */
      cache_data_size = (const char *) cache + cachesize - cache_data;

#undef HWCAP_CHECK
#define HWCAP_CHECK do {} while (0)
      SEARCH_CACHE (cache);
    }

  /* Print our result if wanted.  */
  if (__builtin_expect (_dl_debug_mask & DL_DEBUG_LIBS, 0) && best != NULL)
    _dl_debug_printf ("  trying file=%s\n", best);

  return best;
}

#ifndef MAP_COPY
/* If the system does not support MAP_COPY we cannot leave the file open
   all the time since this would create problems when the file is replaced.
   Therefore we provide this function to close the file and open it again
   once needed.  */
void
_dl_unload_cache (void)
{
  if (cache != NULL && cache != (struct cache_file *) -1)
    {
      munmap (cache, cachesize);
      cache = NULL;
    }
}
#endif
