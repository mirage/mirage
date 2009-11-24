/*
 * mbx-outbyte.c -- outbyte function for targets using the eppcbug monitor
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

#include "ppc-asm.h"

static int sendbyte(char c)
{
    struct {
	unsigned clun;
	unsigned dlun;
	char     *data;
	unsigned len;
	unsigned rsrvd;
	char     buf[4];
    } ipb, *inpb;

    struct {
	int status;
	int cnt;
    } opb, *outpb;

    inpb = &ipb;
    outpb = &opb;

    inpb->clun = 0;
    inpb->dlun = 0;
    inpb->data = ipb.buf;
    inpb->len  = 1;
    inpb->rsrvd = 0;
    inpb->buf[0] = c;

    asm volatile (
        "mr  3,%0\n"
        "mr  4,%1\n"
        "li  10,0x201\n"
	"sc"
	: /* no outputs */
	: "r" (inpb), "r" (outpb)
	: "3", "4", "10"
    );

    return (outpb->status == 0 && outpb->cnt == 1);
}

#define GDB_QUOTE_OUTBYTES 1

void outbyte(char c)
{
#ifdef GDB_QUOTE_OUTBYTES
    /*
     *  GDB monitor.c will echo characters quoted with ^O
     */
    while (!sendbyte('\017')) ;
#endif
    while (!sendbyte(c)) ;
}


