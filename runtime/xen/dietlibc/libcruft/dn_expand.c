#include <netinet/in.h>
#include <arpa/nameser.h>
#include <resolv.h>

extern int __dns_decodename(const unsigned char *packet,unsigned int ofs,unsigned char *dest,
			    unsigned int maxlen,const unsigned char* behindpacket);

int dn_expand(const unsigned char *msg, const unsigned char *eomorig, const unsigned char *comp_dn, unsigned char *exp_dn, int length) {
  return __dns_decodename(msg,comp_dn-msg,exp_dn,length,eomorig)-(comp_dn-msg);
}

