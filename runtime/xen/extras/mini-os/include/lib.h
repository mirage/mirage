/* -*-  Mode:C; c-basic-offset:4; tab-width:4 -*-
 ****************************************************************************
 * (C) 2003 - Rolf Neugebauer - Intel Research Cambridge
 ****************************************************************************
 *
 *        File: lib.h
 *      Author: Rolf Neugebauer (neugebar@dcs.gla.ac.uk)
 *     Changes: 
 *              
 *        Date: Aug 2003
 * 
 * Environment: Xen Minimal OS
 * Description: Random useful library functions, contains some freebsd stuff
 *
 ****************************************************************************
 * $Id: h-insert.h,v 1.4 2002/11/08 16:03:55 rn Exp $
 ****************************************************************************
 *
 *-
 * Copyright (c) 1991, 1993
 *      The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *      This product includes software developed by the University of
 *      California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *      @(#)stdarg.h    8.1 (Berkeley) 6/10/93
 * $FreeBSD: src/sys/i386/include/stdarg.h,v 1.10 1999/08/28 00:44:26 peter Exp $
 */

#ifndef _LIB_H_
#define _LIB_H_

#include <stdarg.h>
#include <stddef.h>
#include <xen/xen.h>
#include <xen/event_channel.h>
#include "gntmap.h"

#ifdef HAVE_LIBC
#include <stdio.h>
#else
/* printing */
#define _p(_x) ((void *)(unsigned long)(_x))
int vsnprintf(char *buf, size_t size, const char *fmt, va_list args);
int vscnprintf(char *buf, size_t size, const char *fmt, va_list args);
int snprintf(char * buf, size_t size, const char *fmt, ...);
int scnprintf(char * buf, size_t size, const char *fmt, ...);
int vsprintf(char *buf, const char *fmt, va_list args);
int sprintf(char * buf, const char *fmt, ...);
int vsscanf(const char * buf, const char * fmt, va_list args);
int sscanf(const char * buf, const char * fmt, ...);
#endif

long simple_strtol(const char *cp,char **endp,unsigned int base);
unsigned long simple_strtoul(const char *cp,char **endp,unsigned int base);
long long simple_strtoll(const char *cp,char **endp,unsigned int base);
unsigned long long simple_strtoull(const char *cp,char **endp,unsigned int base);

#ifdef HAVE_LIBC
#include <string.h>
#else
/* string and memory manipulation */
int    memcmp(const void *cs, const void *ct, size_t count);
void  *memcpy(void *dest, const void *src, size_t count);
int    strncmp(const char *cs, const char *ct, size_t count);
int    strcmp(const char *cs, const char *ct);
char  *strcpy(char *dest, const char *src);
char  *strncpy(char *dest, const char *src, size_t count);
void  *memset(void *s,int c, size_t count);
size_t strnlen(const char *s, size_t count);
size_t strlen(const char *s);
char  *strchr(const char *s, int c);
char  *strrchr(const char *s, int c);
char  *strstr(const char *s1, const char *s2);
char * strcat(char * dest, const char * src);
char  *strdup(const char *s);
#endif
#include <mini-os/console.h>

#define RAND_MIX 2654435769U

int rand(void);

#include <mini-os/xenbus.h>

#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))

struct kvec {
    void *iov_base;
    size_t iov_len;
};

#define ASSERT(x)                                              \
do {                                                           \
	if (!(x)) {                                                \
		printk("ASSERTION FAILED: %s at %s:%d.\n",             \
			   # x ,                                           \
			   __FILE__,                                       \
			   __LINE__);                                      \
        BUG();                                                 \
	}                                                          \
} while(0)

#define BUG_ON(x) ASSERT(!(x))

/* Consistency check as much as possible. */
void sanity_check(void);

#ifdef HAVE_LIBC
enum fd_type {
    FTYPE_NONE = 0,
    FTYPE_CONSOLE,
    FTYPE_FILE,
    FTYPE_XENBUS,
    FTYPE_XC,
    FTYPE_EVTCHN,
    FTYPE_GNTMAP,
    FTYPE_SOCKET,
    FTYPE_TAP,
    FTYPE_BLK,
    FTYPE_KBD,
    FTYPE_FB,
    FTYPE_MEM,
};

#define MAX_EVTCHN_PORTS 16

extern struct file {
    enum fd_type type;
    union {
	struct {
            /* lwIP fd */
	    int fd;
	} socket;
	struct {
            /* FS import fd */
	    int fd;
	    off_t offset;
	} file;
	struct {
            /* To each event channel FD is associated a series of ports which
             * wakes select for this FD. */
            struct {
                evtchn_port_t port;
                unsigned long pending;
                int bound;
            } ports[MAX_EVTCHN_PORTS];
	} evtchn;
	struct gntmap gntmap;
	struct {
	    struct netfront_dev *dev;
	} tap;
	struct {
	    struct blkfront_dev *dev;
	} blk;
	struct {
	    struct kbdfront_dev *dev;
	} kbd;
	struct {
	    struct fbfront_dev *dev;
	} fb;
	struct {
	    struct consfront_dev *dev;
	} cons;
        struct {
            /* To each xenbus FD is associated a queue of watch events for this
             * FD.  */
            xenbus_event_queue events;
        } xenbus;
    };
    int read;	/* maybe available for read */
} files[];

int alloc_fd(enum fd_type type);
void close_all_files(void);
extern struct thread *main_thread;
void sparse(unsigned long data, size_t size);
#endif

#endif /* _LIB_H_ */
