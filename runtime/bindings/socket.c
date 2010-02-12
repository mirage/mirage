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

/* $Id: socket.c,v 1.11 2005/03/24 17:20:53 doligez Exp $ */

#include <fail.h>
#include <mlvalues.h>
#include "unixsupport.h"

#include <sys/types.h>
#include <sys/socket.h>

int socket_domain_table[] = {
  PF_INET,
  0
};

int socket_type_table[] = {
  SOCK_STREAM, SOCK_DGRAM, SOCK_RAW
};

CAMLprim value unix_socket(value domain, value type, value proto)
{
  int retcode;
  retcode = socket(socket_domain_table[Int_val(domain)],
                   socket_type_table[Int_val(type)],
                   Int_val(proto));
  if (retcode == -1) uerror("socket", Nothing);
  return Val_int(retcode);

}
