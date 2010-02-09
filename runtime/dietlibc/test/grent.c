#include <grp.h>
#include <stdio.h>

int main() {
  struct group gr,*tmp;
  char buf[1000];
  while (getgrent_r(&gr,buf,sizeof(buf),&tmp)==0) {
    int i;
    printf("name %s\tpassword %s\tgid %u\t[",gr.gr_name,gr.gr_passwd,gr.gr_gid);
    for (i=0; i<8; ++i) {
      if (gr.gr_mem[i])
	printf("%s%s",gr.gr_mem[i],gr.gr_mem[i+1]?",":"");
      else
	break;
    }
    printf("]\n");
  }
  return 0;
}
