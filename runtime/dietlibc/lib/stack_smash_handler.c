#include <write12.h>
#include <unistd.h>

/* this is only used with ProPolice in gcc 3.x */

void __stack_smash_handler(char* func,unsigned int damaged);
void __stack_smash_handler(char* func,unsigned int damaged) {
  char buf[sizeof(char*)*2+1];
  int i;
  for (i=0; i<(int)sizeof(buf)-1; ++i) {
    char c=damaged&0xf;
    c+=c<10?'0':'a';
    buf[sizeof(buf)-2-i]=c;
    damaged>>=4;
  }
  buf[sizeof(buf)-1]=0;
  __write2("stack smashed in ");
  __write2(func);
  __write2(" (value 0x");
  __write2(buf);
  __write2(")\n");
  _exit(127);
}


