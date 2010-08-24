#include <stdio.h>
#include <pwd.h>

int main() {
  struct passwd* pw=getpwnam("fnord");
  if (!pw) pw=getpwnam("alias");
  if (!pw) pw=getpwnam("nobody");
  if (!pw) pw=getpwnam("root");
  if (!pw) {
    puts("not found");
    return 0;
  }

  printf("name %s\npassword %s\nuid %u\ngid %u\ngecos %s\ndir %s\nshell %s\n",
	  pw->pw_name,pw->pw_passwd,pw->pw_uid,pw->pw_gid,pw->pw_gecos,pw->pw_dir,
	  pw->pw_shell);

  pw=getpwnam("doesNOThopefullnotexistsdar3245235wrafsdsfsdpl");
  if (pw) printf("getpwnam(\"doesNOThopefullnotexistsdar3245235wrafsdsfsdpl\" did not return null\n");
  return 0;	  
}
