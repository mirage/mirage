#include "dietfeatures.h"
#include <errno.h>
#include "dieticonv.h"
#include <netinet/in.h>

size_t iconv(iconv_t cd, char* * inbuf, size_t *
		    inbytesleft, char* * outbuf, size_t * outbytesleft) {
  size_t result=0,i,j,k;
  int bits;
  unsigned char* in,* out;
  enum charset from=ic_from(cd);
  enum charset to=ic_to(cd);
  if (!inbuf || !*inbuf) return 0;
  in=(unsigned char*)(*inbuf);
  out=(unsigned char*)(*outbuf);
  k=0;
  while (*inbytesleft) {
    unsigned int v;
    v=*in;
    i=j=1;
    switch (from) {
    case UCS_2:
      if (*inbytesleft<2) {
starve:
	errno=EINVAL;
	return (size_t)-1;
      }
      v=(((unsigned long)in[0])<<8) |
        ((unsigned long)in[1]);
      i=2;
      break;
    case UCS_4:
      if (*inbytesleft<4) goto starve;
      v=(((unsigned long)in[0])<<24) |
        (((unsigned long)in[1])<<16) |
        (((unsigned long)in[2])<<8) |
        ((unsigned long)in[3]);
      i=4;
    case ISO_8859_1:
      break;
    case UTF_8:
      if (!(v&0x80)) break;
      for (i=0xC0; i!=0xFC; i=(i>>1)+0x80)
	if ((v&((i>>1)|0x80))==i) {
	  v&=~i;
	  break;
	}
      for (i=1; (in[i]&0xc0)==0x80; ++i) {
	if (i>*inbytesleft) goto starve;
	v=(v<<6)|(in[i]&0x3f);
      }
/*      printf("got %u in %u bytes, buflen %u\n",v,i,*inbytesleft); */
      break;
    case UTF_16:
      if (*inbytesleft<2) goto starve;
      if (v==0xff && in[1]==0xfe) {
	from=UTF_16_LE; *inbytesleft-=2; in+=2; goto utf16le;
      } else if (v==0xfe && in[1]==0xff) {
	from=UTF_16_BE; *inbytesleft-=2; in+=2; goto utf16be;
      }
ABEND:
      errno=EILSEQ;
      return (size_t)-1;
    case UTF_16_BE:
utf16be:
      if (*inbytesleft<2) goto starve;
      v=((unsigned long)in[0]<<8) | in[1];
joined:
      i=2;
      if (v>=0xd800 && v<=0xdfff) {
	long w;
	if (v>0xdbff) goto ABEND;
	if (*inbytesleft<4) goto starve;
	if (from==UTF_16_BE)
	  w=((unsigned long)in[2]<<8) | in[3];
	else
	  w=((unsigned long)in[3]<<8) | in[2];
	if (w<0xdc00 || w>0xdfff) goto ABEND;
	v=0x10000+(((v-0xd800) << 10) | (w-0xdc00));
	i=4;
      }
      break;
    case UTF_16_LE:
utf16le:
      v=((unsigned long)in[1]<<8) | in[0];
      goto joined;
    }
    if (v>=0xd800 && v<=0xd8ff) goto ABEND;	/* yuck!  in-band signalling! */
    switch (to) {
    case ISO_8859_1:
      if (*outbytesleft<1) goto bloat;
      if (v>0xff) ++result;
      *out=(unsigned char)v;
      break;
    case UCS_2:
      if (*outbytesleft<2) goto bloat;
      if (v>0xffff) ++result;
      out[0]=v>>8;
      out[1]=v&0xff;
      j=2;
      break;
    case UCS_4:
      if (*outbytesleft<4) goto bloat;
      out[0]=(v>>23)&0xff;
      out[1]=(v>>16)&0xff;
      out[2]=(v>>8)&0xff;
      out[3]=v&0xff;
      j=4;
      break;
    case UTF_8:
      if (v>=0x04000000) { bits=30; *out=0xFC; j=6; } else
      if (v>=0x00200000) { bits=24; *out=0xF8; j=5; } else
      if (v>=0x00010000) { bits=18; *out=0xF0; j=4; } else
      if (v>=0x00000800) { bits=12; *out=0xE0; j=3; } else
      if (v>=0x00000080) { bits=6; *out=0xC0; j=2; } else
			{ bits=0; *out=0; }
      *out|= (unsigned char)(v>>bits);
      if (*outbytesleft<j) {
bloat:
	errno=E2BIG;
	return (size_t)-1;
      }
      for (k=1; k<j; ++k) {
	bits-=6;
	out[k]=0x80+((v>>bits)&0x3F);
      }
      break;
    case UTF_16:
      if (*outbytesleft<4) goto bloat;
      to=UTF_16_LE;
      out[0]=0xff;
      out[1]=0xfe;
      out+=2; *outbytesleft-=2;
    case UTF_16_LE:
      if (v>0xffff) {
	long a,b;
	if (*outbytesleft<(j=4)) goto bloat;
	v-=0x10000;
	if (v>0xfffff) result++;
	a=0xd800+(v>>10); b=0xdc00+(v&0x3ff);
	out[1]=a>>8;
	out[0]=a&0xff;
	out[3]=b>>8;
	out[2]=b&0xff;
      } else {
	if (*outbytesleft<(j=2)) goto bloat;
	out[1]=(v>>8)&0xff;
	out[0]=v&0xff;
      }
      break;
    case UTF_16_BE:
      if (v>0xffff) {
	long a,b;
	if (*outbytesleft<(j=4)) goto bloat;
	v-=0x10000;
	if (v>0xfffff) result++;
	a=0xd800+(v>>10); b=0xdc00+(v&0x3ff);
	out[0]=a>>8;
	out[1]=a&0xff;
	out[2]=b>>8;
	out[3]=b&0xff;
      } else {
	if (*outbytesleft<(j=2)) goto bloat;
	out[0]=(v>>8)&0xff;
	out[1]=v&0xff;
      }
      break;
    }
    in+=i; *inbytesleft-=i;
    out+=j; *outbytesleft-=j;
  }
  *inbuf=(char*)in; *outbuf=(char*)out;
  return result;
}
