#include <unistd.h>
#include <resolv.h>
#include "dietfeatures.h"

extern int __dns_fd;
#ifdef WANT_IPV6_DNS
extern int __dns_fd6;
#endif

void res_close(void) {
  if (__dns_fd!=-1) { close(__dns_fd); __dns_fd=-1; }
#ifdef WANT_IPV6_DNS
  if (__dns_fd6!=-1) { close(__dns_fd6); __dns_fd6=-1; }
#endif
}
