#include <sys/mman.h>

#include "_dl_int.h"

static void dec_referenced_libs(struct _dl_handle*dh) {
  Elf_Dyn* dyn_tab=dh->dynamic;
  int i;
  for(i=0;dyn_tab[i].d_tag;i++) {
    if (dyn_tab[i].d_tag==DT_NEEDED) {
      char *lib_name=dh->dyn_str_tab+dyn_tab[i].d_un.d_val;
#ifdef DEBUG
      pf(__FUNCTION__); pf(": lib: "); pf(lib_name); pf("\n");
#endif
      dlclose(_dl_find_lib(lib_name));
    }
  }
}

int dlclose(void*handle) {
  _dl_error_location="dlclose";
  if (handle) {
    struct _dl_handle*dh=handle;
    if (--(dh->lnk_count)) return 0;	/* not yet unreferenced */

#ifdef DEBUG
    pf(__FUNCTION__); pf(": "); pf(dh->name); pf("\n");
#endif
    if (dh->fini) dh->fini();
    dec_referenced_libs(dh);
#ifdef __DIET_LD_SO__
    if (_dl_sys_munmap(dh->mem_base,dh->mem_size)<0) return -1;
#else
    if (munmap(dh->mem_base,dh->mem_size)==-1) return -1;
#endif
    _dl_free_handle(handle);
#ifdef WANT_LD_SO_GDB_SUPPORT
    _r_debug.r_state=RT_DELETE;
    _dl_debug_state();
    _r_debug.r_state=RT_CONSISTENT;
    _dl_debug_state();
#endif
  }
  return 0;
}
