#include <string.h>
#include <netdb.h>

extern int getservbyport_r(int port,const char* proto,
			   struct servent *res, char *buf, size_t buflen,
			   struct servent **res_sig) {
  while (!getservent_r(res,buf,buflen,res_sig))
    if (port==res->s_port && !strcmp(res->s_proto,proto)) goto ok;
  *res_sig=0;
ok:
  endservent();
  return *res_sig?0:-1;
}
