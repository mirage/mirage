#ifndef ___DL_INT_H__
#define ___DL_INT_H__

//#define DEBUG

#include "dietfeatures.h"

#if defined(__alpha__) || defined(__sparc64__) || defined(__x86_64__)
#define ELF_CLASS ELFCLASS64
#else
#define ELF_CLASS ELFCLASS32
#endif

#include <elf.h>
#define _GNU_SOURCE
#include <dlfcn.h>

#include "_dl_rel.h"

#if ELF_CLASS == ELFCLASS32

#define Elf_Addr	Elf32_Addr

#define Elf_Dyn 	Elf32_Dyn
#define Elf_Ehdr	Elf32_Ehdr
#define Elf_Phdr	Elf32_Phdr
#define Elf_Rel 	Elf32_Rel
#define Elf_Rela	Elf32_Rela
#define Elf_Sym 	Elf32_Sym

#define ELF_R_SYM(x)	ELF32_R_SYM((x))
#define ELF_R_TYPE(x)	ELF32_R_TYPE((x))

#define ELF_ST_BIND(x)	ELF32_ST_BIND((x))
#define ELF_ST_TYPE(x)	ELF32_ST_TYPE((x))

#else

#define Elf_Addr	Elf64_Addr

#define Elf_Dyn 	Elf64_Dyn
#define Elf_Ehdr	Elf64_Ehdr
#define Elf_Phdr	Elf64_Phdr
#define Elf_Rel 	Elf64_Rel
#define Elf_Rela	Elf64_Rela
#define Elf_Sym 	Elf64_Sym

#define ELF_R_SYM(x)	ELF64_R_SYM((x))
#define ELF_R_TYPE(x)	ELF64_R_TYPE((x))

#define ELF_ST_BIND(x)	ELF64_ST_BIND((x))
#define ELF_ST_TYPE(x)	ELF64_ST_TYPE((x))

#endif

#define RTLD_USER	0x10000000
#define RTLD_NOSONAME	0x20000000
#define LDSO_FLAGS	(RTLD_LAZY|RTLD_GLOBAL|RTLD_NOSONAME)

struct _dl_handle {
  /* the next fields HAVE to be in this order for GDB */
  char *	mem_base;	/* base address of maped *.so / or zero if program | Elf_Addr l_addr */
  char *	l_name;		/* Abloslute filename of this object */
  Elf_Dyn*	dynamic;	/* _DYNAMIC */

  struct _dl_handle *next;
  struct _dl_handle *prev;
  /* ok last GDB used part was prev */

  unsigned long flags;		/* FLAGS */

  char *	name;		/* name of shared object */

  /* basic */
  unsigned long mem_size;	/* len of mem block */
  unsigned long lnk_count;	/* reference count (other libraries) */

  /* lazy evaluator data */
  unsigned long*pltgot;		/* PLT/GOT */

  /* symbol resolve helper */
  unsigned int*hash_tab;	/* hash table */
  char *	dyn_str_tab;	/* dyn_name table */
  Elf_Sym *	dyn_sym_tab;	/* dynamic symbol table */
  _dl_rel_t*	plt_rel;	/* PLT relocation table */
  unsigned int*gnu_hash_tab;	/* GNU hash table */

  /* INIT / FINI */
  void (*init)(void);
  void (*fini)(void);
};

/* debug communication (GDB) (dyn-linker only) */
struct r_debug {
  int r_version;
  struct _dl_handle* r_map;
  void(*r_brk)();
  enum {
    RT_CONSISTENT,	/* mapping complete */
    RT_ADD,		/* begin add object */
    RT_DELETE,		/* begin del object */
  } r_state;
  Elf_Addr r_ldbase;
};

#define HASH_BUCKET_LEN(p)	(*((p)))
#define HASH_BUCKET(p)		((p)+2)

#define HASH_CHAIN_LEN(p)	(*((p)+1))
#define HASH_CHAIN(p)		((p)+2+HASH_BUCKET_LEN(p))

#define GNU_HASH_BUCKET_LEN(p)	(*((p)))
#define GNU_HASH_BUCKET(p,n)	((p)[(n)+1])
#define GNU_HASH_CHAIN(p,n)	((p)+(1+GNU_HASH_BUCKET_LEN(p)+(n)))

/* _dl_alloc.c */
#if 0
extern struct _dl_handle* _dl_root_handle;
extern struct _dl_handle* _dl_top_handle;
extern struct _dl_handle* _dl_free_list;
#endif
#ifndef __DIET_LD_SO__
void _dl_free_handle(struct _dl_handle* dh);
struct _dl_handle* _dl_get_handle();
struct _dl_handle* _dl_find_lib(const char* name);

/* _dl_open.c */
void *_dl_open(const char* filename, int flags);

/* _dl_load.c */
void *_dl_load(const char* filename, const char*pathname, int fd, int flags);
struct _dl_handle* _dl_dyn_scan(struct _dl_handle* dh, void* dyn_addr, int flags);

/* _dl_search.c */
void _dl_set_rpath(const char *path);
const char* _dl_get_rpath();
int _dl_search(char *buf, int len, const char *filename);

/* dlsym.c */
void *_dlsym(void*dh,const char*symbol);
void *_dl_sym_search_str(struct _dl_handle*h,const char*name);
void *_dl_sym(struct _dl_handle * h, int symbol);
void *_dl_sym_next(struct _dl_handle * h, int symbol);

/* _dl_queue.c */
int _dl_queue_lib(const char* name, int flags);
int _dl_open_dep();

/* _dl_relocate.c */
int _dl_relocate(struct _dl_handle* dh, _dl_rel_t *rel, int num);

/* dlerror.c */
extern unsigned int _dl_error;
extern const char* _dl_error_location;
extern const char* _dl_error_data;
#endif

#endif
