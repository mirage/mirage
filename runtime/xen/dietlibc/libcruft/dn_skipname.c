#include <resolv.h>

int dn_skipname(const unsigned char* cur,const unsigned char* eom) {
  const unsigned char* orig=cur;
  while (cur<eom) {
    if ((*cur&0xc)==0xc) { /* compression */
      if (cur+1<eom)
	return cur-orig+2;
      else
	return -1;
    } else
      if (*cur==0) return cur-orig+1;
      if (cur+*cur+1<eom)
	cur+=*cur+1;
      else
	return -1;
  }
  return -1;
}
