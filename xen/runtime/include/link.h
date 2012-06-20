#ifndef _LINK_H
#define _LINK_H

#include <elf.h>

__BEGIN_DECLS

#define ElfW(type)	_ElfW (Elf, __ELF_NATIVE_CLASS, type)
#define _ElfW(e,w,t)	_ElfW_1 (e, w, _##t)
#define _ElfW_1(e,w,t)	e##w##t

#ifdef _GNU_SOURCE
struct dl_phdr_info
  {
    ElfW(Addr) dlpi_addr;
    const char *dlpi_name;
    const ElfW(Phdr) *dlpi_phdr;
    ElfW(Half) dlpi_phnum;

    unsigned long long int dlpi_adds;
    unsigned long long int dlpi_subs;
  };

extern int dl_iterate_phdr (int (*callback) (struct dl_phdr_info *info,
					     size_t size, void *data),
			    void *data);
#endif

__END_DECLS

#endif
