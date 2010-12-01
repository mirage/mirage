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

/* $Id: closedir.c 6113 2004-02-14 10:21:23Z xleroy $ */

#include <mlvalues.h>
#include "unixsupport.h"
#include <errno.h>
#include <sys/types.h>
#ifdef HAS_DIRENT
#include <dirent.h>
#else
#include <sys/dir.h>
#endif

CAMLprim value unix_closedir(value vd)
{
  DIR * d = DIR_Val(vd);
  if (d == (DIR *) NULL) unix_error(EBADF, "closedir", Nothing);
  closedir(d);
  DIR_Val(vd) = (DIR *) NULL;
  return Val_unit;
}
