#ifndef	_CTYPE_H
#define _CTYPE_H

#include <sys/cdefs.h>

__BEGIN_DECLS

extern int isascii (int c) __THROW __attribute__ ((__const__));
extern int isblank (int c) __THROW __attribute__ ((__const__));
extern int isalnum (int c) __THROW __attribute__ ((__const__));
extern int isalpha (int c) __THROW __attribute__ ((__const__));
extern int isdigit (int c) __THROW __attribute__ ((__const__));
extern int isspace (int c) __THROW __attribute__ ((__const__));

extern int isupper (int c) __THROW __attribute__ ((__const__));
extern int islower (int c) __THROW __attribute__ ((__const__));

extern int toascii(int c) __THROW __attribute__ ((__const__));
extern int tolower(int c) __THROW __attribute__ ((__const__));
extern int toupper(int c) __THROW __attribute__ ((__const__));

extern int isprint(int c) __THROW __attribute__ ((__const__));
extern int ispunct(int c) __THROW __attribute__ ((__const__));
extern int iscntrl(int c) __THROW __attribute__ ((__const__));

/* fscking GNU extensions! */
extern int isxdigit(int c) __THROW __attribute__ ((__const__));

extern int isgraph(int c) __THROW __attribute__ ((__const__));

__END_DECLS

#endif
