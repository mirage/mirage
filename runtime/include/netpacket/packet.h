#ifndef __NETPACKET_PACKET_H
#define __NETPACKET_PACKET_H

#include <sys/cdefs.h>

__BEGIN_DECLS

struct sockaddr_ll {
  unsigned short int sll_family;
  unsigned short int sll_protocol;
  int sll_ifindex;
  unsigned short int sll_hatype;
  unsigned char sll_pkttype;
  unsigned char sll_halen;
  unsigned char sll_addr[8];
};

#define PACKET_HOST		0		/* To us.  */
#define PACKET_BROADCAST	1		/* To all.  */
#define PACKET_MULTICAST	2		/* To group.  */
#define PACKET_OTHERHOST	3		/* To someone else.  */
#define PACKET_OUTGOING		4		/* Originated by us. */
#define PACKET_LOOPBACK		5
#define PACKET_FASTROUTE	6

/* Packet socket options.  */

#define PACKET_ADD_MEMBERSHIP		1
#define PACKET_DROP_MEMBERSHIP		2
#define PACKET_RECV_OUTPUT		3
#define PACKET_RX_RING			5
#define PACKET_STATISTICS		6

struct packet_mreq {
  int mr_ifindex;
  unsigned short int mr_type;
  unsigned short int mr_alen;
  unsigned char mr_address[8];
};

#define PACKET_MR_MULTICAST	0
#define PACKET_MR_PROMISC	1
#define PACKET_MR_ALLMULTI	2

__END_DECLS

#endif
