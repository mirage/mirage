#ifndef _ARPA_NAMESER_H
#define _ARPA_NAMESER_H

#include <sys/cdefs.h>
#include <endian.h>

__BEGIN_DECLS

#define NS_PACKETSZ	512	/* maximum packet size */
#define NS_MAXDNAME	1025	/* maximum domain name */
#define NS_MAXCDNAME	255	/* maximum compressed domain name */
#define NS_MAXLABEL	63	/* maximum length of domain label */
#define NS_HFIXEDSZ	12	/* #/bytes of fixed data in header */
#define NS_QFIXEDSZ	4	/* #/bytes of fixed data in query */
#define NS_RRFIXEDSZ	10	/* #/bytes of fixed data in r record */
#define NS_INT32SZ	4	/* #/bytes of data in a u_int32_t */
#define NS_INT16SZ	2	/* #/bytes of data in a u_int16_t */
#define NS_INT8SZ	1	/* #/bytes of data in a u_int8_t */
#define NS_INADDRSZ	4	/* IPv4 T_A */
#define NS_IN6ADDRSZ	16	/* IPv6 T_AAAA */
#define NS_CMPRSFLGS	0xc0	/* Flag bits indicating name compression. */
#define NS_DEFAULTPORT	53	/* For both TCP and UDP. */

/*
 * Currently defined type values for resources and queries.
 */
typedef enum __ns_type {
	ns_t_invalid = 0,	/* Cookie. */
	ns_t_a = 1,		/* Host address. */
	ns_t_ns = 2,		/* Authoritative server. */
	ns_t_md = 3,		/* Mail destination. */
	ns_t_mf = 4,		/* Mail forwarder. */
	ns_t_cname = 5,		/* Canonical name. */
	ns_t_soa = 6,		/* Start of authority zone. */
	ns_t_mb = 7,		/* Mailbox domain name. */
	ns_t_mg = 8,		/* Mail group member. */
	ns_t_mr = 9,		/* Mail rename name. */
	ns_t_null = 10,		/* Null resource record. */
	ns_t_wks = 11,		/* Well known service. */
	ns_t_ptr = 12,		/* Domain name pointer. */
	ns_t_hinfo = 13,	/* Host information. */
	ns_t_minfo = 14,	/* Mailbox information. */
	ns_t_mx = 15,		/* Mail routing information. */
	ns_t_txt = 16,		/* Text strings. */
	ns_t_rp = 17,		/* Responsible person. */
	ns_t_afsdb = 18,	/* AFS cell database. */
	ns_t_x25 = 19,		/* X_25 calling address. */
	ns_t_isdn = 20,		/* ISDN calling address. */
	ns_t_rt = 21,		/* Router. */
	ns_t_nsap = 22,		/* NSAP address. */
	ns_t_nsap_ptr = 23,	/* Reverse NSAP lookup (deprecated). */
	ns_t_sig = 24,		/* Security signature. */
	ns_t_key = 25,		/* Security key. */
	ns_t_px = 26,		/* X.400 mail mapping. */
	ns_t_gpos = 27,		/* Geographical position (withdrawn). */
	ns_t_aaaa = 28,		/* Ip6 Address. */
	ns_t_loc = 29,		/* Location Information. */
	ns_t_nxt = 30,		/* Next domain (security). */
	ns_t_eid = 31,		/* Endpoint identifier. */
	ns_t_nimloc = 32,	/* Nimrod Locator. */
	ns_t_srv = 33,		/* Server Selection. */
	ns_t_atma = 34,		/* ATM Address */
	ns_t_naptr = 35,	/* Naming Authority PoinTeR */
	ns_t_kx = 36,		/* Key Exchange */
	ns_t_cert = 37,		/* Certification record */
	ns_t_a6 = 38,		/* IPv6 address (deprecates AAAA) */
	ns_t_dname = 39,	/* Non-terminal DNAME (for IPv6) */
	ns_t_sink = 40,		/* Kitchen sink (experimentatl) */
	ns_t_opt = 41,		/* EDNS0 option (meta-RR) */
	ns_t_tsig = 250,	/* Transaction signature. */
	ns_t_ixfr = 251,	/* Incremental zone transfer. */
	ns_t_axfr = 252,	/* Transfer zone of authority. */
	ns_t_mailb = 253,	/* Transfer mailbox records. */
	ns_t_maila = 254,	/* Transfer mail agent records. */
	ns_t_any = 255,		/* Wildcard match. */
	ns_t_zxfr = 256,	/* BIND-specific, nonstandard. */
	ns_t_max = 65536
} ns_type;

/*
 * Values for class field
 */
typedef enum __ns_class {
	ns_c_invalid = 0,	/* Cookie. */
	ns_c_in = 1,		/* Internet. */
	ns_c_2 = 2,		/* unallocated/unsupported. */
	ns_c_chaos = 3,		/* MIT Chaos-net. */
	ns_c_hs = 4,		/* MIT Hesiod. */
	/* Query class values which do not appear in resource records */
	ns_c_none = 254,	/* for prereq. sections in update requests */
	ns_c_any = 255,		/* Wildcard match. */
	ns_c_max = 65536
} ns_class;

/*
 * Currently defined opcodes.
 */
typedef enum __ns_opcode {
	ns_o_query = 0,		/* Standard query. */
	ns_o_iquery = 1,	/* Inverse query (deprecated/unsupported). */
	ns_o_status = 2,	/* Name server status query (unsupported). */
				/* Opcode 3 is undefined/reserved. */
	ns_o_notify = 4,	/* Zone change notification. */
	ns_o_update = 5,	/* Zone update message. */
	ns_o_max = 6
} ns_opcode;

/*
 * Currently defined response codes.
 */
typedef	enum __ns_rcode {
	ns_r_noerror = 0,	/* No error occurred. */
	ns_r_formerr = 1,	/* Format error. */
	ns_r_servfail = 2,	/* Server failure. */
	ns_r_nxdomain = 3,	/* Name error. */
	ns_r_notimpl = 4,	/* Unimplemented. */
	ns_r_refused = 5,	/* Operation refused. */
	/* these are for BIND_UPDATE */
	ns_r_yxdomain = 6,	/* Name exists */
	ns_r_yxrrset = 7,	/* RRset exists */
	ns_r_nxrrset = 8,	/* RRset does not exist */
	ns_r_notauth = 9,	/* Not authoritative for zone */
	ns_r_notzone = 10,	/* Zone of record different from zone section */
	ns_r_max = 11,
	/* The following are TSIG extended errors */
	ns_r_badsig = 16,
	ns_r_badkey = 17,
	ns_r_badtime = 18
} ns_rcode;

typedef struct {
        unsigned        id :16;         /* query identification number */
#if BYTE_ORDER == BIG_ENDIAN
                        /* fields in third byte */
        unsigned        qr: 1;          /* response flag */
        unsigned        opcode: 4;      /* purpose of message */
        unsigned        aa: 1;          /* authoritive answer */
        unsigned        tc: 1;          /* truncated message */
        unsigned        rd: 1;          /* recursion desired */
                        /* fields in fourth byte */
        unsigned        ra: 1;          /* recursion available */
        unsigned        unused :1;      /* unused bits (MBZ as of 4.9.3a3) */
        unsigned        ad: 1;          /* authentic data from named */
        unsigned        cd: 1;          /* checking disabled by resolver */
        unsigned        rcode :4;       /* response code */
#endif
#if BYTE_ORDER == LITTLE_ENDIAN || BYTE_ORDER == PDP_ENDIAN
                        /* fields in third byte */
        unsigned        rd :1;          /* recursion desired */
        unsigned        tc :1;          /* truncated message */
        unsigned        aa :1;          /* authoritive answer */
        unsigned        opcode :4;      /* purpose of message */
        unsigned        qr :1;          /* response flag */
                        /* fields in fourth byte */
        unsigned        rcode :4;       /* response code */
        unsigned        cd: 1;          /* checking disabled by resolver */
        unsigned        ad: 1;          /* authentic data from named */
        unsigned        unused :1;      /* unused bits (MBZ as of 4.9.3a3) */
        unsigned        ra :1;          /* recursion available */
#endif
                        /* remaining bytes */
        unsigned        qdcount :16;    /* number of question entries */
        unsigned        ancount :16;    /* number of answer entries */
        unsigned        nscount :16;    /* number of authority entries */
        unsigned        arcount :16;    /* number of resource entries */
} HEADER;

#define PACKETSZ        NS_PACKETSZ
#define MAXDNAME        NS_MAXDNAME
#define MAXCDNAME       NS_MAXCDNAME
#define MAXLABEL        NS_MAXLABEL
#define HFIXEDSZ        NS_HFIXEDSZ
#define QFIXEDSZ        NS_QFIXEDSZ
#define RRFIXEDSZ       NS_RRFIXEDSZ
#define INT32SZ         NS_INT32SZ
#define INT16SZ         NS_INT16SZ
#define INADDRSZ        NS_INADDRSZ
#define IN6ADDRSZ       NS_IN6ADDRSZ
#define INDIR_MASK      NS_CMPRSFLGS
#define NAMESERVER_PORT NS_DEFAULTPORT

#define S_ZONE          ns_s_zn
#define S_PREREQ        ns_s_pr
#define S_UPDATE        ns_s_ud
#define S_ADDT          ns_s_ar

#define QUERY           ns_o_query
#define IQUERY          ns_o_iquery
#define STATUS          ns_o_status
#define NS_NOTIFY_OP    ns_o_notify
#define NS_UPDATE_OP    ns_o_update

#define NOERROR         ns_r_noerror
#define FORMERR         ns_r_formerr
#define SERVFAIL        ns_r_servfail
#define NXDOMAIN        ns_r_nxdomain
#define NOTIMP          ns_r_notimpl
#define REFUSED         ns_r_refused
#define YXDOMAIN        ns_r_yxdomain
#define YXRRSET         ns_r_yxrrset
#define NXRRSET         ns_r_nxrrset
#define NOTAUTH         ns_r_notauth
#define NOTZONE         ns_r_notzone

#define DELETE          ns_uop_delete
#define ADD             ns_uop_add

#define T_A             ns_t_a
#define T_NS            ns_t_ns
#define T_MD            ns_t_md
#define T_MF            ns_t_mf
#define T_CNAME         ns_t_cname
#define T_SOA           ns_t_soa
#define T_MB            ns_t_mb
#define T_MG            ns_t_mg
#define T_MR            ns_t_mr
#define T_NULL          ns_t_null
#define T_WKS           ns_t_wks
#define T_PTR           ns_t_ptr
#define T_HINFO         ns_t_hinfo
#define T_MINFO         ns_t_minfo
#define T_MX            ns_t_mx
#define T_TXT           ns_t_txt
#define T_RP            ns_t_rp
#define T_AFSDB         ns_t_afsdb
#define T_X25           ns_t_x25
#define T_ISDN          ns_t_isdn
#define T_RT            ns_t_rt
#define T_NSAP          ns_t_nsap
#define T_NSAP_PTR      ns_t_nsap_ptr
#define T_SIG           ns_t_sig
#define T_KEY           ns_t_key
#define T_PX            ns_t_px
#define T_GPOS          ns_t_gpos
#define T_AAAA          ns_t_aaaa
#define T_LOC           ns_t_loc
#define T_NXT           ns_t_nxt
#define T_EID           ns_t_eid
#define T_NIMLOC        ns_t_nimloc
#define T_SRV           ns_t_srv
#define T_ATMA          ns_t_atma
#define T_NAPTR         ns_t_naptr
#define T_TSIG          ns_t_tsig
#define T_IXFR          ns_t_ixfr
#define T_AXFR          ns_t_axfr
#define T_MAILB         ns_t_mailb
#define T_MAILA         ns_t_maila
#define T_ANY           ns_t_any

#define C_IN            ns_c_in
#define C_CHAOS         ns_c_chaos
#define C_HS            ns_c_hs
#define C_NONE          ns_c_none
#define C_ANY           ns_c_any

__END_DECLS

#endif
