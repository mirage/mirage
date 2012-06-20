#ifndef _DLFCN_H
#define _DLFCN_H 1

#include <sys/cdefs.h>

#define RTLD_LAZY	0x00000
#define RTLD_NOW	0x00001

#define RTLD_LOCAL	0x00000
#define RTLD_GLOBAL	0x10000

#define RTLD_DEFAULT	((void*)1)
#define RTLD_NEXT	((void*)2)

__BEGIN_DECLS

void *dlopen (const char *filename, int flag);
const char *dlerror(void);
void *dlsym(void *handle, const char *symbol);
int dlclose (void *handle);

#ifdef _GNU_SOURCE
typedef struct
{
  const char *dli_fname;
  void *dli_fbase;
  const char *dli_sname;
  void *dli_saddr;
} Dl_info;

int dladdr(void *addr, Dl_info *info);
#endif

__END_DECLS

#endif
