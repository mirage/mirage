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

/* $Id: addrofstr.c,v 1.11 2004/04/09 13:25:20 xleroy Exp $ */

#include <mlvalues.h>
#include <fail.h>
#include "unixsupport.h"

#include "socketaddr.h"

CAMLprim value unix_inet_addr_of_string(value s)
{
  struct in_addr address;
  if (inet_aton(String_val(s), &address) == 0)
    failwith("inet_addr_of_string");
  return alloc_inet_addr(&address);
}
