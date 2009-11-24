/* Copyright (C) 2002 by  Red Hat, Incorporated. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

#include <sys/types.h>

/* Find string str in buffer buf of length buf_len.  Point buf to
   character after string, or set it to NULL if end of buffer is
   reached.  Return 1 if found, 0 if not. */
int _buf_findstr(const char *str, char **buf, size_t *buf_len);
