/* nullmon.c - Stub or monitor services.
 *
 * Copyright (c) 1998 Cygnus Support
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

/* This is a ROMSTUB
    Various libraries in libgloss may reference board specific services.
   These are often performed by system calls and by rom specific
   interfaces such as dvemon.c This file defines the null interface in
   which the rom monitor either does not exist or is not used.
   Linking with this file supports applications which only exercise
   the processor, specifically, the GDB test suite.
   By linking this object in rather than a monitor specific support
   we can insure that the testsuite will run without references or
   linkages to nonexistent monitor services.
   Similarly, every service provided by this file muse be provided by all
   monitor speciifc interfaces.
   PLEASE DO NOT MAKE THIS FILE SPECIFIC TO ANY MONITOR
 */   

/* This form is giving linker relocation errors */
#if ! defined(BOARD_MEM_SIZE)
#define BOARD_MEM_SIZE 0x100000 /* About a megabyte */
#endif
extern char _ftext[]; /* Defined in nullmon.ld */
extern char _end[];   /* Defined in nullmon.ld */

#if defined(FIXME_WARNINGS)
#warning("FIXME: struct s_mem belongs in a header file")
#endif
struct s_mem
{ unsigned int size;
  unsigned int icsize;
  unsigned int dcsize;
};

void
get_mem_info (mem)
     struct s_mem *mem;
{
  mem->size = BOARD_MEM_SIZE - (_end - _ftext);
}

/*  SYSTEM INTERFACE
  Since we are defining a NULL operating environment here, I am
  entering the stub definitions for the GNUpro libraries, System Calls.
  I would rather not to even pretend to support these functions but, they
  get pulled in by other libraries.
*/
 
int read(int file, char * ptr , int len) {   return 0 ; }
int close (int file) { return -1 ; }
int write(int file , char * ptr, int len) { return 0 ; }
/*eof*/
