#include <pwd.h>
#include <string.h>

extern struct passwd __passwd_pw;
extern char __passwd_buf[1000];

struct passwd *getpwnam(const char* name) {
  struct passwd *tmp;
  getpwnam_r(name,&__passwd_pw,__passwd_buf,sizeof(__passwd_buf),&tmp);
  return tmp;
}
