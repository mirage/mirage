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

/* $Id: getgroups.c,v 1.8 2001/12/07 13:39:43 xleroy Exp $ */

#include <sys/types.h>
#include <limits.h>

#ifdef NGROUPS_MAX

int main(void)
{
  int gidset[NGROUPS_MAX];
  if (getgroups(NGROUPS_MAX, gidset) == -1) return 1;
  return 0;
}

#else

int main(void) { return 1; }

#endif
