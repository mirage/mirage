#include <string.h>
#include <unistd.h>
#include <netdb.h>

void herror(const char* s) {
  write(2,s,strlen(s));
  write(2,": DNS error.\n",13);
}
