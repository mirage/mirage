#include <shadow.h>
#include <stdio.h>

int main(int argc,char *argv[]) {
  struct spwd sp,*tmp;
  char buf[1000];
  while (getspent_r(&sp,buf,sizeof(buf),&tmp)==0) {
    printf("name %s\tpassword %s\n",sp.sp_namp,sp.sp_pwdp);
    printf("  %ld %d %d %d %d %d %d\n",sp.sp_lstchg, sp.sp_min,
	   sp.sp_max, sp.sp_warn, sp.sp_inact, sp.sp_expire, sp.sp_flag);
  }
  return 0;
}
