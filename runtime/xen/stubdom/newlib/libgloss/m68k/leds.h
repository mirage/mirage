/* leds.c -- control the led's on a Motorola mc68ec0x0 board.
 *           Written by rob@cygnus.com (Rob Savoye)
 *
 * Copyright (c) 1995, 1996 Cygnus Support
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

#ifndef __LEDS_H__
#define __LEDS_H__

#define LED_ADDR	0xd00003
#define LED_0           ~0x1
#define LED_1           ~0x2
#define LED_2           ~0x4
#define LED_3           ~0x8
#define LED_4           ~0x10
#define LED_5           ~0x20
#define LED_6           ~0x40
#define LED_7           ~0x80
#define LEDS_OFF	0xff
#define LEDS_ON		0x0

#define FUDGE(x) ((x >= 0xa && x <= 0xf) ? (x + 'a') & 0x7f : (x + '0') & 0x7f)

extern void led_putnum( char );
void zylons();

#endif		/* __LEDS_H__ */
