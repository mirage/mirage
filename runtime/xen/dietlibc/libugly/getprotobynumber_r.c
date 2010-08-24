#include <string.h>
#include <netdb.h>

extern int getprotobynumber_r(int proto,
			   struct protoent *res, char *buf, size_t buflen,
			   struct protoent **res_sig) {
  while (!getprotoent_r(res,buf,buflen,res_sig))
    if (proto==res->p_proto) goto found;
  *res_sig=0;
found:
  endprotoent();
  return *res_sig?0:-1;
}
