#include <resolv.h>

extern void __dns_readstartfiles(void);

int res_init(void) {
  _res.nscount=0;
  __dns_readstartfiles();
  return 0;
}
