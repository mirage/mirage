#include <sys/socket.h>
#include <arpa/inet.h>
#include <string.h>

static const unsigned char V4mappedprefix[12]={0,0,0,0,0,0,0,0,0,0,0xff,0xff};

static char tohex(char hexdigit) {
  return hexdigit>9?hexdigit+'a'-10:hexdigit+'0';
}

static int fmt_xlong(char* s,unsigned int i) {
  char* bak=s;
  *s=tohex((i>>12)&0xf); if (s!=bak || *s!='0') ++s;
  *s=tohex((i>>8)&0xf); if (s!=bak || *s!='0') ++s;
  *s=tohex((i>>4)&0xf); if (s!=bak || *s!='0') ++s;
  *s=tohex(i&0xf);
  return s-bak+1;
}

static unsigned int fmt_ip6(char *s,const char ip[16]) {
  unsigned int len;
  unsigned int i;
  unsigned int temp;
  unsigned int compressing;
  unsigned int compressed;
  int j;

  len = 0; compressing = 0; compressed = 0;
  for (j=0; j<16; j+=2) {
    if (j==12 && !memcmp(ip,V4mappedprefix,12)) {
      inet_ntoa_r(*(struct in_addr*)(ip+12),s);
      temp=strlen(s);
      return len+temp;
    }
    temp = ((unsigned long) (unsigned char) ip[j] << 8) +
            (unsigned long) (unsigned char) ip[j+1];
    if (temp == 0 && !compressed) {
      if (!compressing) {
	compressing=1;
	if (j==0) {
	  *s++=':'; ++len;
	}
      }
    } else {
      if (compressing) {
	compressing=0; compressed=1;
	*s++=':'; ++len;
      }
      i = fmt_xlong(s,temp); len += i; s += i;
      if (j<14) {
	*s++ = ':';
	++len;
      }
    }
  }
  if (compressing) {
    *s++=':'; ++len;
  }
  *s=0;
  return len;
}

const char* inet_ntop(int AF, const void *CP, char *BUF, size_t LEN) {
  char buf[100];
  size_t len;
  if (AF==AF_INET) {
    inet_ntoa_r(*(struct in_addr*)CP,buf);
    len=strlen(buf);
  } else if (AF==AF_INET6) {
    len=fmt_ip6(buf,CP);
  } else
    return 0;
  if (len<LEN) {
    strcpy(BUF,buf);
    return BUF;
  }
  return 0;
}
