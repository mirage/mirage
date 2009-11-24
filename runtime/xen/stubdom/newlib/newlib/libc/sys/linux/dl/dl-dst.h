/* Handling of dynamic sring tokens.
   Copyright (C) 1999, 2001 Free Software Foundation, Inc.
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

/* Determine the number of DST elements in the name.  Only if IS_PATH is
   nonzero paths are recognized (i.e., multiple, ':' separated filenames).  */
#define DL_DST_COUNT(name, is_path) \
  ({									      \
    size_t __cnt = 0;							      \
    const char *__sf = strchr (name, '$');				      \
									      \
    if (__builtin_expect (__sf != NULL, 0))				      \
      __cnt = _dl_dst_count (__sf, is_path);				      \
									      \
    __cnt; })

/* Prototype for used function.  */
extern size_t _dl_dst_count (const char *name, int is_path);


/* Guess from the number of DSTs the length of the result string.  */
#define DL_DST_REQUIRED(l, name, len, cnt) 1024

/* Perform the DST substitution.  */
#define DL_DST_SUBSTITUTE(l, name, res, is_path) \
  _dl_dst_substitute (l, name, res, is_path)

/* Prototype for used function.  */
extern char *_dl_dst_substitute (struct link_map *l, const char *name,
				 char *result, int is_path);
