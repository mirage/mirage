#include <grp.h>
#include <string.h>

extern struct group __group_pw;
extern char __group_buf[1000];

struct group *getgrnam(const char* name) {
  struct group *tmp;
  getgrnam_r(name,&__group_pw,__group_buf,sizeof(__group_buf),&tmp);
  return tmp;
}
