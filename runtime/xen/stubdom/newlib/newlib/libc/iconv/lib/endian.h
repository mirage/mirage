/*
 * Copyright (c) 2003-2004, Artem B. Bityuckiy
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
#ifndef __ICONV_CES_ENDIAN_H__
#define __ICONV_CES_ENDIAN_H__

#include <sys/param.h>

#if (BYTE_ORDER == LITTLE_ENDIAN)

#  define ICONV_BETOHS(s) \
     ((((s) << 8) & 0xFF00) | (((s) >> 8) & 0x00FF))

#  define ICONV_BETOHL(l) \
     ((((l) << 24) & 0xFF000000) | \
      (((l) <<  8) & 0x00FF0000) | \
      (((l) >>  8) & 0x0000FF00) | \
      (((l) >> 24) & 0x000000FF))

#  define ICONV_LETOHS(s) (s)
#  define ICONV_LETOHL(l) (l)

#  define ICONV_HTOLES(s) ICONV_LETOHS (s)
#  define ICONV_HTOLEL(l) ICONV_LETOHL (l)
#  define ICONV_HTOBES(s) ICONV_BETOHS (s)
#  define ICONV_HTOBEL(l) ICONV_BETOHL (l)

#elif (BYTE_ORDER == BIG_ENDIAN)

#  define ICONV_BETOHS(s) (s)
#  define ICONV_BETOHL(l) (l)
  
#  define ICONV_LETOHS(s) \
     ((((s) << 8) & 0xFF00) | (((s) >> 8) & 0x00FF))

#  define ICONV_LETOHL(l) \
     ((((l) << 24) & 0xFF000000) | \
      (((l) <<  8) & 0x00FF0000) | \
      (((l) >>  8) & 0x0000FF00) | \
      (((l) >> 24) & 0x000000FF))

#  define ICONV_HTOBES(s) ICONV_BETOHS (s)
#  define ICONV_HTOBEL(l) ICONV_BETOHL (l)
#  define ICONV_HTOLES(s) ICONV_LETOHS (s)
#  define ICONV_HTOLEL(l) ICONV_LETOHL (l)

#else
#  error "Unknown byte order."
#endif

#endif /* !__ICONV_CES_ENDIAN_H__ */

