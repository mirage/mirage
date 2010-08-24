#include <string.h>

extern const char __sys_err_unknown[];

int strerror_r(int errnum, char *buf, size_t n) {
  const char* x=strerror(errnum);
  if (x==__sys_err_unknown || n<1) return -1;
  strncpy(buf,strerror(errnum),n);
  buf[n-1]=0;
  return 0;
}
