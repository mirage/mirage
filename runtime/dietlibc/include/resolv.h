#ifndef _RESOLV_H
#define _RESOLV_H

#include <sys/param.h>
#include <sys/types.h>
#include <stdio.h>
#include <netinet/in.h>

__BEGIN_DECLS

#ifndef _PATH_RESCONF
#define _PATH_RESCONF        "/etc/resolv.conf"
#endif

/*
 * Global defines and variables for resolver stub.
 */
#define	MAXNS			8	/* max # name servers we'll track */
#define	MAXDFLSRCH		3	/* # default domain levels to try */
#define	MAXDNSRCH		6	/* max # domains in search path */
#define	LOCALDOMAINPARTS	2	/* min levels in name that is "local" */

#define	RES_TIMEOUT		5	/* min. seconds between retries */
#define	MAXRESOLVSORT		10	/* number of net to sort on */
#define	RES_MAXNDOTS		15	/* should reflect bit field size */

typedef struct __res_state {
  int	retrans;	 	/* retransmission time interval */
  int	retry;			/* number of times to retransmit */
  unsigned long	options;		/* option flags - see below. */
  int	nscount;		/* number of name servers */
  struct sockaddr_in_pad
	  nsaddr_list[MAXNS];	/* address of name server */
#define	nsaddr	nsaddr_list[0]		/* for backward compatibility */
  unsigned short	id;			/* current message id */
  char	*dnsrch[MAXDNSRCH+1];	/* components of domain to search */
  char	defdname[256];		/* default domain (deprecated) */
  unsigned long	pfcode;			/* RES_PRF_ flags - see below. */
  unsigned ndots:4;		/* threshold for initial abs. query */
  unsigned nsort:4;		/* number of elements in sort_list[] */
  char	unused[3];
  struct {
    struct in_addr	addr;
    uint32_t	mask;
  } sort_list[MAXRESOLVSORT];
  char	pad[72];		/* on an i386 this means 512b total */
} * res_state;

/*
 * Resolver options (keep these in synch with res_debug.c, please)
 */
#define RES_INIT	0x00000001	/* address initialized */
#define RES_DEBUG	0x00000002	/* print debug messages */
#define RES_AAONLY	0x00000004	/* authoritative answers only (!IMPL)*/
#define RES_USEVC	0x00000008	/* use virtual circuit */
#define RES_PRIMARY	0x00000010	/* query primary server only (!IMPL) */
#define RES_IGNTC	0x00000020	/* ignore trucation errors */
#define RES_RECURSE	0x00000040	/* recursion desired */
#define RES_DEFNAMES	0x00000080	/* use default domain name */
#define RES_STAYOPEN	0x00000100	/* Keep TCP socket open */
#define RES_DNSRCH	0x00000200	/* search up local domain tree */
#define	RES_INSECURE1	0x00000400	/* type 1 security disabled */
#define	RES_INSECURE2	0x00000800	/* type 2 security disabled */
#define	RES_NOALIASES	0x00001000	/* shuts off HOSTALIASES feature */
#define	RES_USE_INET6	0x00002000	/* use/map IPv6 in gethostbyname() */

#define RES_DEFAULT	(RES_RECURSE | RES_DEFNAMES | RES_DNSRCH)

/*
 * Resolver "pfcode" values.  Used by dig.
 */
#define RES_PRF_STATS	0x00000001
/*			0x00000002	*/
#define RES_PRF_CLASS   0x00000004
#define RES_PRF_CMD	0x00000008
#define RES_PRF_QUES	0x00000010
#define RES_PRF_ANS	0x00000020
#define RES_PRF_AUTH	0x00000040
#define RES_PRF_ADD	0x00000080
#define RES_PRF_HEAD1	0x00000100
#define RES_PRF_HEAD2	0x00000200
#define RES_PRF_TTLID	0x00000400
#define RES_PRF_HEADX	0x00000800
#define RES_PRF_QUERY	0x00001000
#define RES_PRF_REPLY	0x00002000
#define RES_PRF_INIT    0x00004000
/*			0x00008000	*/

struct res_sym {
	int	number;		/* Identifying number, like T_MX */
	char *	name;		/* Its symbolic name, like "MX" */
	char *	humanname;	/* Its fun name, like "mail exchanger" */
};

extern struct __res_state _res;
extern const struct res_sym __p_class_syms[];
extern const struct res_sym __p_type_syms[];

int res_init(void) __THROW;

int res_query(const char *dname, int _class, int type,
      unsigned char *answer, int anslen) __THROW;

int res_search(const char *dname, int _class, int type,
      unsigned char *answer, int anslen) __THROW;

int res_querydomain(const char *name, const char *domain,
      int _class, int type, unsigned char *answer,
      int anslen) __THROW;

int res_mkquery(int op, const char *dname, int _class,
      int type, char *data, int datalen, const unsigned char* newrr,
      char *buf, int buflen) __THROW;

int res_send(const char *msg, int msglen, char *answer,
      int anslen) __THROW;

int dn_comp(unsigned char *msg, unsigned char *comp_dn,
      int length, unsigned char **dnptrs, unsigned char *exp_dn,
      unsigned char **lastdnptr) __THROW;

int dn_expand(const unsigned char *msg, const unsigned char *eomorig,
      const unsigned char *comp_dn, unsigned char *exp_dn,
      int length) __THROW;

void res_close(void) __THROW __attribute_dontuse__;

int dn_skipname(const unsigned char* cur,const unsigned char* eom) __THROW;

__END_DECLS

#endif
