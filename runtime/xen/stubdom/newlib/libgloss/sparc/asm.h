/* asm.h -- macros for sparc asm
 *
 * Copyright (c) 1996 Cygnus Support
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */

#ifndef __SPARC_ASM_h
#define __SPARC_ASM_h

/* Indicate we are in an assembly file and get the basic CPU definitions.  */
#define ASM

/* ANSI concatenation macros.  */
#define CONCAT1(a, b) CONCAT2(a, b)
#define CONCAT2(a, b) a ## b

/* Use the right prefix for global labels.
   Note that it's too late to have coff have no underscores
   (would break user programs).
   One school of thought likes having underscores for both a.out and coff
   (simplicity in consistency).  */
#define SYM(x) CONCAT1 (__USER_LABEL_PREFIX__,x)

/* STRINGSYM makes a string out of a symbol name with the proper assembly
   prefix.  Useful for inline assembly language in C source files.  */
#define STRINGIT2(x) #x
#define STRINGIT1(x) STRINGIT2(x)
#define STRINGSYM(x) STRINGIT1(SYM(x))

#endif
