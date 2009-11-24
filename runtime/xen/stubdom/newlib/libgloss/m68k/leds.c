/*
 * leds.c -- control the led's on a Motorola mc68ec0x0 board.
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
#include "leds.h"

/*
 * led_putnum -- print a hex number on the LED. the value of num must be a char with
 *              the ascii value. ie... number 0 is '0', a is 'a', ' ' (null) clears
 *		the led display.
 *		Setting the bit to 0 turns it on, 1 turns it off.
 * 		the LED's are controlled by setting the right bit mask in the base
 * 		address. 
 *		The bits are:
 *			[d.p | g | f | e | d | c | b | a ] is the byte.
 *
 *		The locations are:
 *		
 *			 a
 *		       -----
 *		    f |     | b
 *		      |  g  |
 *		       -----
 *                    |     |
 *                  e |     | c
 *                     -----
 *                       d                . d.p (decimal point)
 */
void
led_putnum ( num )
char num;
{
    static unsigned char *leds = (unsigned char *)LED_ADDR;
    static unsigned char num_bits [18] = {
      0xff,						/* clear all */
      0xc0, 0xf9, 0xa4, 0xb0, 0x99, 0x92, 0x82, 0xf8, 0x80, 0x98, /* numbers 0-9 */
      0x98, 0x20, 0x3, 0x27, 0x21, 0x4, 0xe 		/* letters a-f */
    };

    if (num >= '0' && num <= '9')
      num = (num - '0') + 1;

    if (num >= 'a' && num <= 'f')
      num = (num - 'a') + 12;

    if (num == ' ')
      num = 0;

    *leds = num_bits[num];
}

/*
 * zylons -- draw a rotating pattern. NOTE: this function never returns.
 */
void
zylons()
{
  unsigned char *leds 	= (unsigned char *)LED_ADDR;
  unsigned char curled = 0xfe;

  while (1)
    {
      *leds = curled;
      curled = (curled >> 1) | (curled << 7);
      delay ( 200 );
    }
}
