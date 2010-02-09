#include <grp.h>

extern struct group __group_pw;
extern char __group_buf[1000];

struct group *getgrent(void) {
  struct group* tmp;
  getgrent_r(&__group_pw,__group_buf,sizeof(__group_buf),&tmp);
  return tmp;
}
