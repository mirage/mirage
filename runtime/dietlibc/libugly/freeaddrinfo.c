#include <sys/socket.h>
#include <stdlib.h>

void freeaddrinfo(struct addrinfo *res) {
  while (res) {
    struct addrinfo *duh;
    duh=res;
    res=res->ai_next;
    free(duh);
  }
}
