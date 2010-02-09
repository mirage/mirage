#include <string.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <dlfcn.h>
#include <elf.h>

#include "_dl_int.h"

#define _ELF_DWN_ROUND(ps,n)	((n)&(~((ps)-1)))
#define _ELF_UP_ROUND(ps,n)	((((n)&((ps)-1))?(ps):0)+ _ELF_DWN_ROUND((ps),(n)))
#define _ELF_RST_ROUND(ps,n)	((n)&((ps)-1))

/* this is an arch specific "return jump" for the relocation */
void _dl_jump();

/*
 * this file is a Q. & D. hack ... don't think this is bug free or meaningfull
 */

static inline int map_flags(int flags)
{
  int perm = 0;
  if (flags & PF_X) perm|=PROT_EXEC;
  if (flags & PF_R) perm|=PROT_READ;
  if (flags & PF_W) perm|=PROT_WRITE;
  return perm;
}

static inline void *do_map_in(void *base, unsigned long length, int flags, int fd, unsigned long offset)
{
  register int op = MAP_PRIVATE;
  if (base) op|=MAP_FIXED;
  return mmap(base, length, map_flags(flags), op, fd, offset);
}

static struct _dl_handle *_dl_map_lib(const char*fn, const char*pathname, int fd, int flags)
{
  struct _dl_handle* ret=0;
  int ps=getpagesize();
  int i;
  unsigned char buf[1024];
  char *m=0,*d=0;

  unsigned long l;
  struct stat st;

  Elf_Ehdr *eh;
  Elf_Phdr *ph;

  int ld_nr=0;
  Elf_Phdr **ld=0;
  Elf_Phdr *dyn=0;

  if (fd==-1) return 0;

#ifdef DEBUG
  pf(__func__": "); pf(pathname); pf("\n");
#endif

  if (fstat(fd,&st)<0) {
    close(fd);
    _dl_error=2;
    return 0;
  }
  else {
    // use st_dev and st_ino for identification
  }

  if (read(fd, buf, 1024)<128) {
    close(fd);
    _dl_error=2;
    return 0;
  }

  eh=(Elf_Ehdr*)buf;
  ph=(Elf_Phdr*)&buf[eh->e_phoff];

  for (i=0; i<eh->e_phnum; i++) {
    if (ph[i].p_type==PT_LOAD) ++ld_nr;
  }
  ld=alloca(ld_nr*sizeof(Elf_Phdr));

  for (ld_nr=i=0; i<eh->e_phnum; i++) {
    if (ph[i].p_type==PT_LOAD) {
      ld[ld_nr++]=ph+i;
    }
    if (ph[i].p_type==PT_DYNAMIC) {
      dyn=ph+i;
    }
  }

  if (ld_nr==1) {
    unsigned long offset = _ELF_DWN_ROUND(ps,ld[0]->p_offset);
    unsigned long off = _ELF_RST_ROUND(ps,ld[0]->p_offset);
    unsigned long length = _ELF_UP_ROUND(ps,ld[0]->p_memsz+off);
    ret = _dl_get_handle();

    m = (char*)do_map_in(0, length, ld[0]->p_flags, fd, offset);
    if (m==MAP_FAILED) { _dl_free_handle(ret); close(fd); return 0; }

    /* zero pad bss */
    l = ld[0]->p_offset+ld[0]->p_filesz;
    memset(m+l,0,length-l);

    ret->mem_base=m;
    ret->mem_size=length;
  }
  else if (ld_nr==2) { /* aem... yes Quick & Really Dirty / for the avarage 99% */
//    unsigned long text_addr = _ELF_DWN_ROUND(ps,ld[0]->p_vaddr);	/* do we need this ? */
    unsigned long text_offset = _ELF_DWN_ROUND(ps,ld[0]->p_offset);
    unsigned long text_off = _ELF_RST_ROUND(ps,ld[0]->p_offset);
    unsigned long text_size = _ELF_UP_ROUND(ps,ld[0]->p_memsz+text_off);

    unsigned long data_addr = _ELF_DWN_ROUND(ps,ld[1]->p_vaddr);
    unsigned long data_offset = _ELF_DWN_ROUND(ps,ld[1]->p_offset);
    unsigned long data_off = _ELF_RST_ROUND(ps,ld[1]->p_offset);
    unsigned long data_size = _ELF_UP_ROUND(ps,ld[1]->p_memsz+data_off);
    unsigned long data_fsize = _ELF_UP_ROUND(ps,ld[1]->p_filesz+data_off);

    ret = _dl_get_handle();
    /* mmap all mem_blocks for *.so */
    m = (char*) do_map_in(0,text_size+data_size,ld[0]->p_flags,fd,text_offset);
    if (m==MAP_FAILED) { _dl_free_handle(ret); close(fd); return 0; }

    /* release data,bss part */
    mprotect(m+data_addr, data_size, PROT_NONE);

    /* mmap data,bss part */
    d = (char*) do_map_in(m+data_addr,data_fsize,ld[1]->p_flags,fd,data_offset);

    /* zero pad bss */
    l = data_off+ld[1]->p_filesz;
    memset(d+l,0,data_fsize-l);

    /* more bss ? */
    if (data_size>data_fsize) {
      l = data_size-data_fsize;
      mmap(d+data_fsize, l, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0);
    }

    ret->mem_base=m;
    ret->mem_size=text_size+data_size;
  }

  if (ret) {
    ret->lnk_count=1;
    ret->name=strdup(fn);
    ret->dyn_str_tab=(char*)m+dyn->p_vaddr;	/* missuse of field */
  }

  close(fd);
  return ret;
}

/* local alias */
static struct _dl_handle* __dl_dyn_scan(struct _dl_handle* dh, void* dyn_addr, int flags)
__attribute__ ((alias("_dl_dyn_scan")));

struct _dl_handle* _dl_dyn_scan(struct _dl_handle* dh, void* dyn_addr, int flags)
{
  Elf_Dyn* dyn_tab = dyn_addr;

  void (*init)()=0;
  unsigned long* got=0;
  void* jmprel=0;
  int pltreltype=0;
  int pltrelsize=0;
  unsigned long rel=0;
  int relent=0;
  int relsize=0;

  int i;

#ifdef DEBUG
  pf(__func__": pre dynamic scan "); ph((unsigned long)dh); pf("\n");
#endif
  dh->dyn_str_tab=0;
  dh->flags=flags;

  for(i=0;dyn_tab[i].d_tag;i++) {
//    DEBUG(printf("_dl_load dyn %d, %08lx\n",dyn_tab[i].d_tag, dyn_tab[i].d_un.d_val);)
    if (dyn_tab[i].d_tag==DT_HASH) {
      dh->hash_tab = (unsigned long*)(dh->mem_base+dyn_tab[i].d_un.d_ptr);
#ifdef DEBUG
      pf(__func__": have hash @ "); ph((long)dh->hash_tab); pf("\n");
#endif
    }
    else if (dyn_tab[i].d_tag==DT_SYMTAB) {
      dh->dyn_sym_tab = (Elf_Sym*)(dh->mem_base+dyn_tab[i].d_un.d_ptr);
#ifdef DEBUG
      pf(__func__": have dyn_sym_tab @ "); ph((long)dh->dyn_sym_tab); pf("\n");
#endif
    }
    else if (dyn_tab[i].d_tag==DT_STRTAB) {
      dh->dyn_str_tab = (char*)(dh->mem_base+dyn_tab[i].d_un.d_ptr);
#ifdef DEBUG
      pf(__func__": have dyn_str_tab @ "); ph((long)dh->dyn_str_tab); pf("\n");
#endif
    }

    /* INIT / FINI */
    else if (dyn_tab[i].d_tag==DT_FINI) {
      dh->fini = (void(*)(void))(dh->mem_base+dyn_tab[i].d_un.d_val);
#ifdef DEBUG
      pf(__func__": have fini @ "); ph((long)dh->fini); pf("\n");
#endif
    }
    else if (dyn_tab[i].d_tag==DT_INIT) {
      init = (void(*)(void))(dh->mem_base+dyn_tab[i].d_un.d_val);
#ifdef DEBUG
      pf(__func__": have init @ "); ph((long)init); pf("\n");
#endif
    }

    /* PLT / Relocation entries for PLT in GOT */
    else if (dyn_tab[i].d_tag==DT_PLTGOT) {
      got=(unsigned long*)(dh->mem_base+dyn_tab[i].d_un.d_val);
      dh->pltgot=got;
#ifdef DEBUG
      pf(__func__": have plt got @ "); ph((long)dh->pltgot); pf("\n");
#endif
    }
    else if (dyn_tab[i].d_tag==DT_PLTREL) {
      pltreltype=dyn_tab[i].d_un.d_val;
#ifdef DEBUG
      pf(__func__": have pltreltype @ "); ph((long)pltreltype); pf("\n");
#endif
    }
    else if (dyn_tab[i].d_tag==DT_PLTRELSZ) {
      pltrelsize=dyn_tab[i].d_un.d_val;
#ifdef DEBUG
      pf(__func__": have pltrelsize @ "); ph((long)pltrelsize); pf("\n");
#endif
    }
    else if (dyn_tab[i].d_tag==DT_JMPREL) {
      jmprel=(dh->mem_base+dyn_tab[i].d_un.d_val);
      dh->plt_rel=jmprel;
#ifdef DEBUG
      pf(__func__": have jmprel @ "); ph((long)jmprel); pf("\n");
#endif
    }

    /* Relocation */
    else if (dyn_tab[i].d_tag==DT_REL) {
      rel=(unsigned long)(dh->mem_base+dyn_tab[i].d_un.d_val);
#ifdef DEBUG
      pf(__func__": have rel @ "); ph((long)rel); pf("\n");
#endif
    }
    else if (dyn_tab[i].d_tag==DT_RELENT) {
      relent=dyn_tab[i].d_un.d_val;
#ifdef DEBUG
      pf(__func__": have relent  @ "); ph((long)relent); pf("\n");
#endif
    }
    else if (dyn_tab[i].d_tag==DT_RELSZ) {
      relsize=dyn_tab[i].d_un.d_val;
#ifdef DEBUG
      pf(__func__": have relsize @ "); ph((long)relsize); pf("\n");
#endif
    }

    else if (dyn_tab[i].d_tag==DT_TEXTREL) {
      _dl_free_handle(dh);
      _dl_error = 3;
      return 0;
    }
  }
  /* extra scan for rpath (if program) ... */
  if (dh->name==0) {
    for(i=0;dyn_tab[i].d_tag;i++) {
      if (dyn_tab[i].d_tag==DT_RPATH) {
	char *rpath=dh->dyn_str_tab+dyn_tab[i].d_un.d_val;
	_dl_set_rpath(rpath);
#ifdef DEBUG
	pf(__func__": have runpath: "); pf(rpath); pf("\n");
#endif
      }
    }
  }

#ifdef DEBUG
  pf(__func__": post dynamic scan "); ph((unsigned long)dh); pf("\n");
#endif

  if ((got=_dlsym(dh,"_GLOBAL_OFFSET_TABLE_"))) {
#ifdef DEBUG
    pf(__func__": found a GOT @ "); ph((unsigned long)got); pf("\n");
#endif
    /* GOT */
    got[0]+=(unsigned long)dh->mem_base;	/* reloc dynamic pointer */
    got[1] =(unsigned long)dh;
    got[2] =(unsigned long)(_dl_jump);	/* sysdep jump to _dl_rel */
    /* */
  }
  else {
    if (dh) {
      munmap(dh->mem_base,dh->mem_size);
      _dl_free_handle(dh);
    }
    _dl_error = 3;
    return 0;
  }

  /* load other libs */
  for(i=0;dyn_tab[i].d_tag;i++) {
    if (dyn_tab[i].d_tag==DT_NEEDED) {
      char *lib_name=dh->dyn_str_tab+dyn_tab[i].d_un.d_val;
#ifdef DEBUG
      pf(__func__": needed for this lib: "); pf(lib_name); pf("\n");
#endif
      _dl_queue_lib(lib_name,flags);
    }
  }

  if (_dl_open_dep()) {
    _dl_error = 1;
    return 0;
  }

  /* relocate */
  if (rel) {
#ifdef DEBUG
    pf(__func__": try to relocate some values\n");
#endif
    if (_dl_relocate(dh,(Elf_Rel*)rel,relsize/relent)) {
      munmap(dh->mem_base,dh->mem_size);
      _dl_free_handle(dh);
      return 0;
    }
  }

  /* do PTL / GOT relocation */
  if (pltreltype == DT_REL) {
    Elf_Rel *tmp = jmprel;
#ifdef DEBUG
    pf(__func__": rel got\n");
#endif
    for (;(char*)tmp<(((char*)jmprel)+pltrelsize);(char*)tmp=((char*)tmp)+sizeof(Elf_Rel)) {
      if ((flags&RTLD_NOW)) {
	unsigned long sym=(unsigned long)_dl_sym(dh,ELF_R_SYM(tmp->r_info));
	if (sym) *((unsigned long*)(dh->mem_base+tmp->r_offset))=sym;
	else {
	  _dl_free_handle(dh);
	  _dl_error = 4;
	  return 0;
	}
      }
      else
	*((unsigned long*)(dh->mem_base+tmp->r_offset))+=(unsigned long)dh->mem_base;
#if 0
      DEBUG("_dl_load rel @ %08lx with type %d -> %d\n",(long)dh->mem_base+tmp->r_offset,ELF_R_TYPE(tmp->r_info),ELF_R_SYM(tmp->r_info));
      DEBUG("_dl_load -> %08lx\n",*((unsigned long*)(dh->mem_base+tmp->r_offset)));
#endif
    }
  }
  if (pltreltype == DT_RELA) {
    Elf_Rela *tmp = jmprel;
#ifdef DEBUG
    pf(__func__": rela got\n");
#endif
    for (;(char*)tmp<(((char*)jmprel)+pltrelsize);(char*)tmp=((char*)tmp)+sizeof(Elf_Rela)) {
      if ((flags&RTLD_NOW)) {
	unsigned long sym=(unsigned long)_dl_sym(dh,ELF_R_SYM(tmp->r_info));
	if (sym) *((unsigned long*)(dh->mem_base+tmp->r_offset))=sym;
	else {
	  _dl_free_handle(dh);
	  _dl_error = 4;
	  return 0;
	}
      }
      else
	*((unsigned long*)(dh->mem_base+tmp->r_offset))=(unsigned long)(dh->mem_base+tmp->r_addend);
#if 0
      DEBUG("_dl_load rela @ %08lx with type %d -> %d\n",(long)dh->mem_base+tmp->r_offset,ELF_R_TYPE(tmp->r_info),ELF_R_SYM(tmp->r_info));
      DEBUG("_dl_load -> %08lx\n",*((unsigned long*)(dh->mem_base+tmp->r_offset)));
#endif
    }
  }

  /* _dl_load depending libs ... */
#ifdef DEBUG
  pf(__func__": post resolve, pre init\n");
#endif
  if (init) init();
#ifdef DEBUG
  pf(__func__": post init\n");
#endif

  return dh;
}

void *_dl_load(const char*fn, const char*pathname, int fd, int flags)
{
  struct _dl_handle* ret=0;
  if ((ret=_dl_map_lib(fn,pathname,fd,flags))) {
    ret=__dl_dyn_scan(ret,(void*)(ret->dyn_str_tab),flags);
  }
  return ret;
}
