#include <shadow.h>

extern struct spwd __shadow_pw;
extern char __shadow_buf[1000];

struct spwd *getspent(void) {
  struct spwd* tmp;
  getspent_r(&__shadow_pw,__shadow_buf,sizeof(__shadow_buf),&tmp);
  return tmp;
}
