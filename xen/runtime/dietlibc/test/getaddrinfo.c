#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netdb.h>

int main() {
  struct addrinfo hints, *ai, *aitop;
  int gaierr;
  memset(&hints,0,sizeof(hints));
  hints.ai_family=AF_UNSPEC;
  hints.ai_flags=0;
  hints.ai_socktype=0;
  if ((gaierr = getaddrinfo(NULL,"6010",&hints,&aitop)) != 0) {
    printf("error: %.100s\n",gai_strerror(gaierr));
    exit(0);
  }
  ai=aitop;
  while (ai) {
    printf("found host %s, port %d, family %s, socktype %s\n",ai->ai_canonname,
	   ntohs(ai->ai_family==AF_INET6?((struct sockaddr_in6*)ai->ai_addr)->sin6_port:
				   ((struct sockaddr_in*)ai->ai_addr)->sin_port),
	   ai->ai_family==AF_INET6?"PF_INET6":"PF_INET",
	   ai->ai_socktype==SOCK_STREAM?"SOCK_STREAM":"SOCK_DGRAM");
    {
      char buf[100];
      inet_ntop(ai->ai_family,ai->ai_family==AF_INET6?
		(char*)&(((struct sockaddr_in6*)ai->ai_addr)->sin6_addr):
		(char*)&(((struct sockaddr_in*)ai->ai_addr)->sin_addr),buf,100);
      printf("  %s\n",buf);
    }
    ai=ai->ai_next;
  }
  return 0;
}
