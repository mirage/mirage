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

/* $Id: envir.c 6824 2005-03-24 17:20:54Z doligez $ */

#include <mlvalues.h>
#include <alloc.h>

#ifndef _WIN32
extern char ** environ;
#endif

CAMLprim value unix_environment(value unit)
{
  return copy_string_array((const char**)environ);
}
