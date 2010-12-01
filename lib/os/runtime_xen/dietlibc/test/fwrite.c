#include <stdio.h>

int main() {
  FILE *f=fopen("test","wb");
  char buf[]="abcdefg";
  if (fwrite(buf,1,5,f)!=5) return -1;
  fclose(f);
  return 0;
}
