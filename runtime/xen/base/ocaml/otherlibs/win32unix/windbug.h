/***********************************************************************/
/*                                                                     */
/*                           Objective Caml                            */
/*                                                                     */
/*  Contributed by Sylvain Le Gall for Lexifi                          */
/*                                                                     */
/*  Copyright 2008 Institut National de Recherche en Informatique et   */
/*  en Automatique.  All rights reserved.  This file is distributed    */
/*  under the terms of the GNU Library General Public License, with    */
/*  the special exception on linking described in file ../../LICENSE.  */
/*                                                                     */
/***********************************************************************/

/* $Id: windbug.h 10467 2010-05-25 13:01:06Z xleroy $ */

#ifdef DEBUG

#include <stdio.h>
#include <windows.h>

#define DEBUG_PRINT(fmt, ...) \
  do \
  { \
    if (debug_test()) \
    { \
      fprintf(stderr, "DBUG (pid:%d, tid: %d): ", GetCurrentProcessId(), GetCurrentThreadId()); \
      fprintf(stderr, fmt, __VA_ARGS__); \
      fprintf(stderr, "\n"); \
      fflush(stderr); \
    }; \
  } while(0)

/* Test if we are in dbug mode */
int  debug_test    (void);

#else
#define DEBUG_PRINT(fmt, ...)
#endif
