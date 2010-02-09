#ifndef _NETINET_TCP_H
#define _NETINET_TCP_H

#include <inttypes.h>
#include <endian.h>

__BEGIN_DECLS

struct tcphdr {		/* size 20/0x14      40/0x28 with IP header */
  uint16_t source;	/* offset 0          20/0x14 */
  uint16_t dest;	/* offset 2          22/0x16 */
  uint32_t seq;		/* offset 4          24/0x18 */
  uint32_t ack_seq;	/* offset 8          28/0x1c */
#if __BYTE_ORDER == __LITTLE_ENDIAN
  uint16_t res1:4, doff:4, fin:1, syn:1, rst:1, psh:1, ack:1, urg:1, ece:1, cwr:1;
#else
  uint16_t doff:4, res1:4, cwr:1, ece:1, urg:1, ack:1, psh:1, rst:1, syn:1, fin:1;
#endif
			/* offset 12/0xc     32/0x20 */
  uint16_t window;	/* offset 14/0xe     34/0x22 */
  uint16_t check;	/* offset 16/0x10    36/0x24 */
  uint16_t urg_ptr;	/* offset 18/0x12    38/0x26 */
};


enum {
  TCP_ESTABLISHED = 1,
  TCP_SYN_SENT,
  TCP_SYN_RECV,
  TCP_FIN_WAIT1,
  TCP_FIN_WAIT2,
  TCP_TIME_WAIT,
  TCP_CLOSE,
  TCP_CLOSE_WAIT,
  TCP_LAST_ACK,
  TCP_LISTEN,
  TCP_CLOSING,	 /* now a valid state */

  TCP_MAX_STATES /* Leave at the end! */
};

#define TCP_STATE_MASK 0xF
#define TCP_ACTION_FIN (1 << 7)

enum {
  TCPF_ESTABLISHED = (1 << 1),
  TCPF_SYN_SENT  = (1 << 2),
  TCPF_SYN_RECV  = (1 << 3),
  TCPF_FIN_WAIT1 = (1 << 4),
  TCPF_FIN_WAIT2 = (1 << 5),
  TCPF_TIME_WAIT = (1 << 6),
  TCPF_CLOSE     = (1 << 7),
  TCPF_CLOSE_WAIT = (1 << 8),
  TCPF_LAST_ACK  = (1 << 9),
  TCPF_LISTEN    = (1 << 10),
  TCPF_CLOSING   = (1 << 11)
};

/*
 *	The union cast uses a gcc extension to avoid aliasing problems
 *  (union is compatible to any of its members)
 *  This means this part of the code is -fstrict-aliasing safe now.
 */
union tcp_word_hdr {
  struct tcphdr hdr;
  uint32_t words[5];
};

#define tcp_flag_word(tp) ( ((union tcp_word_hdr *)(tp))->words [3]) 

enum {
#if __BYTE_ORDER == __LITTLE_ENDIAN
  TCP_FLAG_CWR = 0x00008000,
  TCP_FLAG_ECE = 0x00004000,
  TCP_FLAG_URG = 0x00002000,
  TCP_FLAG_ACK = 0x00001000,
  TCP_FLAG_PSH = 0x00000800,
  TCP_FLAG_RST = 0x00000400,
  TCP_FLAG_SYN = 0x00000200,
  TCP_FLAG_FIN = 0x00000100,
  TCP_RESERVED_BITS = 0x0000C00F,
  TCP_DATA_OFFSET = 0x000000F0
#else
  TCP_FLAG_CWR = 0x00800000,
  TCP_FLAG_ECE = 0x00400000,
  TCP_FLAG_URG = 0x00200000,
  TCP_FLAG_ACK = 0x00100000,
  TCP_FLAG_PSH = 0x00080000,
  TCP_FLAG_RST = 0x00040000,
  TCP_FLAG_SYN = 0x00020000,
  TCP_FLAG_FIN = 0x00010000,
  TCP_RESERVED_BITS = 0x0FC00000,
  TCP_DATA_OFFSET = 0xF0000000
#endif
};

/* TCP socket options */
#define TCP_NODELAY		1	/* Turn off Nagle's algorithm. */
#define TCP_MAXSEG		2	/* Limit MSS */
#define TCP_CORK		3	/* Never send partially complete segments */
#define TCP_KEEPIDLE		4	/* Start keeplives after this period */
#define TCP_KEEPINTVL		5	/* Interval between keepalives */
#define TCP_KEEPCNT		6	/* Number of keepalives before death */
#define TCP_SYNCNT		7	/* Number of SYN retransmits */
#define TCP_LINGER2		8	/* Life time of orphaned FIN-WAIT-2 state */
#define TCP_DEFER_ACCEPT	9	/* Wake up listener only when data arrive */
#define TCP_WINDOW_CLAMP	10	/* Bound advertised window */
#define TCP_INFO		11	/* Information about this connection. */
#define TCP_QUICKACK		12	/* Block/reenable quick acks */

#define TCPI_OPT_TIMESTAMPS	1
#define TCPI_OPT_SACK		2
#define TCPI_OPT_WSCALE		4
#define TCPI_OPT_ECN		8

enum tcp_ca_state {
  TCP_CA_Open = 0,
#define TCPF_CA_Open	(1<<TCP_CA_Open)
  TCP_CA_Disorder = 1,
#define TCPF_CA_Disorder (1<<TCP_CA_Disorder)
  TCP_CA_CWR = 2,
#define TCPF_CA_CWR	(1<<TCP_CA_CWR)
  TCP_CA_Recovery = 3,
#define TCPF_CA_Recovery (1<<TCP_CA_Recovery)
  TCP_CA_Loss = 4
#define TCPF_CA_Loss	(1<<TCP_CA_Loss)
};

struct tcp_info {
  uint8_t tcpi_state;
  uint8_t tcpi_ca_state;
  uint8_t tcpi_retransmits;
  uint8_t tcpi_probes;
  uint8_t tcpi_backoff;
  uint8_t tcpi_options;
  uint8_t tcpi_snd_wscale : 4, tcpi_rcv_wscale : 4;

  uint32_t tcpi_rto;
  uint32_t tcpi_ato;
  uint32_t tcpi_snd_mss;
  uint32_t tcpi_rcv_mss;

  uint32_t tcpi_unacked;
  uint32_t tcpi_sacked;
  uint32_t tcpi_lost;
  uint32_t tcpi_retrans;
  uint32_t tcpi_fackets;

  /* Times. */
  uint32_t tcpi_last_data_sent;
  uint32_t tcpi_last_ack_sent;     /* Not remembered, sorry. */
  uint32_t tcpi_last_data_recv;
  uint32_t tcpi_last_ack_recv;

  /* Metrics. */
  uint32_t tcpi_pmtu;
  uint32_t tcpi_rcv_ssthresh;
  uint32_t tcpi_rtt;
  uint32_t tcpi_rttvar;
  uint32_t tcpi_snd_ssthresh;
  uint32_t tcpi_snd_cwnd;
  uint32_t tcpi_advmss;
  uint32_t tcpi_reordering;
};

__END_DECLS

#endif
