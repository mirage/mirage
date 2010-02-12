#ifndef _NET_ROUTE_H
#define _NET_ROUTE_H

#include <inttypes.h>
#include <netinet/in.h>

__BEGIN_DECLS

/* This structure gets passed by the SIOCADDRT and SIOCDELRT calls. */
struct rtentry {
  unsigned long rt_pad1;
  struct sockaddr rt_dst;		/* target address		*/
  struct sockaddr rt_gateway;	/* gateway addr (RTF_GATEWAY)	*/
  struct sockaddr rt_genmask;	/* target network mask (IP)	*/
  unsigned short rt_flags;
  short rt_pad2;
  unsigned long rt_pad3;
  void *rt_pad4;
  short rt_metric;	/* +1 for binary compatibility!	*/
  char *rt_dev;		/* forcing the device at add	*/
  unsigned long rt_mtu;	/* per route MTU/Window 	*/
#define rt_mss	rt_mtu	/* Compatibility :-(            */
  unsigned long rt_window;	/* Window clamping 		*/
  unsigned short rt_irtt;	/* Initial RTT			*/
};

#define RTF_UP		0x0001		/* route usable		  	*/
#define RTF_GATEWAY	0x0002		/* destination is a gateway	*/
#define RTF_HOST	0x0004		/* host entry (net otherwise)	*/
#define RTF_REINSTATE	0x0008		/* reinstate route after tmout	*/
#define RTF_DYNAMIC	0x0010		/* created dyn. (by redirect)	*/
#define RTF_MODIFIED	0x0020		/* modified dyn. (by redirect)	*/
#define RTF_MTU		0x0040		/* specific MTU for this route	*/
#define RTF_MSS		RTF_MTU		/* Compatibility :-(		*/
#define RTF_WINDOW	0x0080		/* per route window clamping	*/
#define RTF_IRTT	0x0100		/* Initial round trip time	*/
#define RTF_REJECT	0x0200		/* Reject route			*/

struct in6_rtmsg {
  struct in6_addr rtmsg_dst;
  struct in6_addr rtmsg_src;
  struct in6_addr rtmsg_gateway;
  uint32_t rtmsg_type;
  uint16_t rtmsg_dst_len;
  uint16_t rtmsg_src_len;
  uint32_t rtmsg_metric;
  unsigned long int rtmsg_info;
  uint32_t rtmsg_flags;
  int rtmsg_ifindex;
};

__END_DECLS

#endif
