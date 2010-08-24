#include <errno.h>
#include <resolv.h>
#include <netdb.h>

int *__h_errno_location(void);
int *__h_errno_location(void) { return &h_errno; }

int *h_errno_location(void) __attribute__((weak,alias("__h_errno_location")));
