#include <pwd.h>
#include <string.h>
#include <stdlib.h>

extern struct passwd __passwd_pw;
extern char __passwd_buf[1000];

struct passwd *getpwuid(uid_t uid) {
  struct passwd *tmp;
  getpwuid_r(uid,&__passwd_pw,__passwd_buf,sizeof(__passwd_buf),&tmp);
  return tmp;
}
