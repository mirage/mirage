#ifndef _LIBINTL_H
#define _LIBINTL_H

#include <sys/cdefs.h>
#include <sys/types.h>
#include <locale.h>

__BEGIN_DECLS

char* gettext(const char* msgid) __THROW;
char* dgettext(const char* domainname, const char* msgid) __THROW;
char* dcgettext(const char *domainname, const char *msgid, int category) __THROW;

char* ngettext (const char* msgid, const char* msgid_plural, unsigned long int n) __THROW;
char* dngettext (const char* domainname, const char* msgid, const char* msgid_plural, unsigned long int n) __THROW;
char* dcngettext(const char* domainname,
		 const char* msgid1, const char* msgid2,
		 unsigned long int n, int __category) __THROW;

char* textdomain(const char *domainname) __THROW;
char* bindtextdomain(const char *domainname, const char *dirname) __THROW;
char* bind_textdomain_codeset(const char *domainname, const char *codeset) __THROW;

#define gettext(msgid) dgettext(0,msgid)
#define dgettext(domainname,msgid) dcgettext(domainname,msgid,LC_MESSAGES)

#define ngettext(msgid1,msgid2,n) dngettext(0,msgid1,msgid2,n)
#define dngettext(dn,msgid1,msgid2,n) dngettext(dn,msgid1,msgid2,n,LC_MESSAGES)


__END_DECLS

#endif
