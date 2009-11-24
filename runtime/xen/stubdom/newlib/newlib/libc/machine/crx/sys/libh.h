/* libh.h -- CRX default handlers
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

#ifndef	_LIBH
#define _LIBH

/* These are the first 16 entries of the default dispatch table as defined
   in the CompactRISC architecture:

   Entry    Function
   -----    --------
    0	    NULL
    1	    nmi
    2	    NULL
    3	    NULL
    4	    NULL
    5	    svc
    6	    dvz
    7	    flg
    8	    bpt
    9	    trc
   10	    und
   11	    NULL
   12	    iad
   13	    NULL
   14	    dbg
   15	    ise
*/

extern void (* const _dispatch_table[])(void);

/* Function prototypes */
void svc_handler(void);
void dvz_handler(void);
void flg_handler(void);
void und_handler(void);
void iad_handler(void);

#endif  /* _LIBH */
