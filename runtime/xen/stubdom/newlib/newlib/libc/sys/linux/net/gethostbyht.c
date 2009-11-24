/*-
 * Copyright (c) 1985, 1988, 1993
 *	The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the University of
 *	California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 * -
 * Portions Copyright (c) 1993 by Digital Equipment Corporation.
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies, and that
 * the name of Digital Equipment Corporation not be used in advertising or
 * publicity pertaining to distribution of the document or software without
 * specific, written prior permission.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND DIGITAL EQUIPMENT CORP. DISCLAIMS ALL
 * WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS.   IN NO EVENT SHALL DIGITAL EQUIPMENT
 * CORPORATION BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
 * DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
 * PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
 * ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
 * SOFTWARE.
 * -
 * --Copyright--
 */

#if defined(LIBC_SCCS) && !defined(lint)
static char sccsid[] = "@(#)gethostnamadr.c	8.1 (Berkeley) 6/4/93";
#endif /* LIBC_SCCS and not lint */
#include <sys/cdefs.h>
#include <sys/types.h>

#include <sys/param.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <stdarg.h>
#include <nsswitch.h>
#include <arpa/nameser.h>	/* XXX */
#include <resolv.h>		/* XXX */
#include <dirent.h>
#include <stdlib.h>
#include <errno.h>

static FILE *hostf = NULL;
static int stayopen = 0;
__LOCK_INIT(static, host_lock);

void
_sethosthtent_r(int f, FILE **hostfile, int *hstayopen)
{
	if (!*hostfile)
		*hostfile = fopen(_PATH_HOSTS, "r" );
	else
		rewind(*hostfile);
	*hstayopen = f;
}

void
_endhosthtent_r(FILE **hostfile, int *hstayopen)
{
	if (*hostfile && !*hstayopen) {
		(void) fclose(*hostfile);
		*hostfile = NULL;
	}
}

void
_sethosthtent(f)
	int f;
{
  _sethosthtent_r(f, &hostf, &stayopen);
}

void
_endhosthtent()
{
  _endhosthtent_r(&hostf, &stayopen);
}

struct hostent *
gethostent()
{
  static struct hostent hp;
  static char buffer[BUFSIZ+1];
  static int len = BUFSIZ;
  static int herr;

#ifdef HAVE_DD_LOCK
  __lock_acquire(host_lock);
#endif
  gethostent_r(&hp, buffer, len, &herr, &hostf);
#ifdef HAVE_DD_LOCK
  __lock_release(host_lock);
#endif
  return &hp;
}

int
gethostent_r(struct hostent *hp, char *buffer, int buflen, int *herr, FILE **hostfile)
{
	char *p;
	char *cp, **q;
	int af, len;

	if (!*hostfile && !(*hostfile = fopen(_PATH_HOSTS, "r" ))) {
		*herr = NETDB_INTERNAL;
		return -1;
	}
 again:
	if (!(p = fgets(buffer, buflen, *hostfile))) {
		*herr = HOST_NOT_FOUND;
		return -1;
	}
	if (*p == '#')
		goto again;
	if (!(cp = strpbrk(p, "#\n")))
		goto again;
	*cp = '\0';
	if (!(cp = strpbrk(p, " \t")))
		goto again;
	*cp++ = '\0';

        hp->h_addr_list = hp->__host_addrs;
        hp->__host_addrs[0] = (char *)hp->__host_addr;

	if (inet_pton(AF_INET6, p, hp->h_addr_list[0]) > 0) {
		af = AF_INET6;
		len = IN6ADDRSZ;
	} else if (inet_pton(AF_INET, p, hp->h_addr_list[0]) > 0) {
		if (_res.options & RES_USE_INET6) {
			_map_v4v6_address(hp->h_addr_list[0], hp->h_addr_list[0]);
			af = AF_INET6;
			len = IN6ADDRSZ;
		} else {
			af = AF_INET;
			len = INADDRSZ;
		}
	} else {
		goto again;
	}

        
	hp->h_addr_list[1] = NULL;
        hp->h_addr = hp->__host_addrs[0];
	hp->h_length = len;
	hp->h_addrtype = af;

	while (*cp == ' ' || *cp == '\t')
		cp++;
	hp->h_name = cp;
	q = hp->h_aliases = hp->__host_aliases;
        if ((cp = strpbrk(cp, " \t")) != NULL)
          *cp++ = '\0';
        while (cp && *cp) {
          if (*cp == ' ' || *cp == '\t') {
            cp++;
            continue;
          }
          if (q < &hp->h_aliases[MAXALIASES - 1])
            *q++ = cp;
          if ((cp = strpbrk(cp, " \t")) != NULL)
            *cp++ = '\0';
        }
        *q = NULL;

	*herr = NETDB_SUCCESS;
	return 0;
}

int
_ht_gethostbyname(void *rval, void *cb_data, va_list ap) 
{
	char **cp;
	const char *name;
	int af;
        struct hostent *resultbuf;
        char *buf;
        int buflen;
        int *herr;
        FILE *hostfile = NULL;
        int stayopen;
        int p;

	name = va_arg(ap, const char *);
	af = va_arg(ap, int);
        resultbuf = va_arg(ap, struct hostent *);
        buf = va_arg(ap, char *);
        buflen = va_arg(ap, int);
        herr = va_arg(ap, int *);

	sethostent_r(0, &hostfile, &stayopen);
	while ((p = gethostent_r(resultbuf, buf, buflen, herr, &hostfile)) != -1) {
		if (resultbuf->h_addrtype != af)
			continue;
		if (strcasecmp(resultbuf->h_name, name) == 0)
			break;
                for (cp = resultbuf->h_aliases; *cp != 0; cp++)
                  if (strcasecmp(*cp, name) == 0)
                    goto found;
	}
found:
	endhostent_r(&hostfile, &stayopen);

        if (p == -1)
          {
            *(struct hostent **)rval = NULL;
            return NS_NOTFOUND;
            }
        else
          {
            *(struct hostent **)rval = resultbuf;
            return NS_SUCCESS;
          }
}

int 
_ht_gethostbyaddr(void *rval, void *cb_data, va_list ap)
{
	const char *addr;
	int len, af;
        struct hostent *resultbuf;
        char *buf;
        int buflen;
        int *herr;
        FILE *hostfile = NULL;
        int stayopen;
        int p;

	addr = va_arg(ap, const char *);
	len = va_arg(ap, int);
	af = va_arg(ap, int);
        resultbuf = va_arg(ap, struct hostent *);
        buf = va_arg(ap, char *);
        buflen = va_arg(ap, int);
        herr = va_arg(ap, int *);

	sethostent_r(0, &hostfile, &stayopen);
	while ((p = gethostent_r(resultbuf, buf, buflen, herr, &hostfile)) != -1)
		if (resultbuf->h_addrtype == af && !memcmp(resultbuf->h_addr, addr, len))
			break;
	endhostent_r(&hostfile, &stayopen);

        if (p == -1)
          {
            *(struct hostent **)rval = NULL;
            return NS_NOTFOUND;
            }
        else
          {
            *(struct hostent **)rval = resultbuf;
            return NS_SUCCESS;
          }
}
