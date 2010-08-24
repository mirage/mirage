#include <string.h>
#include <netdb.h>

extern int getprotobyname_r(const char* name,
			    struct protoent *res, char *buf, size_t buflen,
			    struct protoent **res_sig) {
  while (!getprotoent_r(res,buf,buflen,res_sig)) {
    int i;
    if (!strcmp(res->p_name,name)) goto found;
    for (i=0; res->p_aliases[i]; ++i)
      if (!strcmp(res->p_aliases[i],name)) goto found;
  }
  *res_sig=0;
found:
  endprotoent();
  return *res_sig?0:-1;
}
