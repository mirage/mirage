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
 *
 * The w89k uses a memory mapped I/O scheme as well as a PC style ISA bus.
 * All I/O accesses are via a port.
 */
#define IOSPACE		0xf0000000
#define	outp(port,val)	*((volatile unsigned char*)(IOSPACE+port))=val
#define	inp(port)	*((volatile unsigned char*)(IOSPACE+port))
#define RS232PORT	0x3f8
#define COM1_LSR	(0x3f8 + 5)
#define COM1_DATA	(0x3f8 + 0)

#define RS232REG	0x3fd
#define TRANSMIT	0x20
#define RECEIVE		0x01
