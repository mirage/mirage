#include "_dl_int.h"

static struct _dl_handle*_dl_addr_search_dh(char*addr)
{
  struct _dl_handle*bestdh,*dh;
  for (bestdh=0,dh=_dl_root_handle;dh;dh=dh->next)
    if (dh->mem_base<=(char*)addr &&
	(!bestdh||bestdh->mem_base<dh->mem_base))
      bestdh=dh;
  return bestdh;
}

static Elf_Sym*_dl_addr_search_sym(struct _dl_handle*dh,char*addr)
{
  Elf_Sym*bestsym,*sym;
  /* we assume the string table follows the symbol table (so does glibc) */
  for (bestsym=0,sym=dh->dyn_sym_tab;(char*)sym<dh->dyn_str_tab;++sym)
    if (dh->mem_base+sym->st_value<=addr &&
	(!bestsym||bestsym->st_value<sym->st_value))
      bestsym=sym;
  return bestsym;
}

int dladdr(void *addr, Dl_info *info) {
  struct _dl_handle*dh;
  dh=_dl_addr_search_dh((char*)addr);
  if (dh) {
    Elf_Sym*sym;
    sym=_dl_addr_search_sym(dh,(char*)addr);
    if (sym) {
      info->dli_fname=dh->l_name;
      info->dli_fbase=dh->mem_base;
      info->dli_sname=dh->dyn_str_tab+sym->st_name;
      info->dli_saddr=dh->mem_base+sym->st_value;
      return 1;
    }
  }
  return 0;
}
