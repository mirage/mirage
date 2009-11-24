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
#ifndef __ICONV_LIB_LOCAL_H__
#define __ICONV_LIB_LOCAL_H__

#include <_ansi.h>
#include <reent.h>
#include <sys/types.h>
#include <limits.h>

/* void* type for K&R compilers compatibility */
#define _VOID_PTR _PTR

/* Encodings aliases file */
#define ICONV_ALIASES_FNAME   "encoding.aliases"
/* iconv CCS data path */
#define ICONV_SUBDIR          "iconv_data"
/* iconv data files extension */
#define ICONV_DATA_EXT        ".cct"

/* This macro is used to zero mbstate_t objects */
#define ICONV_ZERO_MB_STATE_T ((mbstate_t){0, {0}})

/* Define the maximum multi-byte character length produced by iconv library */
#if MB_LEN_MAX < 6
#  define ICONV_MB_LEN_MAX 6
#else
#  define ICONV_MB_LEN_MAX MB_LEN_MAX
#endif

/* 16-bit UCS-2 type */
typedef __uint16_t ucs2_t;

/* 32-bit UCS-4 type */
typedef __uint32_t ucs4_t;


/* The list of built-in encoding names and aliases */
extern _CONST char *
_iconv_aliases;

#endif /* !__ICONV_LIB_LOCAL_H__ */

