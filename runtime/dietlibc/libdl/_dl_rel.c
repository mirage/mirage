#include <dlfcn.h>

#include "_dl_int.h"

static void exit_now(void) {
#ifdef DEBUG
  pf(__func__": symbol not found\n");
#endif
  _exit(212);
}

unsigned long do_rel(struct _dl_handle * tmp_dl, unsigned long off)
{
  Elf_Rel *tmp = ((void*)tmp_dl->plt_rel)+off;

  int sym=ELF_R_SYM(tmp->r_info);

  register unsigned long sym_val;

#ifdef DEBUG
  pf(__func__": "); ph((unsigned long)tmp_dl); pf(" "); ph(off); pf(" on ");
  ph((long)tmp_dl->plt_rel); pf("\n");
  pf(__func__": @ "); ph((long)tmp->r_offset); pf(" with type ");
  ph(ELF_R_TYPE(tmp->r_info)); pf(" and sym "); ph(sym);
  pf(" symval "); ph(tmp_dl->dyn_sym_tab[sym].st_value); pf("\n");
#endif

  /* modify GOT for REAL symbol */
  //sym_val=((unsigned long)(tmp_dl->mem_base+tmp_dl->dyn_sym_tab[sym].st_value));
  sym_val=(unsigned long)_dl_sym(tmp_dl,sym);
  *((unsigned long*)(tmp_dl->mem_base+tmp->r_offset))=sym_val;

#ifdef DEBUG
  pf(__func__": sym "); ph(sym_val); pf("\n");
#endif
  /* JUMP (arg sysdep...) */
  if (sym_val) return sym_val;
  /* can't find symbol -> die now */
  return (unsigned long)exit_now;
}


