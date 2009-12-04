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

/* $Id: sighandler.c,v 1.7 2001/12/07 13:39:44 xleroy Exp $ */

#include <signal.h>

int main(void)
{
  SIGRETURN (*old)();
  old = signal(SIGQUIT, SIG_DFL);
  return 0;
}
