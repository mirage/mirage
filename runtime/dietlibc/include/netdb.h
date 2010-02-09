#ifndef _NETDB_H
#define _NETDB_H

#include <sys/cdefs.h>
#include <sys/types.h>

__BEGIN_DECLS

/* Absolute file name for network data base files.  */
#define	_PATH_HEQUIV		"/etc/hosts.equiv"
#define	_PATH_HOSTS		"/etc/hosts"
#define	_PATH_NETWORKS		"/etc/networks"
#define	_PATH_NSSWITCH_CONF	"/etc/nsswitch.conf"
#define	_PATH_PROTOCOLS		"/etc/protocols"
#define	_PATH_SERVICES		"/etc/services"

/* Description of data base entry for a single service.  */
struct servent {
  char *s_name;			/* Official service name.  */
  char **s_aliases;		/* Alias list.  */
  int s_port;			/* Port number.  */
  char *s_proto;		/* Protocol to use.  */
};

extern void endservent (void) __THROW;
extern void setservent(int stayopen) __THROW;

extern int getservent_r(struct servent *res, char *buf, size_t buflen,
			 struct servent **res_sig) __THROW;
extern int getservbyname_r(const char* name,const char* proto,
			   struct servent *res, char *buf, size_t buflen,
			   struct servent **res_sig) __THROW;
extern int getservbyport_r(int port,const char* proto,
			   struct servent *res, char *buf, size_t buflen,
			   struct servent **res_sig) __THROW;

extern struct servent *getservent(void) __THROW;
extern struct servent *getservbyname (const char *__name,
				      const char *__proto) __THROW;
extern struct servent *getservbyport (int __port, const char *__proto)
     __THROW;

struct hostent {
  char *h_name;			/* Official name of host.  */
  char **h_aliases;		/* Alias list.  */
  int h_addrtype;		/* Host address type.  */
  socklen_t h_length;		/* Length of address.  */
  char **h_addr_list;		/* List of addresses from name server.  */
#define	h_addr	h_addr_list[0]	/* Address, for backward compatibility.  */
};

extern void endhostent (void) __THROW;
extern struct hostent *gethostent (void) __THROW;
extern struct hostent *gethostent_r (char* buf,int len) __THROW;
extern struct hostent *gethostbyaddr (const void *__addr, socklen_t __len,
				      int __type) __THROW;
extern struct hostent *gethostbyname (const char *__name) __THROW;
extern struct hostent *gethostbyname2 (const char *__name, int __af) __THROW;

/* this glibc "invention" is so ugly, I'm going to throw up any minute
 * now */
extern int gethostbyname_r(const char* NAME, struct hostent* RESULT_BUF,char* BUF,
			   size_t BUFLEN, struct hostent** RESULT,
			   int* H_ERRNOP) __THROW;

#define HOST_NOT_FOUND 1
#define TRY_AGAIN 2
#define NO_RECOVERY 3
#define NO_ADDRESS 4
#define NO_DATA 5

extern int gethostbyaddr_r(const char* addr, size_t length, int format,
		    struct hostent* result, char *buf, size_t buflen,
		    struct hostent **RESULT, int *h_errnop) __THROW;

int gethostbyname2_r(const char* name, int AF, struct hostent* result,
		    char *buf, size_t buflen,
		    struct hostent **RESULT, int *h_errnop) __THROW;

struct protoent {
  char    *p_name;        /* official protocol name */
  char    **p_aliases;    /* alias list */
  int     p_proto;        /* protocol number */
};

struct protoent *getprotoent(void) __THROW;
struct protoent *getprotobyname(const char *name) __THROW;
struct protoent *getprotobynumber(int proto) __THROW;
void setprotoent(int stayopen) __THROW;
void endprotoent(void) __THROW;

int getprotoent_r(struct protoent *res, char *buf, size_t buflen,
		  struct protoent **res_sig) __THROW;
int getprotobyname_r(const char* name,
		     struct protoent *res, char *buf, size_t buflen,
		     struct protoent **res_sig) __THROW;
int getprotobynumber_r(int proto,
		      struct protoent *res, char *buf, size_t buflen,
		      struct protoent **res_sig) __THROW;


void sethostent(int stayopen) __THROW;

/* dummy */
extern int h_errno;

struct netent {
  char    *n_name;          /* official network name */
  char    **n_aliases;      /* alias list */
  int     n_addrtype;       /* net address type */
  unsigned long int n_net;  /* network number */
};

struct netent *getnetbyaddr(unsigned long net, int type) __THROW;
void endnetent(void) __THROW;
void setnetent(int stayopen) __THROW;
struct netent *getnetbyname(const char *name) __THROW;
struct netent *getnetent(void) __THROW;

extern const char *hstrerror (int err_num) __THROW;
void herror(const char *s) __THROW;

#define NI_MAXHOST 1025
#define NI_MAXSERV 32

__END_DECLS

#endif
