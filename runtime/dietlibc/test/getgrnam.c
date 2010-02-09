#include <stdio.h>
#include <grp.h>

int main() {
  int i;
  struct group* gr=getgrnam("fnord");
  if (!gr) gr=getgrnam("uucp");
  if (!gr) {
    puts("not found");
    return 0;
  }
  printf("name %s\tpassword %s\tgid %u\t[",gr->gr_name,gr->gr_passwd,gr->gr_gid);
  for (i=0; i<8; ++i) {
    if (gr->gr_mem[i])
      printf("%s%s",gr->gr_mem[i],gr->gr_mem[i+1]?",":"");
    else
      break;
  }
  printf("]\n");
  return 0;
}
