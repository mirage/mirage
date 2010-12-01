#define _GNU_SOURCE
#include <stdio.h>
#include <string.h>
#include <assert.h>

int main(int argc, char **argv) {
 char *path;
 int asprintlen=0;
  
 if ( argc < 2 ) return 111;
   
 asprintlen=asprintf(&path, "/proc" "/%s/stat", argv[1]);
 assert(strlen(path) == asprintlen);
	     
 printf("%s\n", path);
 asprintlen=asprintf(&path, "/proc" "/%d/stat", strlen(argv[1]));
 assert(strlen(path) == asprintlen);
 printf("%s\n", path);

return 0;
}
