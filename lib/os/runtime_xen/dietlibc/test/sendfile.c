// #define _FILE_OFFSET_BITS 64
#include <sys/sendfile.h>
#include <stdio.h>

int main() {
  off_t o=0;
  int ret=sendfile(1,0,&o,100);
 
  if (ret<0)
      perror("sendfile()");

  printf("sendfile returned %d\n",ret);

return 0;    
}
