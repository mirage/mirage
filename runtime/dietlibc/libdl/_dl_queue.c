#include <dlfcn.h>
#include "_dl_int.h"

#define MAX_QUEUE 64

static int _dl_queue_start=0;
static int _dl_queue_stop=0;

static struct {
  const char*name;
  int flags;
} _dl_queue[MAX_QUEUE];

#ifdef __DIET_LD_SO__
static
#endif
int _dl_queue_lib(const char*name,int flags) {
  struct _dl_handle*ret;
  if ((ret=_dl_find_lib(name))) ++(ret->lnk_count);
  else {
    register int tmp;
    if ((tmp=_dl_queue_stop+1)>=MAX_QUEUE) tmp=0;
    if (tmp==_dl_queue_start) return -1;
    _dl_queue[_dl_queue_stop].name=name;
    _dl_queue[_dl_queue_stop].flags=flags;
    _dl_queue_stop=tmp;
  }
  return 0;
}

#ifdef __DIET_LD_SO__
static
#endif
int _dl_open_dep() {
  while (_dl_queue_start!=_dl_queue_stop) {
    int tmp=_dl_queue_start;
    if (++_dl_queue_start>=MAX_QUEUE) _dl_queue_start=0;
    if (!_dlopen(_dl_queue[tmp].name,_dl_queue[tmp].flags)) return 1;
  }
  return 0;
}
