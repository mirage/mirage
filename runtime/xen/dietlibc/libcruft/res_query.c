#include <resolv.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <poll.h>
#include <unistd.h>
#include <errno.h>
#include <arpa/nameser.h>
#include <fcntl.h>
#include "dietfeatures.h"

extern void __dns_make_fd(void);
extern int __dns_fd;
#ifdef WANT_IPV6_DNS
extern void __dns_make_fd6(void);
extern int __dns_fd6;
#endif

extern void __dns_readstartfiles(void);

#ifdef WANT_PLUGPLAY_DNS
int __dns_plugplay_interface;
#endif

int res_query(const char *dname, int class, int type, unsigned char *answer, int anslen) {
  unsigned char packet[512];
  int size;
  struct pollfd duh[2];
#ifndef WANT_IPV6_DNS
  __dns_make_fd();
#endif

  __dns_readstartfiles();
  if ((size=res_mkquery(QUERY,dname,class,type,0,0,0,(char*)packet,512))<0) { h_errno=NO_RECOVERY; return -1; }
  {
    {
      int i;	/* current server */
      int j;	/* timeout count down */
      struct timeval last,now;
#ifdef WANT_PLUGPLAY_DNS
      struct timeval first;
      static int pnpfd=-1;
#ifdef WANT_IPV6_DNS
      static struct sockaddr_in6 pnpsa6;
#endif
      static struct sockaddr_in pnpsa4;
      static int v4pnp=0;
      int islocal=0;

      gettimeofday(&first,0);
      {
	char* x=strchr(dname,'.');
	if (x) {
	  if (!memcmp(x,".local",6))
	    if (x[6]==0 || (x[6]=='.' && x[7]==0))
	      islocal=1;
	}
      }
      if (islocal) {
	if (pnpfd<0) {
	  pnpfd=socket(PF_INET6,SOCK_DGRAM,IPPROTO_UDP);
	  if (pnpfd==-1 && errno==EAFNOSUPPORT) {
	    pnpfd=socket(PF_INET,SOCK_DGRAM,IPPROTO_UDP);
	    v4pnp=1;
	  }
	  if (pnpfd>=0) {
	    int one=1;
	    fcntl(pnpfd,F_SETFD,FD_CLOEXEC);
	    if (!v4pnp)
	      setsockopt(pnpfd,IPPROTO_IPV6,IPV6_HOPLIMIT,&one,sizeof one);
	    setsockopt(pnpfd,SOL_IP,IP_RECVTTL,&one,sizeof one);
	    setsockopt(pnpfd,SOL_IP,IP_PKTINFO,&one,sizeof one);
	  }
	}
#ifdef WANT_IPV6_DNS
	if (!v4pnp) {
	  memset(&pnpsa6,0,sizeof(pnpsa6));
	  pnpsa6.sin6_family=AF_INET6;
	  if (pnpfd!=-1) bind(pnpfd,(struct sockaddr*)&pnpsa6,sizeof(pnpsa6));
	  pnpsa6.sin6_port=htons(5353);
	  memcpy(&pnpsa6.sin6_addr,"\xff\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xfb",16);
	}
#endif
	memset(&pnpsa4,0,sizeof(pnpsa4));
	pnpsa4.sin_family=AF_INET;
	if (pnpfd!=-1) bind(pnpfd,(struct sockaddr*)&pnpsa4,sizeof(pnpsa4));
	pnpsa4.sin_port=htons(5353);
	memcpy(&pnpsa4.sin_addr,"\xe0\x00\x00\xfb",4);  /* 224.0.0.251 */

	duh[1].events=POLLIN;
	duh[1].fd=pnpfd;
      } else {
	duh[1].fd=-1;
	duh[1].events=0;
      }

#endif
      i=0;
      duh[0].events=POLLIN;
      duh[0].fd=0;
      last.tv_sec=0;
#ifdef WANT_PLUGPLAY_DNS
      if (duh[1].fd!=-1) {
	sendto(pnpfd,packet,size,0,(struct sockaddr*)(&pnpsa4),sizeof(pnpsa4));
	if (!v4pnp)
	  sendto(pnpfd,packet,size,0,(struct sockaddr*)(&pnpsa6),sizeof(pnpsa6));
      }
      /* if it doesn't work, we don't care */
#endif
      for (j=20; j>0; --j) {
	gettimeofday(&now,0);
	if (now.tv_sec-last.tv_sec>10) {
#ifdef WANT_IPV6_DNS
	  int tmpfd;
	  struct sockaddr* s=(struct sockaddr*)&(_res.nsaddr_list[i]);
	  if (s->sa_family==AF_INET6) {
	    __dns_make_fd6();
	    tmpfd=__dns_fd6;
	  } else {
	    __dns_make_fd();
	    tmpfd=__dns_fd;
	  }
#ifdef WANT_PLUGPLAY_DNS
	  if (duh[0].fd!=-1) {
#endif
	  duh[0].fd=tmpfd;
	  if (sendto(tmpfd,packet,size,0,s,sizeof(struct sockaddr_in6))!=-1)
	    gettimeofday(&last,0);
	  else
	    goto nxdomain;
#ifdef WANT_PLUGPLAY_DNS
	  }
#endif
#else
	  duh[0].fd=__dns_fd;
	  if (sendto(__dns_fd,packet,size,0,(struct sockaddr*)&(_res.nsaddr_list[i]),sizeof(struct sockaddr))==0)
	    gettimeofday(&last,0);
#endif
	  last=now;
	}
	if (++i >= _res.nscount) i=0;
#ifdef WANT_PLUGPLAY_DNS
	if (now.tv_sec>first.tv_sec && duh[0].fd==-1) goto nxdomain;
	if (duh[0].fd==-1 && duh[1].fd==-1) goto nxdomain;
	duh[0].revents=0;
	if (poll(duh[0].fd==-1?duh+1:duh,duh[0].fd==-1?1:2,1000) > 0) {
#else
	if (poll(duh,1,1000) == 1) {
#endif
	  /* read and parse answer */
	  unsigned char inpkg[1500];
#ifdef WANT_PLUGPLAY_DNS
	  int len;
	  struct msghdr mh;
	  struct iovec iv;
	  char abuf[100];	/* for ancillary data */
	  struct cmsghdr* x;
	  int ttl=0;
	  int fd;
	  struct sockaddr_in6 tmpsa;
	  mh.msg_name=&tmpsa;
	  mh.msg_namelen=sizeof(tmpsa);
	  mh.msg_iov=&iv;
	  mh.msg_iovlen=1;
	  iv.iov_base=inpkg;
	  iv.iov_len=sizeof(inpkg);
	  mh.msg_control=abuf;
	  mh.msg_controllen=sizeof(abuf);
	  __dns_plugplay_interface=0;
	  len=recvmsg(fd=(duh[0].revents&POLLIN?duh[0].fd:duh[1].fd),&mh,MSG_DONTWAIT);
	  if (fd==duh[1].fd) {
	    if (tmpsa.sin6_family==AF_INET6)
	      __dns_plugplay_interface=tmpsa.sin6_scope_id;
	    for (x=CMSG_FIRSTHDR(&mh); x; x=CMSG_NXTHDR(&mh,x))
	      if ((x->cmsg_level==SOL_IP && x->cmsg_type==IP_TTL) ||
		  (x->cmsg_level==IPPROTO_IPV6 && x->cmsg_type==IPV6_HOPLIMIT)) {
		ttl=*(int*)CMSG_DATA(x);
		break;
	      } else if ((x->cmsg_level==SOL_IP && x->cmsg_type==IP_PKTINFO))
		__dns_plugplay_interface=((struct in_pktinfo*)(CMSG_DATA(x)))->ipi_ifindex;
	    if (ttl != 255) {
	      /* as per standard, discard packets with TTL!=255 */
	      continue;
	    }
	    /* work around stupid avahi bug */
	    inpkg[2]=(inpkg[2]&~0x1) | (packet[2]&0x1);
	  }
#else
	  int len=read(duh[0].fd,inpkg,sizeof(inpkg));
#endif
	  /* header, question, answer, authority, additional */
	  if (inpkg[0]!=packet[0] || inpkg[1]!=packet[1]) continue;	/* wrong ID */
	  if ((inpkg[2]&0xf9) != (_res.options&RES_RECURSE?0x81:0x80)) continue;	/* not answer */
	  if ((inpkg[3]&0x0f) != 0) {
#ifdef WANT_PLUGPLAY_DNS
/* if the normal DNS server says NXDOMAIN, still give the multicast method some time */
	    if (duh[0].revents&POLLIN) {
	      duh[0].fd=-1;
	      if (duh[1].fd!=-1) {
		if (j>10) j=10;
		continue;
	      }
	    } else
	      continue;
/* ignore NXDOMAIN from the multicast socket */
#endif
nxdomain:
	    h_errno=HOST_NOT_FOUND;
	    return -1;
	  }		/* error */
	  if (len>anslen) {
	    h_errno=NO_RECOVERY;
	    return -1;
	  }
	  memcpy(answer,inpkg,len);
	  return len;
	}
/*kaputt:*/
      }
    }
#ifdef WANT_PLUGPLAY_DNS
    if (duh[1].fd==-1)
      goto nxdomain;
#endif
  }
  h_errno=TRY_AGAIN;
  return -1;
}

#ifndef WANT_FULL_RESOLV_CONF
int res_search(const char *dname, int class, int type, unsigned char *answer, int anslen) __attribute__((alias("res_query")));
#endif
