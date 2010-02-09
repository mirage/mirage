#include <stdlib.h>
#include <stdio.h>
#include <elf.h>

extern char **environ;

int main() {
  register struct elf_aux {
    unsigned long type, value;
  } *x;
  int i;
  for (i=0; environ[i]; ++i) ;
  for (x=(struct elf_aux*)(environ+i+1); x->type; ++x) {
    printf("%d %x\n",x->type,x->value);
    if (x->type==AT_PAGESZ)
      printf("pagesize %d\n",x->value);
    else if (x->type==AT_SYSINFO)
      printf("vsyscall %p\n",x->value);
  }
  return 0;
}
