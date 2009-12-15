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

/* $Id: socketaddr.h,v 1.16 2005/03/24 17:20:53 doligez Exp $ */

#include <misc.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

union sock_addr_union {
  struct sockaddr s_gen;
  struct sockaddr_in s_inet;
};

typedef socklen_t socklen_param_type;

extern void get_sockaddr (value mladdr,
                          union sock_addr_union * addr /*out*/,
                          socklen_param_type * addr_len /*out*/);
CAMLexport value alloc_sockaddr (union sock_addr_union * addr /*in*/,
                      socklen_param_type addr_len, int close_on_error);
CAMLexport value alloc_inet_addr (struct in_addr * inaddr);
#define GET_INET_ADDR(v) (*((struct in_addr *) (v)))

