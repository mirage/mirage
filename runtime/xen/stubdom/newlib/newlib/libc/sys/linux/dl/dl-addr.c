/* Locate the shared object symbol nearest a given address.
   Copyright (C) 1996-2000, 2001 Free Software Foundation, Inc.
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

#include <dlfcn.h>
#include <stddef.h>
#include <ldsodefs.h>

int
internal_function
_dl_addr (const void *address, Dl_info *info)
{
  const ElfW(Addr) addr = DL_LOOKUP_ADDRESS (address);
  struct link_map *l, *match;
  const ElfW(Sym) *symtab, *matchsym;
  const char *strtab;
  ElfW(Word) strtabsize;

  /* Find the highest-addressed object that ADDRESS is not below.  */
  match = NULL;
  for (l = _dl_loaded; l; l = l->l_next)
    if (addr >= l->l_map_start && addr < l->l_map_end)
      {
	/* We know ADDRESS lies within L if in any shared object.
	   Make sure it isn't past the end of L's segments.  */
	size_t n = l->l_phnum;
	if (n > 0)
	  {
	    do
	      --n;
	    while (l->l_phdr[n].p_type != PT_LOAD);
	    if (addr >= (l->l_addr +
			 l->l_phdr[n].p_vaddr + l->l_phdr[n].p_memsz))
	      /* Off the end of the highest-addressed shared object.  */
	      continue;
	  }

	match = l;
	break;
      }

  if (match == NULL)
    return 0;

  /* Now we know what object the address lies in.  */
  info->dli_fname = match->l_name;
  info->dli_fbase = (void *) match->l_addr;

  /* If this is the main program the information is incomplete.  */
  if (__builtin_expect (info->dli_fbase == NULL, 0))
    {
      info->dli_fname = _dl_argv[0];
      info->dli_fbase = (void *) match->l_map_start;
    }

  symtab = (const void *) D_PTR (match, l_info[DT_SYMTAB]);
  strtab = (const void *) D_PTR (match, l_info[DT_STRTAB]);
  strtabsize = match->l_info[DT_STRSZ]->d_un.d_val;

  /* We assume that the string table follows the symbol table, because
     there is no way in ELF to know the size of the dynamic symbol table!!  */
  for (matchsym = NULL; (void *) symtab < (void *) strtab; ++symtab)
    if (addr >= match->l_addr + symtab->st_value
	&& ((symtab->st_size == 0 && addr == match->l_addr + symtab->st_value)
	    || addr < match->l_addr + symtab->st_value + symtab->st_size)
	&& symtab->st_name < strtabsize
	&& (matchsym == NULL || matchsym->st_value < symtab->st_value)
	&& (ELFW(ST_BIND) (symtab->st_info) == STB_GLOBAL
	    || ELFW(ST_BIND) (symtab->st_info) == STB_WEAK))
      matchsym = symtab;

  if (matchsym)
    {
      /* We found a symbol close by.  Fill in its name and exact address.  */
      info->dli_sname = strtab + matchsym->st_name;
      info->dli_saddr = (void *) (match->l_addr + matchsym->st_value);
    }
  else
    {
      /* No symbol matches.  We return only the containing object.  */
      info->dli_sname = NULL;
      info->dli_saddr = NULL;
    }

  return 1;
}
