#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>

#include "_dl_int.h"

#ifdef __DIET_LD_SO__
static struct _dl_handle*_dl_root_handle=(struct _dl_handle*)0;
static struct _dl_handle*_dl_top_handle=(struct _dl_handle*)0;
static struct _dl_handle*_dl_free_list=(struct _dl_handle*)0;
#else
struct _dl_handle*_dl_root_handle=(struct _dl_handle*)0;
struct _dl_handle*_dl_top_handle=(struct _dl_handle*)0;
struct _dl_handle*_dl_free_list=(struct _dl_handle*)0;
#define _dl_lib_memset memset
#endif

#ifdef __DIET_LD_SO__
static
#endif
void _dl_free_handle(struct _dl_handle*dh) {
  if (_dl_root_handle==dh) _dl_root_handle=dh->next;
  if (_dl_top_handle ==dh)  _dl_top_handle=dh->prev;

  if (dh->next) dh->next->prev=dh->prev;
  if (dh->prev) dh->prev->next=dh->next;

  if ((dh->flags&RTLD_NOSONAME) && dh->name) free(dh->name);
  _dl_lib_memset(dh,0,sizeof(struct _dl_handle));
  dh->next=_dl_free_list;
  _dl_free_list=dh;
}

#ifdef __DIET_LD_SO__
static
#endif
struct _dl_handle*_dl_get_handle() {
  struct _dl_handle*tmp;

  if (_dl_free_list==0) {
    register int i,m;
#ifdef __DIET_LD_SO__
    tmp = (struct _dl_handle*)_dl_sys_mmap(0,at_pagesize,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    m=DIV(at_pagesize,sizeof(struct _dl_handle));
#else
    int ps=getpagesize();
    tmp = (struct _dl_handle*)mmap(0,ps,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    m=ps/sizeof(struct _dl_handle);
#endif
    for (i=m;i;) _dl_free_handle(tmp+(--i));
  }

  tmp = _dl_free_list;
  _dl_free_list = tmp->next;

  tmp->next=0;
  if (_dl_root_handle) {
    _dl_top_handle->next=tmp;
    tmp->prev=_dl_top_handle;
  } else
    _dl_root_handle = tmp;

  _dl_top_handle=tmp;

  return tmp;
}

#ifdef __DIET_LD_SO__
static
#endif
struct _dl_handle*_dl_find_lib(const char* name) {
  if (name) {
    if (_dl_root_handle) {
      struct _dl_handle*tmp;
      for (tmp=_dl_root_handle;tmp;tmp=tmp->next) {
	if (!tmp->name) continue;
	if (!_dl_lib_strcmp((const unsigned char*)tmp->name,(const unsigned char*)name)) return tmp;
      }
    }
  }
  return 0;
}
