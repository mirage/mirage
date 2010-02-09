#ifndef _POSIX_NETDB_H_
#define _POSIX_NETDB_H_

struct hostent {
    char *h_addr;
};
#define gethostbyname(buf) NULL

#endif /* _POSIX_NETDB_H_ */
