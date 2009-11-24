/* Copyright (c) 1995 Cygnus Support
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
extern int led_putnum();
extern char putDebugChar(),print(),putnum(); 
#include <stdio.h>

main()
{
  float a1,b1,c1;
  int a2, b2, c2;

  a1 = 0.41;
  b1 = 3.12;
  c1 = a1+b1;

  a2 = 1;
  b2 = 2;
  c2 = a2 + b2;

  iprintf ("Print integer, result = %d\n", c2);
  fflush (stdout);
  putnum (c1);
  outbyte ('\n');
  printf ("Print float, result with 'f' = %f\n", c1);
  printf ("Print float, result with 'e' = %e\n", c1);
  printf ("Print float, result with 'E' = %E\n", c1);
  printf ("Print float, result with 'g' = %g\n", c1);
  printf ("Print float, result with 'G' = %G\n", c1);
  fflush (stdout);
  print ("Done...\n");
}
