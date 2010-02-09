/* @(#)get_myaddress.c	2.1 88/07/29 4.0 RPCSRC */
/*
 * Sun RPC is a product of Sun Microsystems, Inc. and is provided for
 * unrestricted use provided that this legend is included on all tape
 * media and as a part of the software program in whole or part.  Users
 * may copy or modify Sun RPC without charge, but are not authorized
 * to license or distribute it to anyone else except as part of a product or
 * program developed by the user.
 * 
 * SUN RPC IS PROVIDED AS IS WITH NO WARRANTIES OF ANY KIND INCLUDING THE
 * WARRANTIES OF DESIGN, MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE, OR ARISING FROM A COURSE OF DEALING, USAGE OR TRADE PRACTICE.
 * 
 * Sun RPC is provided with no support and without any obligation on the
 * part of Sun Microsystems, Inc. to assist in its use, correction,
 * modification or enhancement.
 * 
 * SUN MICROSYSTEMS, INC. SHALL HAVE NO LIABILITY WITH RESPECT TO THE
 * INFRINGEMENT OF COPYRIGHTS, TRADE SECRETS OR ANY PATENTS BY SUN RPC
 * OR ANY PART THEREOF.
 * 
 * In no event will Sun Microsystems, Inc. be liable for any lost revenue
 * or profits or other special, indirect and consequential damages, even if
 * Sun has been advised of the possibility of such damages.
 * 
 * Sun Microsystems, Inc.
 * 2550 Garcia Avenue
 * Mountain View, California  94043
 */
#if !defined(lint) && defined(SCCSIDS)
static char sccsid[] =

	"@(#)get_myaddress.c 1.4 87/08/11 Copyr 1984 Sun Micro";
#endif

/*
 * get_myaddress.c
 *
 * Get client's IP address via ioctl.  This avoids using the yellowpages.
 * Copyright (C) 1984, Sun Microsystems, Inc.
 */

#include <rpc/types.h>
#include <rpc/pmap_prot.h>
#include <rpc/clnt.h>
#include <sys/socket.h>
#include <stdio.h>
//#include <net/if.h>
#include <sys/ioctl.h>
#include <arpa/inet.h>
#include <netinet/in.h>

/* DO use gethostbyname because it's portable */
#include <unistd.h>
#include <netdb.h>
#include <string.h>
void get_myaddress(struct sockaddr_in* addr)
{
	char localhost[256 + 1];
	struct hostent *hp;

	gethostname(localhost, 256);
	if ((hp = gethostbyname(localhost)) == NULL) {
		perror("get_myaddress: gethostbyname");
		exit(1);
	}
	addr->sin_family = AF_INET;
	memmove((char *) &addr->sin_addr, (char *) hp->h_addr, hp->h_length);
	addr->sin_port = htons(PMAPPORT);
}
