#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

unsigned long int inet_addr(const char *cp) {
  struct in_addr foo;
  if (inet_aton(cp,&foo))
    return foo.s_addr;
  else
    return (unsigned long int)-1;
}
