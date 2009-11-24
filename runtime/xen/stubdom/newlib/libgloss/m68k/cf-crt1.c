/* Initialization code for coldfire boards.
 *
 * Copyright (c) 2006 CodeSourcery Inc
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

#include <stdlib.h>

extern const int __interrupt_vector[];
extern void __reset (void);

extern const char __data_load[] __attribute__ ((aligned (4)));
extern char __data_start[] __attribute__ ((aligned (4)));
extern char __bss_start[] __attribute__ ((aligned (4)));
extern char __end[] __attribute__ ((aligned (4)));
void *__heap_limit;
extern void software_init_hook (void) __attribute__ ((weak));
extern void hardware_init_hook (void) __attribute__ ((weak));
extern void _init (void);
extern void _fini (void);

extern int main (int, char **, char **);

/* This is called from a tiny assembly stub.  */
void __start1 (void *heap_limit)
{
  unsigned ix;
  
  if (hardware_init_hook)
    hardware_init_hook ();
  
  /* Initialize memory */
  if (__data_load != __data_start)
    memcpy (__data_start, __data_load, __bss_start - __data_start);
  memset (__bss_start, 0, __end - __bss_start);
  
  __heap_limit = heap_limit;
  
  if (software_init_hook)
    software_init_hook ();

  _init ();

  /* I'm not sure how useful it is to have a fini_section in an
     embedded system.  */
  atexit (_fini);
  
  ix = main (0, NULL, NULL);
  exit (ix);
  
  while (1)
    __reset ();
}

/* A default hardware init hook.  */

void __attribute__ ((weak)) hardware_init_hook (void)
{
  /* Set the VBR. */
  __asm__ __volatile__ ("movec.l %0,%/vbr" :: "r" (__interrupt_vector));

#ifndef __mcf_family_5213
  /* Flush & enable the caches */
#define CACR_CINV (1 << 24)
#define CACR_CENB (1 << 31)
  __asm__ __volatile__ ("movec.l %0,%/cacr" :: "r" (CACR_CINV | CACR_CENB));
#endif

  /* Should we drop into user mode here? */
}
