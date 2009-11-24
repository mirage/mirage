/* op50nled.c -- fucntions that manipulate the LEDs.
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
#include "op50n.h"

void zylons();
void strobe();
void led_putnum();
void delay();

/*
 * led_putnum -- print a hex number on the LED. the value of num must be a byte. 
 *		 The max number 15, since the front panel only has 4 LEDs.
 */
void
led_putnum ( num )
char num;
{
    static unsigned char *leds = (unsigned char *)LED_ADDR;
    
/**    *leds = (num << 4); **/
    *leds = num;
}

/*
 * strobe -- do a zylons thing, toggling each led in sequence forever...
 */
void
zylons()
{
  while (1) {
    strobe();
  }
}

/*
 * strobe -- toggle each led in sequence up and back once.
 */
void
strobe()
{
  static unsigned char curled;
  static unsigned char dir;

  curled = 1;
  dir = 0;
  while (curled != 0) {
    led_putnum (curled);
    delay (70000);
    if (dir)
      curled >>= 1;
    else
      curled <<= 1;
    
    if (curled == 0x100) {
      dir = ~dir;
    }
  }
  curled = 1;
  dir = 0;
}

void
delay (x)
     int x;
{
  int  y = 17;
  while (x-- !=0)
    y = y^2;
}
