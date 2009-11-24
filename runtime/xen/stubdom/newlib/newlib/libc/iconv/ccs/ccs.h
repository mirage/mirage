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
#ifndef __CCS_H__
#define __CCS_H__

#include <_ansi.h>
#include <sys/types.h>
#include <sys/param.h>

/*
 * Size-optimized tables will be linked instead of speed-optimized if
 * TABLE_USE_SIZE_OPTIMISATION macro is defined.
 */
#if defined (PREFER_SIZE_OVER_SPEED) || defined (__OPTIMIZE_SIZE__)
#  define TABLE_USE_SIZE_OPTIMIZATION
#endif

/* Invalid code marker */
#define INVALC  0xFFFF
/* Invalid block marker - marks empty blocks in speed-optimized tables */
#define INVBLK  0xFFFF
/* Lost code marker - marks codes that was lost during CCS->UCS mapping */
#define LOST_C DEFAULT_CHARACTER

/*
 * Table parameters values.
 */
/* Table version 1.0 identifier */
#define TABLE_VERSION_1 1
/* 8 and 16 bit tables identifiers */
#define TABLE_8BIT  8
#define TABLE_16BIT 16
/* Size-optimized and speed-optimized tables identifiers */
#define TABLE_SIZE_OPTIMIZED  1
#define TABLE_SPEED_OPTIMIZED 2
/* Built-in/external tables identifiers */
#define TABLE_BUILTIN  1
#define TABLE_EXTERNAL 2

/*
 * Binary table fields.
 */
/* "No table" marker */
#define EXTTABLE_NO_TABLE 0
/* Version offset (2 bytes) */
#define EXTTABLE_VERSION_OFF 0
/* Bits number offset (2 bytes) */
#define EXTTABLE_BITS_OFF 2
/* CCS name length offset (2 bytes) */
#define EXTTABLE_CCSNAME_LEN_OFF 4
/* CCS name offset (expanded to even bytes number)*/
#define EXTTABLE_CCSNAME_OFF 8
/* Header length (minus CCS name) */
#define EXTTABLE_HEADER_LEN (EXTTABLE_CCSNAME_OFF + 16*4)
/* Tables and lengths offsets minus CCS name length (4 bytes) */
#define EXTTABLE_FROM_SPEED_BE_OFF     (EXTTABLE_CCSNAME_OFF + 0)
#define EXTTABLE_FROM_SPEED_BE_LEN_OFF (EXTTABLE_CCSNAME_OFF + 4)
#define EXTTABLE_FROM_SPEED_LE_OFF     (EXTTABLE_CCSNAME_OFF + 8)
#define EXTTABLE_FROM_SPEED_LE_LEN_OFF (EXTTABLE_CCSNAME_OFF + 12)
#define EXTTABLE_FROM_SIZE_BE_OFF      (EXTTABLE_CCSNAME_OFF + 16)
#define EXTTABLE_FROM_SIZE_BE_LEN_OFF  (EXTTABLE_CCSNAME_OFF + 20)
#define EXTTABLE_FROM_SIZE_LE_OFF      (EXTTABLE_CCSNAME_OFF + 24)
#define EXTTABLE_FROM_SIZE_LE_LEN_OFF  (EXTTABLE_CCSNAME_OFF + 28)
#define EXTTABLE_TO_SPEED_BE_OFF       (EXTTABLE_CCSNAME_OFF + 32)
#define EXTTABLE_TO_SPEED_BE_LEN_OFF   (EXTTABLE_CCSNAME_OFF + 36)
#define EXTTABLE_TO_SPEED_LE_OFF       (EXTTABLE_CCSNAME_OFF + 40)
#define EXTTABLE_TO_SPEED_LE_LEN_OFF   (EXTTABLE_CCSNAME_OFF + 44)
#define EXTTABLE_TO_SIZE_BE_OFF        (EXTTABLE_CCSNAME_OFF + 48)
#define EXTTABLE_TO_SIZE_BE_LEN_OFF    (EXTTABLE_CCSNAME_OFF + 52)
#define EXTTABLE_TO_SIZE_LE_OFF        (EXTTABLE_CCSNAME_OFF + 56)
#define EXTTABLE_TO_SIZE_LE_LEN_OFF    (EXTTABLE_CCSNAME_OFF + 60)
/* Endian-independent offsets */
#if (BYTE_ORDER == LITTLE_ENDIAN)
#  define EXTTABLE_FROM_SPEED_OFF     EXTTABLE_FROM_SPEED_LE_OFF
#  define EXTTABLE_FROM_SIZE_OFF      EXTTABLE_FROM_SIZE_LE_OFF
#  define EXTTABLE_TO_SPEED_OFF       EXTTABLE_TO_SPEED_LE_OFF
#  define EXTTABLE_TO_SIZE_OFF        EXTTABLE_TO_SIZE_LE_OFF
#  define EXTTABLE_FROM_SPEED_LEN_OFF EXTTABLE_FROM_SPEED_LE_LEN_OFF
#  define EXTTABLE_FROM_SIZE_LEN_OFF  EXTTABLE_FROM_SIZE_LE_LEN_OFF
#  define EXTTABLE_TO_SPEED_LEN_OFF   EXTTABLE_TO_SPEED_LE_LEN_OFF
#  define EXTTABLE_TO_SIZE_LEN_OFF    EXTTABLE_TO_SIZE_LE_LEN_OFF
#elif (BYTE_ORDER == BIG_ENDIAN)
#  define EXTTABLE_FROM_SPEED_OFF     EXTTABLE_FROM_SPEED_BE_OFF
#  define EXTTABLE_FROM_SIZE_OFF      EXTTABLE_FROM_SIZE_BE_OFF
#  define EXTTABLE_TO_SPEED_OFF       EXTTABLE_TO_SPEED_BE_OFF
#  define EXTTABLE_TO_SIZE_OFF        EXTTABLE_TO_SIZE_BE_OFF
#  define EXTTABLE_FROM_SPEED_LEN_OFF EXTTABLE_FROM_SPEED_BE_LEN_OFF
#  define EXTTABLE_FROM_SIZE_LEN_OFF  EXTTABLE_FROM_SIZE_BE_LEN_OFF
#  define EXTTABLE_TO_SPEED_LEN_OFF   EXTTABLE_TO_SPEED_BE_LEN_OFF
#  define EXTTABLE_TO_SIZE_LEN_OFF    EXTTABLE_TO_SIZE_BE_LEN_OFF
#endif

/*
 * Size-optimized suitable fields indexes.
 */
/* Ranges number array index */
#define RANGES_NUM_INDEX    0
/* Un-ranged codes number array index */
#define UNRANGED_NUM_INDEX  1
/* First un-ranged pair index array index */
#define FIRST_UNRANGED_INDEX_INDEX 2
/* First range array index */
#define FIRST_RANGE_INDEX   3


/*
 * Builtin CCS table description structure.
 */
typedef struct
{
  __uint16_t ver;               /* Table version */
  _CONST char *name;            /* CCS name */
  __uint16_t bits;              /* CCS's bits number */
  int from_ucs_type;            /* UCS -> CCS table optimization type */
  _CONST __uint16_t *from_ucs;  /* UCS -> CCS table */
  int to_ucs_type;              /* CCS -> UCS table optimization type */
  _CONST __uint16_t *to_ucs;    /* CCS -> UCS table */
} iconv_ccs_t;

/*
 * CCS table descriptor.
 */
typedef struct
{
  int bits;               /* CCS's bits number */
  int type;               /* Table type (builtin/external) */
  int optimization;       /* Table optimization type (speed/size) */ 
  _CONST __uint16_t *tbl; /* Table's data */
} iconv_ccs_desc_t;

/* Array containing all built-in CCS tables */
extern _CONST iconv_ccs_t *
_iconv_ccs[];

#endif /* __CCS_H__ */

