#ifndef _NETINET_IN_H
#define _NETINET_IN_H

#include <sys/types.h>
#include <sys/socket.h>
#include <endian.h>

__BEGIN_DECLS

/* Standard well-defined IP protocols.  */
enum {
  IPPROTO_IP = 0,		/* Dummy protocol for TCP		*/
#define IPPROTO_IP IPPROTO_IP
  IPPROTO_ICMP = 1,		/* Internet Control Message Protocol	*/
#define IPPROTO_ICMP IPPROTO_ICMP
  IPPROTO_IGMP = 2,		/* Internet Group Management Protocol	*/
#define IPPROTO_IGMP IPPROTO_IGMP
  IPPROTO_IPIP = 4,		/* IPIP tunnels (older KA9Q tunnels use 94) */
#define IPPROTO_IPIP IPPROTO_IPIP
  IPPROTO_TCP = 6,		/* Transmission Control Protocol	*/
#define IPPROTO_TCP IPPROTO_TCP
  IPPROTO_EGP = 8,		/* Exterior Gateway Protocol		*/
#define IPPROTO_EGP IPPROTO_EGP
  IPPROTO_PUP = 12,		/* PUP protocol				*/
#define IPPROTO_PUP IPPROTO_PUP
  IPPROTO_UDP = 17,		/* User Datagram Protocol		*/
#define IPPROTO_UDP IPPROTO_UDP
  IPPROTO_IDP = 22,		/* XNS IDP protocol			*/
#define IPPROTO_IDP IPPROTO_IDP
  IPPROTO_RSVP = 46,		/* RSVP protocol			*/
#define IPPROTO_RSVP IPPROTO_RSVP
  IPPROTO_GRE = 47,		/* Cisco GRE tunnels (rfc 1701,1702)	*/
#define IPPROTO_GRE IPPROTO_GRE
  IPPROTO_IPV6 = 41,		/* IPv6-in-IPv4 tunnelling		*/
#define IPPROTO_IPV6 IPPROTO_IPV6
  IPPROTO_PIM    = 103,		/* Protocol Independent Multicast	*/
#define IPPROTO_PIM IPPROTO_PIM
  IPPROTO_ESP = 50,            /* Encapsulation Security Payload protocol */
#define IPPROTO_ESP IPPROTO_ESP
  IPPROTO_AH = 51,             /* Authentication Header protocol       */
#define IPPROTO_AH IPPROTO_AH
  IPPROTO_COMP   = 108,                /* Compression Header protocol */
#define IPPROTO_COMP IPPROTO_COMP
    IPPROTO_SCTP = 132,	   /* Stream Control Transmission Protocol.  */
#define IPPROTO_SCTP		IPPROTO_SCTP
    IPPROTO_UDPLITE = 136, /* UDP-Lite protocol.  */
#define IPPROTO_UDPLITE		IPPROTO_UDPLITE
  IPPROTO_RAW	 = 255,		/* Raw IP packets			*/
#define IPPROTO_RAW IPPROTO_RAW
  IPPROTO_MAX
};

#define IP_TOS		1
#define IP_TTL		2
#define IP_HDRINCL	3
#define IP_OPTIONS	4
#define IP_ROUTER_ALERT	5
#define IP_RECVOPTS	6
#define IP_RETOPTS	7
#define IP_PKTINFO	8
#define IP_PKTOPTIONS	9
#define IP_MTU_DISCOVER	10
#define IP_RECVERR	11
#define IP_RECVTTL	12
#define IP_RECVTOS	13
#define IP_MTU		14
#define IP_FREEBIND	15

/* BSD compatibility */
#define IP_RECVRETOPTS	IP_RETOPTS

/* IP_MTU_DISCOVER values */
#define IP_PMTUDISC_DONT		0	/* Never send DF frames */
#define IP_PMTUDISC_WANT		1	/* Use per route hints	*/
#define IP_PMTUDISC_DO			2	/* Always DF		*/

#define IP_MULTICAST_IF			32
#define IP_MULTICAST_TTL 		33
#define IP_MULTICAST_LOOP 		34
#define IP_ADD_MEMBERSHIP		35
#define IP_DROP_MEMBERSHIP		36

/* These need to appear somewhere around here */
#define IP_DEFAULT_MULTICAST_TTL        1
#define IP_DEFAULT_MULTICAST_LOOP       1

#define IN6ADDR_ANY_INIT {{{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }}}
#define IN6ADDR_LOOPBACK_INIT {{{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 }}}
extern const struct in6_addr in6addr_any;
extern const struct in6_addr in6addr_loopback;

typedef uint16_t in_port_t;
typedef uint32_t in_addr_t;

struct in_addr {
  in_addr_t s_addr;
};

struct ip_mreq {
  struct in_addr imr_multiaddr;	/* IP multicast address of group */
  struct in_addr imr_interface;	/* local IP address of interface */
};

struct ip_mreqn {
  struct in_addr	imr_multiaddr;		/* IP multicast address of group */
  struct in_addr	imr_address;		/* local IP address of interface */
  int32_t		imr_ifindex;		/* Interface index */
};

struct in_pktinfo {
  int32_t		ipi_ifindex;
  struct in_addr	ipi_spec_dst;
  struct in_addr	ipi_addr;
};

/* Structure describing an Internet (IP) socket address. */
#define __SOCK_SIZE__	16		/* sizeof(struct sockaddr)	*/
struct sockaddr_in {
  sa_family_t		sin_family;	/* Address family		*/
  in_port_t		sin_port;	/* Port number			*/
  struct in_addr	sin_addr;	/* Internet address		*/
  /* Pad to size of `struct sockaddr'. */
  unsigned char		sin_zero[__SOCK_SIZE__ - sizeof(int16_t) -
			sizeof(uint16_t) - sizeof(struct in_addr)];
};


/*
 * Definitions of the bits in an Internet address integer.
 * On subnets, host and network parts are found according
 * to the subnet mask, not these masks.
 */
#define	IN_CLASSA(a)		((((long int) (a)) & 0x80000000) == 0)
#define	IN_CLASSA_NET		0xff000000
#define	IN_CLASSA_NSHIFT	24
#define	IN_CLASSA_HOST		(0xffffffff & ~IN_CLASSA_NET)
#define	IN_CLASSA_MAX		128

#define	IN_CLASSB(a)		((((long int) (a)) & 0xc0000000) == 0x80000000)
#define	IN_CLASSB_NET		0xffff0000
#define	IN_CLASSB_NSHIFT	16
#define	IN_CLASSB_HOST		(0xffffffff & ~IN_CLASSB_NET)
#define	IN_CLASSB_MAX		65536

#define	IN_CLASSC(a)		((((long int) (a)) & 0xe0000000) == 0xc0000000)
#define	IN_CLASSC_NET		0xffffff00
#define	IN_CLASSC_NSHIFT	8
#define	IN_CLASSC_HOST		(0xffffffff & ~IN_CLASSC_NET)

#define	IN_CLASSD(a)		((((long int) (a)) & 0xf0000000) == 0xe0000000)
#define	IN_MULTICAST(a)		IN_CLASSD(a)
#define IN_MULTICAST_NET	0xF0000000

#define	IN_EXPERIMENTAL(a)	((((long int) (a)) & 0xf0000000) == 0xf0000000)
#define	IN_BADCLASS(a)		IN_EXPERIMENTAL((a))

/* Address to accept any incoming messages. */
#define	INADDR_ANY		((unsigned long int) 0x00000000)

/* Address to send to all hosts. */
#define	INADDR_BROADCAST	((unsigned long int) 0xffffffff)

/* Address indicating an error return. */
#define	INADDR_NONE		((unsigned long int) 0xffffffff)

/* Network number for local host loopback. */
#define	IN_LOOPBACKNET		127

/* Address to loopback in software to local host.  */
#define	INADDR_LOOPBACK		0x7f000001	/* 127.0.0.1   */
#define	IN_LOOPBACK(a)		((((long int) (a)) & 0xff000000) == 0x7f000000)

/* Defines for Multicast INADDR */
#define INADDR_UNSPEC_GROUP   	0xe0000000U	/* 224.0.0.0   */
#define INADDR_ALLHOSTS_GROUP 	0xe0000001U	/* 224.0.0.1   */
#define INADDR_ALLRTRS_GROUP    0xe0000002U	/* 224.0.0.2 */
#define INADDR_MAX_LOCAL_GROUP  0xe00000ffU	/* 224.0.0.255 */

struct in6_addr {
  union {
    uint8_t		u6_addr8[16];
    uint16_t		u6_addr16[8];
    uint32_t		u6_addr32[4];
  } in6_u;
#define s6_addr			in6_u.u6_addr8
#define s6_addr16		in6_u.u6_addr16
#define s6_addr32		in6_u.u6_addr32
};

struct sockaddr_in6 {
  uint16_t		sin6_family;    /* AF_INET6 */
  uint16_t		sin6_port;      /* Transport layer port # */
  uint32_t		sin6_flowinfo;  /* IPv6 flow information */
  struct in6_addr	sin6_addr;      /* IPv6 address */
  uint32_t		sin6_scope_id;  /* scope id (new in RFC2553) */
};

struct sockaddr_in_pad {
  sa_family_t		sin_family;	/* Address family		*/
  in_port_t		sin_port;	/* Port number			*/
  struct in_addr	sin_addr;	/* Internet address		*/
  /* Pad to size of `struct sockaddr_in6'. */
  unsigned char		sin_zero[sizeof(struct sockaddr_in6) - sizeof(int16_t) -
			sizeof(uint16_t) - sizeof(struct in_addr)];
};

struct ipv6_mreq {
  /* IPv6 multicast address of group */
  struct in6_addr ipv6mr_multiaddr;
  /* local IPv6 address of interface */
  int32_t ipv6mr_interface;
};

struct in6_flowlabel_req {
  struct in6_addr	flr_dst;
  uint32_t	flr_label;
  uint8_t	flr_action;
  uint8_t	flr_share;
  uint16_t	flr_flags;
  uint16_t 	flr_expires;
  uint16_t	flr_linger;
  uint32_t	__flr_pad;
  /* Options in format of IPV6_PKTOPTIONS */
};

#define IPV6_FL_A_GET	0
#define IPV6_FL_A_PUT	1
#define IPV6_FL_A_RENEW	2

#define IPV6_FL_F_CREATE	1
#define IPV6_FL_F_EXCL		2

#define IPV6_FL_S_NONE		0
#define IPV6_FL_S_EXCL		1
#define IPV6_FL_S_PROCESS	2
#define IPV6_FL_S_USER		3
#define IPV6_FL_S_ANY		255

#define IPV6_FLOWINFO_FLOWLABEL		0x000fffff
#define IPV6_FLOWINFO_PRIORITY		0x0ff00000

/*
 *	IPV6 extension headers
 */
#define IPPROTO_HOPOPTS		0	/* IPv6 hop-by-hop options	*/
#define IPPROTO_ROUTING		43	/* IPv6 routing header		*/
#define IPPROTO_FRAGMENT	44	/* IPv6 fragmentation header	*/
#define IPPROTO_ICMPV6		58	/* ICMPv6			*/
#define IPPROTO_NONE		59	/* IPv6 no next header		*/
#define IPPROTO_DSTOPTS		60	/* IPv6 destination options	*/

/* IPv6 TLV options. */
#define IPV6_TLV_PAD0		0
#define IPV6_TLV_PADN		1
#define IPV6_TLV_ROUTERALERT	5
#define IPV6_TLV_JUMBO		194

/* IPV6 socket options. */
#define IPV6_ADDRFORM		1
#define IPV6_PKTINFO		2
#define IPV6_HOPOPTS		3
#define IPV6_DSTOPTS		4
#define IPV6_RTHDR		5
#define IPV6_PKTOPTIONS		6
#define IPV6_CHECKSUM		7
#define IPV6_HOPLIMIT		8
#define IPV6_NEXTHOP		9
#define IPV6_AUTHHDR		10
#define IPV6_FLOWINFO		11

#define IPV6_UNICAST_HOPS	16
#define IPV6_MULTICAST_IF	17
#define IPV6_MULTICAST_HOPS	18
#define IPV6_MULTICAST_LOOP	19
#define IPV6_ADD_MEMBERSHIP	20
#define IPV6_DROP_MEMBERSHIP	21
#define IPV6_ROUTER_ALERT	22
#define IPV6_MTU_DISCOVER	23
#define IPV6_MTU		24
#define IPV6_RECVERR		25

/* IPV6_MTU_DISCOVER values */
#define IPV6_PMTUDISC_DONT		0
#define IPV6_PMTUDISC_WANT		1
#define IPV6_PMTUDISC_DO		2

/* Flowlabel */
#define IPV6_FLOWLABEL_MGR	32
#define IPV6_FLOWINFO_SEND	33

#define IPV6_MIN_MTU	1280

struct in6_pktinfo {
  struct in6_addr	ipi6_addr;
  int32_t		ipi6_ifindex;
};

struct in6_ifreq {
  struct in6_addr	ifr6_addr;
  uint32_t		ifr6_prefixlen;
  int32_t		ifr6_ifindex;
};

#define IPV6_SRCRT_STRICT	0x01	/* this hop must be a neighbor	*/
#define IPV6_SRCRT_TYPE_0	0	/* IPv6 type 0 Routing Header	*/

/* routing header */
struct ipv6_rt_hdr {
  uint8_t		nexthdr;
  uint8_t		hdrlen;
  uint8_t		type;
  uint8_t		segments_left;
  /* type specific data, variable length field */
};

struct ipv6_opt_hdr {
  uint8_t 		nexthdr;
  uint8_t 		hdrlen;
  /* TLV encoded option data follows. */
};

#define ipv6_destopt_hdr ipv6_opt_hdr
#define ipv6_hopopt_hdr  ipv6_opt_hdr

/* routing header type 0 (used in cmsghdr struct) */

#if !defined(__STRICT_ANSI__) || (__STDC_VERSION__ + 0 >= 199900L)
struct rt0_hdr {
  struct ipv6_rt_hdr	rt_hdr;
  uint32_t		bitmap;		/* strict/loose bit map */
  struct in6_addr	addr[0];
#define rt0_type		rt_hdr.type;
};
#endif

struct ipv6hdr {
#if __BYTE_ORDER == __LITTLE_ENDIAN
  uint32_t		flow_lbl:20,
			priority:8,
			version:4;
#else
  uint32_t		version:4,
			priority:8,
			flow_lbl:20;
#endif

  uint16_t		payload_len;
  uint8_t		nexthdr;
  uint8_t		hop_limit;

  struct in6_addr	saddr;
  struct in6_addr	daddr;
};
/* fnord */

#define IPPORT_RESERVED 1024
#define INET_ADDRSTRLEN 16
#define INET6_ADDRSTRLEN 46

#undef htonl
#undef htons
#undef ntohl
#undef ntohs
uint32_t htonl(uint32_t hostlong);
uint16_t htons(uint16_t hostshort);
uint32_t ntohl(uint32_t netlong);
uint16_t ntohs(uint16_t netshort);

#define IN6_IS_ADDR_UNSPECIFIED(a) \
	(((__const uint32_t *) (a))[0] == 0				      \
	 && ((__const uint32_t *) (a))[1] == 0				      \
	 && ((__const uint32_t *) (a))[2] == 0				      \
	 && ((__const uint32_t *) (a))[3] == 0)

#define IN6_IS_ADDR_LOOPBACK(a) \
	(((__const uint32_t *) (a))[0] == 0				      \
	 && ((__const uint32_t *) (a))[1] == 0				      \
	 && ((__const uint32_t *) (a))[2] == 0				      \
	 && ((__const uint32_t *) (a))[3] == htonl (1))

#define IN6_IS_ADDR_MULTICAST(a) (((__const uint8_t *) (a))[0] == 0xff)

#define IN6_IS_ADDR_LINKLOCAL(a) \
	((((__const uint32_t *) (a))[0] & htonl (0xffc00000))		      \
	 == htonl (0xfe800000))

#define IN6_IS_ADDR_SITELOCAL(a) \
	((((__const uint32_t *) (a))[0] & htonl (0xffc00000))		      \
	 == htonl (0xfec00000))

#define IN6_IS_ADDR_V4MAPPED(a) \
	((((__const uint32_t *) (a))[0] == 0)				      \
	 && (((__const uint32_t *) (a))[1] == 0)			      \
	 && (((__const uint32_t *) (a))[2] == htonl (0xffff)))

#define IN6_IS_ADDR_V4COMPAT(a) \
	((((__const uint32_t *) (a))[0] == 0)				      \
	 && (((__const uint32_t *) (a))[1] == 0)			      \
	 && (((__const uint32_t *) (a))[2] == 0)			      \
	 && (ntohl (((__const uint32_t *) (a))[3]) > 1))

#define IN6_ARE_ADDR_EQUAL(a,b) \
	((((__const uint32_t *) (a))[0] == ((__const uint32_t *) (b))[0])     \
	 && (((__const uint32_t *) (a))[1] == ((__const uint32_t *) (b))[1])  \
	 && (((__const uint32_t *) (a))[2] == ((__const uint32_t *) (b))[2])  \
	 && (((__const uint32_t *) (a))[3] == ((__const uint32_t *) (b))[3]))

/* old legacy bullshit */
int bindresvport(int sd, struct sockaddr_in* _sin);

#define IN6_IS_ADDR_MC_NODELOCAL(a) \
	(IN6_IS_ADDR_MULTICAST(a)					      \
	 && ((((__const uint8_t *) (a))[1] & 0xf) == 0x1))

#define IN6_IS_ADDR_MC_LINKLOCAL(a) \
	(IN6_IS_ADDR_MULTICAST(a)					      \
	 && ((((__const uint8_t *) (a))[1] & 0xf) == 0x2))

#define IN6_IS_ADDR_MC_SITELOCAL(a) \
	(IN6_IS_ADDR_MULTICAST(a)					      \
	 && ((((__const uint8_t *) (a))[1] & 0xf) == 0x5))

#define IN6_IS_ADDR_MC_ORGLOCAL(a) \
	(IN6_IS_ADDR_MULTICAST(a)					      \
	 && ((((__const uint8_t *) (a))[1] & 0xf) == 0x8))

#define IN6_IS_ADDR_MC_GLOBAL(a) \
	(IN6_IS_ADDR_MULTICAST(a)					      \
	 && ((((__const uint8_t *) (a))[1] & 0xf) == 0xe))

__END_DECLS

#endif
