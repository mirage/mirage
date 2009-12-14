/***********************************************************************/
/*                                                                     */
/*                           Objective Caml                            */
/*                                                                     */
/*            Xavier Leroy, projet Cristal, INRIA Rocquencourt         */
/*                                                                     */
/*  Copyright 1996 Institut National de Recherche en Informatique et   */
/*  en Automatique.  All rights reserved.  This file is distributed    */
/*  under the terms of the GNU Library General Public License, with    */
/*  the special exception on linking described in file ../../LICENSE.  */
/*                                                                     */
/***********************************************************************/

/* $Id: socketaddr.c,v 1.23 2005/03/24 17:20:53 doligez Exp $ */

#include <string.h>
#include <mlvalues.h>
#include <alloc.h>
#include <memory.h>
#include <errno.h>
#include "unixsupport.h"

#include "socketaddr.h"

CAMLexport value alloc_inet_addr(struct in_addr * a)
{
  value res;
  /* Use a string rather than an abstract block so that it can be
     marshaled safely.  Remember that a is in network byte order,
     hence is marshaled in an endian-independent manner. */
  res = alloc_string(4);
  memcpy(String_val(res), a, 4);
  return res;
}

void get_sockaddr(value mladr,
                  union sock_addr_union * adr /*out*/,
                  socklen_param_type * adr_len /*out*/)
{
  switch(Tag_val(mladr)) {
  case 1:                       /* ADDR_INET */
    memset(&adr->s_inet, 0, sizeof(struct sockaddr_in));
    adr->s_inet.sin_family = AF_INET;
    adr->s_inet.sin_addr = GET_INET_ADDR(Field(mladr, 0));
    adr->s_inet.sin_port = htons(Int_val(Field(mladr, 1)));
    *adr_len = sizeof(struct sockaddr_in);
    break;
  }
}

value alloc_sockaddr(union sock_addr_union * adr /*in*/,
                     socklen_param_type adr_len, int close_on_error)
{
  value res;
  switch(adr->s_gen.sa_family) {
  case AF_INET:
    { value a = alloc_inet_addr(&adr->s_inet.sin_addr);
      Begin_root (a);
        res = alloc_small(2, 1);
        Field(res,0) = a;
        Field(res,1) = Val_int(ntohs(adr->s_inet.sin_port));
      End_roots();
      break;
    }
  default:
    if (close_on_error != -1) close (close_on_error);
    unix_error(EAFNOSUPPORT, "", Nothing);
  }
  return res;
}

