#include <stdlib.h>
#include "dieticonv.h"

int iconv_close(iconv_t cd) {
  (void)cd;	/* shut gcc up about unused cd */
  return 0;
}
