#include <pwd.h>
#include <stdio.h>

int main(int argc,char *argv[]) {
#ifndef OLD
  struct passwd pw,*tmp;
  char buf[1000];
  while (getpwent_r(&pw,buf,sizeof(buf),&tmp)==0) {
    printf("name %s\npassword %s\nuid %u\ngid %u\ngecos %s\ndir %s\nshell %s\n",
	   pw.pw_name,pw.pw_passwd,pw.pw_uid,pw.pw_gid,pw.pw_gecos,pw.pw_dir,
	   pw.pw_shell);
  }
#else
  struct passwd *pw;
  while (pw=getpwent()) {
    printf("name %s\npassword %s\nuid %u\ngid %u\ngecos %s\ndir %s\nshell %s\n",
	   pw->pw_name,pw->pw_passwd,pw->pw_uid,pw->pw_gid,pw->pw_gecos,pw->pw_dir,
	   pw->pw_shell);
  }
#endif
  return 0;
}
