/* Get loaded objects program headers.
   Copyright (C) 2001 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by Jakub Jelinek <jakub@redhat.com>, 2001.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with the GNU C Library; see the file COPYING.LIB.  If not,
   write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
   Boston, MA 02111-1307, USA.  */

#include <errno.h>
#include <ldsodefs.h>
#include <stddef.h>
#include <bits/libc-lock.h>

int
__dl_iterate_phdr (int (*callback) (struct dl_phdr_info *info,
				    size_t size, void *data), void *data)
{
  struct link_map *l;
  struct dl_phdr_info info;
  int ret = 0;

  /* Make sure we are alone.  */
#ifdef HAVE_DD_LOCK
    __lock_acquire(_dl_load_lock);
#endif


  for (l = _dl_loaded; l != NULL; l = l->l_next)
    {
      /* Skip the dynamic linker.  */
      if (l->l_phdr == NULL)
	continue;
      info.dlpi_addr = l->l_addr;
      info.dlpi_name = l->l_name;
      info.dlpi_phdr = l->l_phdr;
      info.dlpi_phnum = l->l_phnum;
      ret = callback (&info, sizeof (struct dl_phdr_info), data);
      if (ret)
	break;
    }

  /* Release the lock.  */
#ifdef HAVE_DD_LOCK
    __lock_release(_dl_load_lock);
#endif


  return ret;
}

#ifdef SHARED
weak_alias (__dl_iterate_phdr, dl_iterate_phdr);
#endif
