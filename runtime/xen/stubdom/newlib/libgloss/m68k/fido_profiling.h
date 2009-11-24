/*
 * fido profiling support.
 *
 * Copyright (c) 2006 CodeSourcery Inc
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

#ifndef FIDO_PROFILING_H
#define FIDO_PROFILING_H

extern int monconfig (unsigned char *buffer, unsigned buffer_size);
extern int moncontrol (int);
extern void _mcleanup (void);

#endif
