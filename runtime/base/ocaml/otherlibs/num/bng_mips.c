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

/* $Id: bng_mips.c 5880 2003-10-24 09:18:01Z xleroy $ */

/* Code specific to the MIPS architecture. */

#define BngMult(resh,resl,arg1,arg2)                                        \
  asm("multu %2, %3 \n\t"                                                   \
      "mflo %0 \n\t"                                                        \
      "mfhi %1"                                                             \
      : "=r" (resl), "=r" (resh)                                            \
      : "r" (arg1), "r" (arg2))

