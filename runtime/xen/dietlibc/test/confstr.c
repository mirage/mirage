#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#include <stdlib.h>
#include <string.h>


#define ps(s) write(2,s,sizeof(s)-1)
#define die(s) do { ps(s); exit(1); } while(0)


int main(int argc,char*argv[]) {
  char*path;
  size_t len;
  len = confstr(_CS_PATH, (char *) NULL, 0);
  if (!(path = malloc(1 + len)))
    die("malloc...\n");
  path[0] = ':';
  confstr(_CS_PATH, path+1, len);
  write(1,path,len);
  return 0;
}

