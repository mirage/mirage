#include "_dl_int.h"

#include "elf_hash.h"
#include "gnu_hash.h"

static void*_dlsym_elfhash(struct _dl_handle*dh,const unsigned char*symbol) {
  unsigned long*sym=0;
  unsigned int hash =elf_hash(symbol);
  unsigned int bhash=MOD(hash, HASH_BUCKET_LEN(dh->hash_tab));
  unsigned int*chain=HASH_CHAIN(dh->hash_tab);
  unsigned char*name=(unsigned char*)dh->dyn_str_tab;
  unsigned int ind=HASH_BUCKET(dh->hash_tab)[bhash];

#ifdef DEBUG
//  pf(__FUNCTION__); pf(": bucket("); ph(bhash); pf(",\""); pf(symbol); pf("\")\n");
//  pf(__FUNCTION__); pf(": chain ("); ph(ind); pf(",\""); pf(symbol); pf("\")\n");
#endif

  while(ind) {
    int ptr=dh->dyn_sym_tab[ind].st_name;
#ifdef DEBUG
//    pf(__FUNCTION__); pf(": symbol(\""); pf(name+ptr); pf("\",\""); pf(symbol); pf("\")\n");
#endif
    if (_dl_lib_strcmp(name+ptr,symbol)==0 && dh->dyn_sym_tab[ind].st_value!=0) {
      if (dh->dyn_sym_tab[ind].st_shndx!=SHN_UNDEF) {
	sym=(unsigned long*)(dh->mem_base+dh->dyn_sym_tab[ind].st_value);
	break;	/* ok found ... */
      }
    }
    ind=chain[ind];
  }
#ifdef DEBUG
  pf(__FUNCTION__); pf(": symbol \""); pf(symbol); pf("\" @ "); ph((long)sym); pf("\n");
#endif
  return sym;
}
static void*_dlsym_gnuhash(struct _dl_handle*dh,const unsigned char*symbol) {
  unsigned long*sym=0;
  unsigned char*name=(unsigned char*)dh->dyn_str_tab;
  unsigned int hash =gnu_hash(symbol);
  unsigned int bhash=MOD(hash, GNU_HASH_BUCKET_LEN(dh->hash_tab));
  unsigned int ind  =GNU_HASH_BUCKET(dh->gnu_hash_tab,bhash);
#ifdef DEBUG
  //pf(__FUNCTION__); pf(": bucket("); ph(bhash); pf(",\""); pf(symbol); pf("\")\n");
  //pf(__FUNCTION__); pf(": chain ("); ph(ind); pf(",\""); pf(symbol); pf("\")\n");
#endif
  if (ind!=0xffffffff) {
    unsigned int*chain=GNU_HASH_CHAIN(dh->gnu_hash_tab,ind);
    unsigned int idx=chain[0];
    unsigned int i,nr=chain[1];
    chain+=2;
    for (i=0;i<nr;++i) {
      if (chain[i]==hash) {
	unsigned int ptr=dh->dyn_sym_tab[idx+i].st_name;
#ifdef DEBUG
	//pf(__FUNCTION__); pf(": symbol(\""); pf(name+ptr); pf("\",\""); pf(symbol); pf("\")\n");
#endif
	if (_dl_lib_strcmp(name+ptr,symbol)==0 && dh->dyn_sym_tab[idx+i].st_value!=0) {
	  if (dh->dyn_sym_tab[ind].st_shndx!=SHN_UNDEF) {
	    sym=(unsigned long*)(dh->mem_base+dh->dyn_sym_tab[idx+i].st_value);
	    break;
	  }
	}
      }
    }
  }
#ifdef DEBUG
  pf(__FUNCTION__); pf(": symbol \""); pf(symbol); pf("\" @ "); ph((long)sym); pf("\n");
#endif
  return sym;
}

#ifdef __DIET_LD_SO__
static
#endif
void *_dlsym(void* handle,const unsigned char* symbol) {
  if (handle) {
    struct _dl_handle*dh=(struct _dl_handle*)handle;
    // if the GNU hash-table is present... use it.
    if (dh->gnu_hash_tab)
      return _dlsym_gnuhash(dh,symbol);
    else
      return _dlsym_elfhash(dh,symbol);
  }
  return 0;
}

#ifdef __DIET_LD_SO__
static
#endif
void*_dl_sym_search_str(struct _dl_handle*dh_begin,const unsigned char*name) {
  void *sym=0;
  struct _dl_handle*tmp;
#ifdef DEBUG
  pf(__FUNCTION__); pf(": search for: "); pf(name); pf("\n");
#endif
  for (tmp=dh_begin;tmp && (!sym);tmp=tmp->next) {
//    if (!(tmp->flags&RTLD_GLOBAL)) continue;
#ifdef DEBUG
    pf(__FUNCTION__); pf(": searching in "); pf(tmp->name); pf("\n");
#endif
    sym=_dlsym((void*)tmp,name);
#ifdef DEBUG
    if (sym) { pf(__FUNCTION__); pf(": found: "); pf(name); pf(" @ "); ph((long)sym); pf("\n"); }
#endif
  }
  return sym;
}

#ifdef __DIET_LD_SO__
static
#endif
void*_dl_sym(struct _dl_handle*dh,int symbol) {
  char *name=dh->dyn_str_tab+dh->dyn_sym_tab[symbol].st_name;
  void*sym=_dl_sym_search_str(_dl_root_handle,(const unsigned char*)name);
#ifdef DEBUG
  pf(__FUNCTION__); pf(": "); ph(symbol); pf(" -> "); ph((long)sym); pf("\n");
#endif
  return sym;
}

#ifdef __DIET_LD_SO__
static
#endif
void*_dl_sym_next(struct _dl_handle*dh,int symbol) {
  char *name=dh->dyn_str_tab+dh->dyn_sym_tab[symbol].st_name;
  void*sym=_dl_sym_search_str(dh->next,(const unsigned char*)name);
#ifdef DEBUG
  pf(__FUNCTION__); pf(": "); ph(symbol); pf(" -> "); ph((long)sym); pf("\n");
#endif
  return sym;
}

void* dlsym(void* handle,const char* symbol) {
  void*h;
  if (handle==RTLD_DEFAULT || !handle /* RTLD_DEFAULT is NULL on glibc */ )
    h=_dl_sym_search_str(0,(const unsigned char*)symbol);
  else h=_dlsym(handle,(const unsigned char*)symbol);
  if (h==0) {
    _dl_error_location="dlsym";
    _dl_error_data=symbol;
    _dl_error=5;
  }
  return h;
}
