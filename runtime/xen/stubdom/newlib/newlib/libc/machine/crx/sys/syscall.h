/* syscall.h -- CRX virtual I/O and trap service codes
 *
 * Copyright (c) 2004 National Semiconductor Corporation
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

#ifndef _SYSCALL_H
#define _SYSCALL_H

#include <sys/asm.h>

/* SVC codes to pass to the debugger */

/* Virtual I/O services */
#define SVC_OPEN	0x401
#define SVC_CLOSE	0x402
#define SVC_READ	0x403
#define SVC_WRITE	0x404
#define SVC_LSEEK	0x405
#define SVC_RENAME	0x406
#define SVC_UNLINK	0x407
#define SVC_GETENV	0x408

/* Time service */
#define SVC_TIME        0x300

/* Start/end of program services */
#define SVC_EOP		0x410

/* Trap services */
#define SVC_SVC		0x505
#define SVC_DVZ		0x506
#define SVC_FLG		0x507
#define SVC_UND		0x50a
#define SVC_IAD		0x50c


/* Places the code of the requested service in R0, then transfers control
   to the debugger using the BPT exception.
   It is called from the start routine, VIO functions and the trap
   handlers.  */

#define STRINGIFY(x)	#x
#define HOST_SERVICE(service) \
  do { \
    __asm__("movd\t$" STRINGIFY(service) ",r0"); \
    _excp_(bpt); \
    __asm__(".short\t0xFFFF"); \
  } while (0)

#endif  /* _SYSCALL_H */

