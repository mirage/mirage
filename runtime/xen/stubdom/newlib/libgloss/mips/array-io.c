/* array-io.c -- I/O code for the Array Tech RAID disk controller.
 *
 * Copyright (c) 1995 Cygnus Support
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
#include "mips.h"

/*
 * outbyte -- shove a byte out the serial port. We wait till the byte 
 */
int
outbyte(byte)
     unsigned char byte;
{
  return (PUTCHAR(byte));
}

/*
 * inbyte -- get a byte from the serial port
 */
unsigned char
inbyte()
{
  return ((unsigned char)GETCHAR);
}

/*
 * led_putnum -- print a hex number on the LED. the value of num must be a byte.
 
 *               The max number 15, since the front panel only has 4 LEDs.
 */
void
led_putnum ( num )
char num;
{
  print ("Sorry, unimplemented, using putnum instead\r\n");
  putnum (num);
}

/*
 * zylons -- draw a rotating pattern. NOTE: this function never returns.
 */
void
zylons()
{
  print ("Sorry, unimplemented\r\n");
}

/*
 * delay -- a really gross, ugly hack for simple time delays
 */
void
delay (x)
     int x;
{
  int  y = 17;
  while (x-- !=0)
    y = y^2;
}
