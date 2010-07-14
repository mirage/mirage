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

/* $Id: exit.c,v 1.9 2001/12/07 13:40:28 xleroy Exp $ */

#include <caml/mlvalues.h>
#include <mini-os/kernel.h>

CAMLprim value unix_exit(value n)
{
  do_exit();
  return Val_unit;
}
