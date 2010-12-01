#ifndef _NETINET_IP_H
#define _NETINET_IP_H

#include <inttypes.h>
#include <endian.h>
#include <netinet/in.h>

__BEGIN_DECLS

#define	IPVERSION	4               /* IP version number */
#define	IP_MAXPACKET	65535		/* maximum packet size */

#define IPTOS_TOS_MASK		0x1E
#define IPTOS_TOS(tos)		((tos)&IPTOS_TOS_MASK)
#define IPTOS_LOWDELAY		0x10
#define IPTOS_THROUGHPUT	0x08
#define IPTOS_RELIABILITY	0x04
#define IPTOS_MINCOST		0x02
#define IPTOS_LOWCOST		IPTOS_MINCOST

#define IPTOS_PREC_MASK		0xE0
#define IPTOS_PREC(tos)		((tos)&IPTOS_PREC_MASK)
#define IPTOS_PREC_NETCONTROL           0xe0
#define IPTOS_PREC_INTERNETCONTROL      0xc0
#define IPTOS_PREC_CRITIC_ECP           0xa0
#define IPTOS_PREC_FLASHOVERRIDE        0x80
#define IPTOS_PREC_FLASH                0x60
#define IPTOS_PREC_IMMEDIATE            0x40
#define IPTOS_PREC_PRIORITY             0x20
#define IPTOS_PREC_ROUTINE              0x00


/* IP options */
#define IPOPT_COPY		0x80
#define IPOPT_CLASS_MASK	0x60
#define IPOPT_NUMBER_MASK	0x1f

#define IPOPT_COPIED(o)		((o)&IPOPT_COPY)
#define IPOPT_CLASS(o)		((o)&IPOPT_CLASS_MASK)
#define IPOPT_NUMBER(o)		((o)&IPOPT_NUMBER_MASK)

#define IPOPT_CONTROL		0x00
#define IPOPT_RESERVED1		0x20
#define IPOPT_MEASUREMENT	0x40
#define IPOPT_RESERVED2		0x60

#define IPOPT_END	(0 |IPOPT_CONTROL)
#define IPOPT_NOOP	(1 |IPOPT_CONTROL)
#define IPOPT_SEC	(2 |IPOPT_CONTROL|IPOPT_COPY)
#define IPOPT_LSRR	(3 |IPOPT_CONTROL|IPOPT_COPY)
#define IPOPT_TIMESTAMP	(4 |IPOPT_MEASUREMENT)
#define IPOPT_RR	(7 |IPOPT_CONTROL)
#define IPOPT_SID	(8 |IPOPT_CONTROL|IPOPT_COPY)
#define IPOPT_SSRR	(9 |IPOPT_CONTROL|IPOPT_COPY)
#define IPOPT_RA	(20|IPOPT_CONTROL|IPOPT_COPY)

#define IPVERSION	4
#define MAXTTL		255
#define IPDEFTTL	64

/* struct timestamp, struct route and MAX_ROUTES are removed.

   REASONS: it is clear that nobody used them because:
   - MAX_ROUTES value was wrong.
   - "struct route" was wrong.
   - "struct timestamp" had fatally misaligned bitfields and was completely unusable.
 */

#define IPOPT_OPTVAL 0
#define IPOPT_OLEN   1
#define IPOPT_OFFSET 2
#define IPOPT_MINOFF 4
#define MAX_IPOPTLEN 40
#define IPOPT_NOP IPOPT_NOOP
#define IPOPT_EOL IPOPT_END
#define IPOPT_TS  IPOPT_TIMESTAMP

#define IPOPT_TS_TSONLY		0		/* timestamps only */
#define IPOPT_TS_TSANDADDR	1		/* timestamps and addresses */
#define IPOPT_TS_PRESPEC	3		/* specified modules only */

struct iphdr {				/* size 20/0x14 */
#if __BYTE_ORDER == __LITTLE_ENDIAN
  unsigned int ihl:4, version:4;	/* offset 0; version=ip version (4) */
#else
  unsigned int version:4, ihl:4;	/* offset 0; ihl=ip header length, measured in words (5) */
#endif
  unsigned char tos;			/* offset 1 */
  unsigned short tot_len;		/* offset 2; total bytes in packet in network byte order */
  unsigned short id;			/* offset 4 */
  unsigned short frag_off;		/* offset 6 */
  unsigned char ttl;			/* offset 8 */
  unsigned char protocol;		/* offset 9; 1=ICMP, 6=TCP, 17=UDP (see netinet/in.h) */
  unsigned short check;			/* offset 10/0xa */
  unsigned int saddr;			/* offset 12/0xc */
  unsigned int daddr;			/* offset 16/0x10 */
  /*The options start here. */
};

struct ip {
#if __BYTE_ORDER == __LITTLE_ENDIAN
  unsigned int ip_hl:4;		/* header length */
  unsigned int ip_v:4;		/* version */
#endif
#if __BYTE_ORDER == __BIG_ENDIAN
  unsigned int ip_v:4;		/* version */
  unsigned int ip_hl:4;		/* header length */
#endif
  unsigned char ip_tos;		/* type of service */
  unsigned short ip_len;		/* total length */
  unsigned short ip_id;		/* identification */
  unsigned short ip_off;		/* fragment offset field */
#define	IP_RF 0x8000			/* reserved fragment flag */
#define	IP_DF 0x4000			/* dont fragment flag */
#define	IP_MF 0x2000			/* more fragments flag */
#define	IP_OFFMASK 0x1fff		/* mask for fragmenting bits */
  unsigned char ip_ttl;		/* time to live */
  unsigned char ip_p;			/* protocol */
  unsigned short ip_sum;		/* checksum */
  struct in_addr ip_src, ip_dst;	/* source and dest address */
};

__END_DECLS

#endif
