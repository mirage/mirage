/* support function when linking against libgcc_eh.a
 *
 * see gcc sources _Unwind_Find_FDE() in unwind-dw2-fde-glibc.c
 *
 * Copyright (C) 2005 Markus F.X.J. Oberhumer
 * License: GNU GPL
 */

#include "dietfeatures.h"
#include <limits.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <elf.h>

#if __WORDSIZE == 64
#  define ElfW(type) Elf64_##type
#else
#  define ElfW(type) Elf32_##type
#endif


extern ElfW(Phdr) *_dl_phdr;
extern size_t _dl_phnum;

ElfW(Phdr) *_dl_phdr = NULL;
size_t _dl_phnum = 0;


void _dl_aux_init(ElfW(auxv_t) *av);
void _dl_aux_init(ElfW(auxv_t) *av)
{
    for ( ; av->a_type != AT_NULL; ++av)
    {
	switch (av->a_type)
	{
	case AT_PHDR:
            _dl_phdr = av->a_un.a_ptr;
            break;
	case AT_PHNUM:
            _dl_phnum = av->a_un.a_val;
            break;
	}
    }
}


void _dl_aux_init_from_envp(char **envp);
void _dl_aux_init_from_envp(char **envp)
{
    if (envp == NULL)
        return;
    while (*envp)
	++envp;
    /* now envp points to the tailing NULL-pointer of the environment */
    _dl_aux_init((ElfW(auxv_t) *) (envp + 1));
}


