/* Copyright (C) 1997, 1998, 1999, 2000, 2001 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by Ulrich Drepper <drepper@cygnus.com>, 1997.

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

#ifndef _GCONV_INT_H
#define _GCONV_INT_H	1

#include "gconv.h"
#include <libc-symbols.h>

__BEGIN_DECLS


/* Type to represent search path.  */
struct path_elem
{
  const char *name;
  size_t len;
};

/* Variable with search path for `gconv' implementation.  */
extern struct path_elem *__gconv_path_elem;
/* Maximum length of a single path element.  */
extern size_t __gconv_max_path_elem_len;


/* Structure for alias definition.  Simply two strings.  */
struct gconv_alias
{
  char *fromname;
  char *toname;
};


/* How many character should be conveted in one call?  */
#define GCONV_NCHAR_GOAL	8160


/* Structure describing one loaded shared object.  This normally are
   objects to perform conversation but as a special case the db shared
   object is also handled.  */
struct __gconv_loaded_object
{
  /* Name of the object.  It must be the first structure element.  */
  const char *name;

  /* Reference counter for the db functionality.  If no conversion is
     needed we unload the db library.  */
  int counter;

  /* The handle for the shared object.  */
  void *handle;

  /* Pointer to the functions the module defines.  */
  __gconv_fct fct;
  __gconv_init_fct init_fct;
  __gconv_end_fct end_fct;
};


/* Description for an available conversion module.  */
struct gconv_module
{
  const char *from_string;
  const char *to_string;

  int cost_hi;
  int cost_lo;

  const char *module_name;

  struct gconv_module *left;	/* Prefix smaller.  */
  struct gconv_module *same;	/* List of entries with identical prefix.  */
  struct gconv_module *right;	/* Prefix larger.  */
};


/* Internal data structure to represent transliteration module.  */
struct trans_struct
{
  const char *name;
  struct trans_struct *next;

  const char **csnames;
  size_t ncsnames;
  __gconv_trans_fct trans_fct;
  __gconv_trans_context_fct trans_context_fct;
  __gconv_trans_init_fct trans_init_fct;
  __gconv_trans_end_fct trans_end_fct;
};


/* Flags for `gconv_open'.  */
enum
{
  GCONV_AVOID_NOCONV = 1 << 0
};


/* Global variables.  */

/* Database of alias names.  */
extern void *__gconv_alias_db;

/* Array with available modules.  */
extern size_t __gconv_nmodules;
extern struct gconv_module *__gconv_modules_db;

/* Value of the GCONV_PATH environment variable.  */
extern const char *__gconv_path_envvar;


/* The gconv functions expects the name to be in upper case and complete,
   including the trailing slashes if necessary.  */
#define norm_add_slashes(str,suffix) \
  ({									      \
    const char *cp = (str);						      \
    char *result;							      \
    char *tmp;								      \
    size_t cnt = 0;							      \
    size_t suffix_len = (suffix) == NULL ? 0 : strlen (suffix);		      \
									      \
    while (*cp != '\0')							      \
      if (*cp++ == '/')							      \
	++cnt;								      \
									      \
    tmp = result = alloca (cp - (str) + 3 + suffix_len);		      \
    cp = (str);								      \
    while (*cp != '\0')							      \
      *tmp++ = __toupper_l (*cp++, &_nl_C_locobj);			      \
    if (cnt < 2)							      \
      {									      \
	*tmp++ = '/';							      \
	if (cnt < 1)							      \
	  {								      \
	    *tmp++ = '/';						      \
	    if (suffix != NULL)						      \
            {                                                                 \
	      tmp = memcpy (tmp, suffix, suffix_len);		              \
              tmp += suffix_len;                                              \
            }                                                                 \
	  }								      \
      }									      \
    *tmp = '\0';							      \
    result;								      \
  })


/* Return in *HANDLE decriptor for transformation from FROMSET to TOSET.  */
extern int __gconv_open (const char *toset, const char *fromset,
			 __gconv_t *handle, int flags)
     internal_function;

/* Free resources associated with transformation descriptor CD.  */
extern int __gconv_close (__gconv_t cd)
     internal_function;

/* Transform at most *INBYTESLEFT bytes from buffer starting at *INBUF
   according to rules described by CD and place up to *OUTBYTESLEFT
   bytes in buffer starting at *OUTBUF.  Return number of non-identical
   conversions in *IRREVERSIBLE if this pointer is not null.  */
extern int __gconv (__gconv_t cd, const unsigned char **inbuf,
		    const unsigned char *inbufend, unsigned char **outbuf,
		    unsigned char *outbufend, size_t *irreversible)
     internal_function;

/* Return in *HANDLE a pointer to an array with *NSTEPS elements describing
   the single steps necessary for transformation from FROMSET to TOSET.  */
extern int __gconv_find_transform (const char *toset, const char *fromset,
				   struct __gconv_step **handle,
				   size_t *nsteps, int flags)
     internal_function;

/* Search for transformation in cache data.  */
extern int __gconv_lookup_cache (const char *toset, const char *fromset,
				 struct __gconv_step **handle, size_t *nsteps,
				 int flags)
     internal_function;

/* Compare the two name for whether they are after alias expansion the
   same.  This function uses the cache and fails if none is
   loaded.  */
extern int __gconv_compare_alias_cache (const char *name1, const char *name2,
					int *result) internal_function;

/* Free data associated with a step's structure.  */
extern void __gconv_release_step (struct __gconv_step *step)
     internal_function;

/* Read all the configuration data and cache it.  */
extern void __gconv_read_conf (void);

/* Try to read module cache file.  */
extern int __gconv_load_cache (void) internal_function;

/* Determine the directories we are looking in.  */
extern void __gconv_get_path (void);

/* Comparison function to search alias.  */
extern int __gconv_alias_compare (const void *p1, const void *p2);

/* Clear reference to transformation step implementations which might
   cause the code to be unloaded.  */
extern int __gconv_close_transform (struct __gconv_step *steps,
				    size_t nsteps)
     internal_function;

/* Free all resources allocated for the transformation record when
   using the cache.  */
extern void __gconv_release_cache (struct __gconv_step *steps, size_t nsteps)
     internal_function;

/* Load shared object named by NAME.  If already loaded increment reference
   count.  */
extern struct __gconv_loaded_object *__gconv_find_shlib (const char *name)
     internal_function;

/* Release shared object.  If no further reference is available unload
   the object.  */
extern void __gconv_release_shlib (struct __gconv_loaded_object *handle)
     internal_function;

/* Fill STEP with information about builtin module with NAME.  */
extern void __gconv_get_builtin_trans (const char *name,
				       struct __gconv_step *step)
     internal_function;

/* Try to load transliteration step module.  */
extern int __gconv_translit_find (struct trans_struct *trans)
     internal_function;

/* Transliteration using the locale's data.  */
extern int __gconv_transliterate (struct __gconv_step *step,
				  struct __gconv_step_data *step_data,
				  void *trans_data,
				  __const unsigned char *inbufstart,
				  __const unsigned char **inbufp,
				  __const unsigned char *inbufend,
				  unsigned char **outbufstart,
				  size_t *irreversible);


/* Builtin transformations.  */
#ifdef _LIBC
# define __BUILTIN_TRANS(Name) \
  extern int Name (struct __gconv_step *step,				      \
		   struct __gconv_step_data *data,			      \
		   const unsigned char **inbuf,				      \
		   const unsigned char *inbufend,			      \
		   unsigned char **outbufstart, size_t *irreversible,	      \
		   int do_flush, int consume_incomplete)

__BUILTIN_TRANS (__gconv_transform_ascii_internal);
__BUILTIN_TRANS (__gconv_transform_internal_ascii);
__BUILTIN_TRANS (__gconv_transform_utf8_internal);
__BUILTIN_TRANS (__gconv_transform_internal_utf8);
__BUILTIN_TRANS (__gconv_transform_ucs2_internal);
__BUILTIN_TRANS (__gconv_transform_internal_ucs2);
__BUILTIN_TRANS (__gconv_transform_ucs2reverse_internal);
__BUILTIN_TRANS (__gconv_transform_internal_ucs2reverse);
__BUILTIN_TRANS (__gconv_transform_internal_ucs4);
__BUILTIN_TRANS (__gconv_transform_ucs4_internal);
__BUILTIN_TRANS (__gconv_transform_internal_ucs4le);
__BUILTIN_TRANS (__gconv_transform_ucs4le_internal);
__BUILTIN_TRANS (__gconv_transform_internal_utf16);
__BUILTIN_TRANS (__gconv_transform_utf16_internal);
# undef __BUITLIN_TRANS

#endif

__END_DECLS

#endif /* gconv_int.h */
