#include <stdio.h>
#include <pwd.h>

extern struct passwd __passwd_pw;
extern char __passwd_buf[1000];

struct passwd *fgetpwent(FILE * fp) {
  struct passwd* tmp;
  fgetpwent_r(fileno(fp),&__passwd_pw,__passwd_buf,sizeof(__passwd_buf),&tmp);
  return tmp;
}
