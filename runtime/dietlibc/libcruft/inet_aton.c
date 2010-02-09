#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdlib.h>

/* inet_aton() converts the Internet host address cp from the standard
 * numbers-and-dots  notation  into  binary data  and  stores it in the
 * structure that inp points to. inet_aton returns nonzero if the
 * address is valid, zero if not. */

/* problem is, inet_aton is historically quite, uh, lenient.
 * the following are all acceptable:
 *   0x7f000001 == 127.1 == 127.0.0.1.0 == 127.0.0.1
 * btw: 127.0.0.x.y == 127.0.0.(x|y)
 * and: 10.1.1 == 10.1.0.1 (huh?!)
 * and: 10 == 0.0.0.10 (?!?!?)
 * The Berkeley people must have been so stoned that they are still high.
 */

/* I hereby disclaim that I wrote this code. */
int inet_aton(const char *cp, struct in_addr *inp) {
  int i;
  unsigned int ip=0;
  char *tmp=(char*)cp;
  for (i=24; ;) {
    long j;
    j=strtoul(tmp,&tmp,0);
    if (*tmp==0) {
      ip|=j;
      break;
    }
    if (*tmp=='.') {
      if (j>255) return 0;
      ip|=(j<<i);
      if (i>0) i-=8;
      ++tmp;
      continue;
    }
    return 0;
  }
  inp->s_addr=htonl(ip);
  return 1;
}
