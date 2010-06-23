/***********************************************************************/
/*                                                                     */
/*                           Objective Caml                            */
/*                                                                     */
/*            Xavier Leroy, projet Cristal, INRIA Rocquencourt         */
/*                                                                     */
/*  Copyright 2003 Institut National de Recherche en Informatique et   */
/*  en Automatique.  All rights reserved.  This file is distributed    */
/*  under the terms of the GNU Library General Public License, with    */
/*  the special exception on linking described in file ../../LICENSE.  */
/*                                                                     */
/***********************************************************************/

/* $Id: ia32sse2.c 6824 2005-03-24 17:20:54Z doligez $ */

/* Test whether IA32 assembler supports SSE2 instructions */

int main()
{
  asm("pmuludq %mm1, %mm0");
  asm("paddq %mm1, %mm0");
  asm("psubq %mm1, %mm0");
  return 0;
}
