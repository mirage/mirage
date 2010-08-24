#include <netdb.h>

static char hostentbuf[1024];

struct hostent* gethostent() {
  return gethostent_r(hostentbuf,sizeof(hostentbuf));
}
