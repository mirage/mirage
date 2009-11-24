/*
 * This file was automatically generated mkdeps.pl script. Don't edit.
 */

#ifndef __CCSBI_H__
#define __CCSBI_H__

#include <newlib.h>
#include <_ansi.h>
#include "ccs.h"

/*
 * Enable CCS tables if encoding needs them.
 * Defining ICONV_TO_UCS_CCS_XXX macro or ICONV_FROM_UCS_CCS_XXX
 * macro is needed to enable "XXX encoding -> UCS" or "UCS -> XXX encoding"
 * part of CCS table.
 * CCS tables aren't linked if Newlib was configuted to use external CCS tables.
 */
#ifndef _ICONV_ENABLE_EXTERNAL_CCS

#if defined (_ICONV_FROM_ENCODING_BIG5)
#  define ICONV_TO_UCS_CCS_BIG5
#endif
#if defined (_ICONV_TO_ENCODING_BIG5)
#  define ICONV_FROM_UCS_CCS_BIG5
#endif

#if defined (_ICONV_FROM_ENCODING_EUC_TW)
#  define ICONV_TO_UCS_CCS_CNS11643_PLANE1
#endif
#if defined (_ICONV_TO_ENCODING_EUC_TW)
#  define ICONV_FROM_UCS_CCS_CNS11643_PLANE1
#endif

#if defined (_ICONV_FROM_ENCODING_EUC_TW)
#  define ICONV_TO_UCS_CCS_CNS11643_PLANE14
#endif
#if defined (_ICONV_TO_ENCODING_EUC_TW)
#  define ICONV_FROM_UCS_CCS_CNS11643_PLANE14
#endif

#if defined (_ICONV_FROM_ENCODING_EUC_TW)
#  define ICONV_TO_UCS_CCS_CNS11643_PLANE2
#endif
#if defined (_ICONV_TO_ENCODING_EUC_TW)
#  define ICONV_FROM_UCS_CCS_CNS11643_PLANE2
#endif

#if defined (_ICONV_FROM_ENCODING_CP775)
#  define ICONV_TO_UCS_CCS_CP775
#endif
#if defined (_ICONV_TO_ENCODING_CP775)
#  define ICONV_FROM_UCS_CCS_CP775
#endif

#if defined (_ICONV_FROM_ENCODING_CP850)
#  define ICONV_TO_UCS_CCS_CP850
#endif
#if defined (_ICONV_TO_ENCODING_CP850)
#  define ICONV_FROM_UCS_CCS_CP850
#endif

#if defined (_ICONV_FROM_ENCODING_CP852)
#  define ICONV_TO_UCS_CCS_CP852
#endif
#if defined (_ICONV_TO_ENCODING_CP852)
#  define ICONV_FROM_UCS_CCS_CP852
#endif

#if defined (_ICONV_FROM_ENCODING_CP855)
#  define ICONV_TO_UCS_CCS_CP855
#endif
#if defined (_ICONV_TO_ENCODING_CP855)
#  define ICONV_FROM_UCS_CCS_CP855
#endif

#if defined (_ICONV_FROM_ENCODING_CP866)
#  define ICONV_TO_UCS_CCS_CP866
#endif
#if defined (_ICONV_TO_ENCODING_CP866)
#  define ICONV_FROM_UCS_CCS_CP866
#endif

#if defined (_ICONV_FROM_ENCODING_ISO_8859_1)
#  define ICONV_TO_UCS_CCS_ISO_8859_1
#endif
#if defined (_ICONV_TO_ENCODING_ISO_8859_1)
#  define ICONV_FROM_UCS_CCS_ISO_8859_1
#endif

#if defined (_ICONV_FROM_ENCODING_ISO_8859_10)
#  define ICONV_TO_UCS_CCS_ISO_8859_10
#endif
#if defined (_ICONV_TO_ENCODING_ISO_8859_10)
#  define ICONV_FROM_UCS_CCS_ISO_8859_10
#endif

#if defined (_ICONV_FROM_ENCODING_ISO_8859_11)
#  define ICONV_TO_UCS_CCS_ISO_8859_11
#endif
#if defined (_ICONV_TO_ENCODING_ISO_8859_11)
#  define ICONV_FROM_UCS_CCS_ISO_8859_11
#endif

#if defined (_ICONV_FROM_ENCODING_ISO_8859_13)
#  define ICONV_TO_UCS_CCS_ISO_8859_13
#endif
#if defined (_ICONV_TO_ENCODING_ISO_8859_13)
#  define ICONV_FROM_UCS_CCS_ISO_8859_13
#endif

#if defined (_ICONV_FROM_ENCODING_ISO_8859_14)
#  define ICONV_TO_UCS_CCS_ISO_8859_14
#endif
#if defined (_ICONV_TO_ENCODING_ISO_8859_14)
#  define ICONV_FROM_UCS_CCS_ISO_8859_14
#endif

#if defined (_ICONV_FROM_ENCODING_ISO_8859_15)
#  define ICONV_TO_UCS_CCS_ISO_8859_15
#endif
#if defined (_ICONV_TO_ENCODING_ISO_8859_15)
#  define ICONV_FROM_UCS_CCS_ISO_8859_15
#endif

#if defined (_ICONV_FROM_ENCODING_ISO_8859_2)
#  define ICONV_TO_UCS_CCS_ISO_8859_2
#endif
#if defined (_ICONV_TO_ENCODING_ISO_8859_2)
#  define ICONV_FROM_UCS_CCS_ISO_8859_2
#endif

#if defined (_ICONV_FROM_ENCODING_ISO_8859_3)
#  define ICONV_TO_UCS_CCS_ISO_8859_3
#endif
#if defined (_ICONV_TO_ENCODING_ISO_8859_3)
#  define ICONV_FROM_UCS_CCS_ISO_8859_3
#endif

#if defined (_ICONV_FROM_ENCODING_ISO_8859_4)
#  define ICONV_TO_UCS_CCS_ISO_8859_4
#endif
#if defined (_ICONV_TO_ENCODING_ISO_8859_4)
#  define ICONV_FROM_UCS_CCS_ISO_8859_4
#endif

#if defined (_ICONV_FROM_ENCODING_ISO_8859_5)
#  define ICONV_TO_UCS_CCS_ISO_8859_5
#endif
#if defined (_ICONV_TO_ENCODING_ISO_8859_5)
#  define ICONV_FROM_UCS_CCS_ISO_8859_5
#endif

#if defined (_ICONV_FROM_ENCODING_ISO_8859_6)
#  define ICONV_TO_UCS_CCS_ISO_8859_6
#endif
#if defined (_ICONV_TO_ENCODING_ISO_8859_6)
#  define ICONV_FROM_UCS_CCS_ISO_8859_6
#endif

#if defined (_ICONV_FROM_ENCODING_ISO_8859_7)
#  define ICONV_TO_UCS_CCS_ISO_8859_7
#endif
#if defined (_ICONV_TO_ENCODING_ISO_8859_7)
#  define ICONV_FROM_UCS_CCS_ISO_8859_7
#endif

#if defined (_ICONV_FROM_ENCODING_ISO_8859_8)
#  define ICONV_TO_UCS_CCS_ISO_8859_8
#endif
#if defined (_ICONV_TO_ENCODING_ISO_8859_8)
#  define ICONV_FROM_UCS_CCS_ISO_8859_8
#endif

#if defined (_ICONV_FROM_ENCODING_ISO_8859_9)
#  define ICONV_TO_UCS_CCS_ISO_8859_9
#endif
#if defined (_ICONV_TO_ENCODING_ISO_8859_9)
#  define ICONV_FROM_UCS_CCS_ISO_8859_9
#endif

#if defined (_ICONV_FROM_ENCODING_ISO_IR_111)
#  define ICONV_TO_UCS_CCS_ISO_IR_111
#endif
#if defined (_ICONV_TO_ENCODING_ISO_IR_111)
#  define ICONV_FROM_UCS_CCS_ISO_IR_111
#endif

#if defined (_ICONV_FROM_ENCODING_EUC_JP)
#  define ICONV_TO_UCS_CCS_JIS_X0201_1976
#endif
#if defined (_ICONV_TO_ENCODING_EUC_JP)
#  define ICONV_FROM_UCS_CCS_JIS_X0201_1976
#endif

#if defined (_ICONV_FROM_ENCODING_EUC_JP)
#  define ICONV_TO_UCS_CCS_JIS_X0208_1990
#endif
#if defined (_ICONV_TO_ENCODING_EUC_JP)
#  define ICONV_FROM_UCS_CCS_JIS_X0208_1990
#endif

#if defined (_ICONV_FROM_ENCODING_EUC_JP)
#  define ICONV_TO_UCS_CCS_JIS_X0212_1990
#endif
#if defined (_ICONV_TO_ENCODING_EUC_JP)
#  define ICONV_FROM_UCS_CCS_JIS_X0212_1990
#endif

#if defined (_ICONV_FROM_ENCODING_KOI8_R)
#  define ICONV_TO_UCS_CCS_KOI8_R
#endif
#if defined (_ICONV_TO_ENCODING_KOI8_R)
#  define ICONV_FROM_UCS_CCS_KOI8_R
#endif

#if defined (_ICONV_FROM_ENCODING_KOI8_RU)
#  define ICONV_TO_UCS_CCS_KOI8_RU
#endif
#if defined (_ICONV_TO_ENCODING_KOI8_RU)
#  define ICONV_FROM_UCS_CCS_KOI8_RU
#endif

#if defined (_ICONV_FROM_ENCODING_KOI8_U)
#  define ICONV_TO_UCS_CCS_KOI8_U
#endif
#if defined (_ICONV_TO_ENCODING_KOI8_U)
#  define ICONV_FROM_UCS_CCS_KOI8_U
#endif

#if defined (_ICONV_FROM_ENCODING_KOI8_UNI)
#  define ICONV_TO_UCS_CCS_KOI8_UNI
#endif
#if defined (_ICONV_TO_ENCODING_KOI8_UNI)
#  define ICONV_FROM_UCS_CCS_KOI8_UNI
#endif

#if defined (_ICONV_FROM_ENCODING_EUC_KR)
#  define ICONV_TO_UCS_CCS_KSX1001
#endif
#if defined (_ICONV_TO_ENCODING_EUC_KR)
#  define ICONV_FROM_UCS_CCS_KSX1001
#endif

#if defined (_ICONV_FROM_ENCODING_WIN_1250)
#  define ICONV_TO_UCS_CCS_WIN_1250
#endif
#if defined (_ICONV_TO_ENCODING_WIN_1250)
#  define ICONV_FROM_UCS_CCS_WIN_1250
#endif

#if defined (_ICONV_FROM_ENCODING_WIN_1251)
#  define ICONV_TO_UCS_CCS_WIN_1251
#endif
#if defined (_ICONV_TO_ENCODING_WIN_1251)
#  define ICONV_FROM_UCS_CCS_WIN_1251
#endif

#if defined (_ICONV_FROM_ENCODING_WIN_1252)
#  define ICONV_TO_UCS_CCS_WIN_1252
#endif
#if defined (_ICONV_TO_ENCODING_WIN_1252)
#  define ICONV_FROM_UCS_CCS_WIN_1252
#endif

#if defined (_ICONV_FROM_ENCODING_WIN_1253)
#  define ICONV_TO_UCS_CCS_WIN_1253
#endif
#if defined (_ICONV_TO_ENCODING_WIN_1253)
#  define ICONV_FROM_UCS_CCS_WIN_1253
#endif

#if defined (_ICONV_FROM_ENCODING_WIN_1254)
#  define ICONV_TO_UCS_CCS_WIN_1254
#endif
#if defined (_ICONV_TO_ENCODING_WIN_1254)
#  define ICONV_FROM_UCS_CCS_WIN_1254
#endif

#if defined (_ICONV_FROM_ENCODING_WIN_1255)
#  define ICONV_TO_UCS_CCS_WIN_1255
#endif
#if defined (_ICONV_TO_ENCODING_WIN_1255)
#  define ICONV_FROM_UCS_CCS_WIN_1255
#endif

#if defined (_ICONV_FROM_ENCODING_WIN_1256)
#  define ICONV_TO_UCS_CCS_WIN_1256
#endif
#if defined (_ICONV_TO_ENCODING_WIN_1256)
#  define ICONV_FROM_UCS_CCS_WIN_1256
#endif

#if defined (_ICONV_FROM_ENCODING_WIN_1257)
#  define ICONV_TO_UCS_CCS_WIN_1257
#endif
#if defined (_ICONV_TO_ENCODING_WIN_1257)
#  define ICONV_FROM_UCS_CCS_WIN_1257
#endif

#if defined (_ICONV_FROM_ENCODING_WIN_1258)
#  define ICONV_TO_UCS_CCS_WIN_1258
#endif
#if defined (_ICONV_TO_ENCODING_WIN_1258)
#  define ICONV_FROM_UCS_CCS_WIN_1258
#endif

/*
 * CCS table description structures forward declarations.
 */
#if defined (ICONV_TO_UCS_CCS_BIG5) \
 || defined (ICONV_FROM_UCS_CCS_BIG5)
extern _CONST iconv_ccs_t
_iconv_ccs_big5;
#endif
#if defined (ICONV_TO_UCS_CCS_CNS11643_PLANE1) \
 || defined (ICONV_FROM_UCS_CCS_CNS11643_PLANE1)
extern _CONST iconv_ccs_t
_iconv_ccs_cns11643_plane1;
#endif
#if defined (ICONV_TO_UCS_CCS_CNS11643_PLANE14) \
 || defined (ICONV_FROM_UCS_CCS_CNS11643_PLANE14)
extern _CONST iconv_ccs_t
_iconv_ccs_cns11643_plane14;
#endif
#if defined (ICONV_TO_UCS_CCS_CNS11643_PLANE2) \
 || defined (ICONV_FROM_UCS_CCS_CNS11643_PLANE2)
extern _CONST iconv_ccs_t
_iconv_ccs_cns11643_plane2;
#endif
#if defined (ICONV_TO_UCS_CCS_CP775) \
 || defined (ICONV_FROM_UCS_CCS_CP775)
extern _CONST iconv_ccs_t
_iconv_ccs_cp775;
#endif
#if defined (ICONV_TO_UCS_CCS_CP850) \
 || defined (ICONV_FROM_UCS_CCS_CP850)
extern _CONST iconv_ccs_t
_iconv_ccs_cp850;
#endif
#if defined (ICONV_TO_UCS_CCS_CP852) \
 || defined (ICONV_FROM_UCS_CCS_CP852)
extern _CONST iconv_ccs_t
_iconv_ccs_cp852;
#endif
#if defined (ICONV_TO_UCS_CCS_CP855) \
 || defined (ICONV_FROM_UCS_CCS_CP855)
extern _CONST iconv_ccs_t
_iconv_ccs_cp855;
#endif
#if defined (ICONV_TO_UCS_CCS_CP866) \
 || defined (ICONV_FROM_UCS_CCS_CP866)
extern _CONST iconv_ccs_t
_iconv_ccs_cp866;
#endif
#if defined (ICONV_TO_UCS_CCS_ISO_8859_1) \
 || defined (ICONV_FROM_UCS_CCS_ISO_8859_1)
extern _CONST iconv_ccs_t
_iconv_ccs_iso_8859_1;
#endif
#if defined (ICONV_TO_UCS_CCS_ISO_8859_10) \
 || defined (ICONV_FROM_UCS_CCS_ISO_8859_10)
extern _CONST iconv_ccs_t
_iconv_ccs_iso_8859_10;
#endif
#if defined (ICONV_TO_UCS_CCS_ISO_8859_11) \
 || defined (ICONV_FROM_UCS_CCS_ISO_8859_11)
extern _CONST iconv_ccs_t
_iconv_ccs_iso_8859_11;
#endif
#if defined (ICONV_TO_UCS_CCS_ISO_8859_13) \
 || defined (ICONV_FROM_UCS_CCS_ISO_8859_13)
extern _CONST iconv_ccs_t
_iconv_ccs_iso_8859_13;
#endif
#if defined (ICONV_TO_UCS_CCS_ISO_8859_14) \
 || defined (ICONV_FROM_UCS_CCS_ISO_8859_14)
extern _CONST iconv_ccs_t
_iconv_ccs_iso_8859_14;
#endif
#if defined (ICONV_TO_UCS_CCS_ISO_8859_15) \
 || defined (ICONV_FROM_UCS_CCS_ISO_8859_15)
extern _CONST iconv_ccs_t
_iconv_ccs_iso_8859_15;
#endif
#if defined (ICONV_TO_UCS_CCS_ISO_8859_2) \
 || defined (ICONV_FROM_UCS_CCS_ISO_8859_2)
extern _CONST iconv_ccs_t
_iconv_ccs_iso_8859_2;
#endif
#if defined (ICONV_TO_UCS_CCS_ISO_8859_3) \
 || defined (ICONV_FROM_UCS_CCS_ISO_8859_3)
extern _CONST iconv_ccs_t
_iconv_ccs_iso_8859_3;
#endif
#if defined (ICONV_TO_UCS_CCS_ISO_8859_4) \
 || defined (ICONV_FROM_UCS_CCS_ISO_8859_4)
extern _CONST iconv_ccs_t
_iconv_ccs_iso_8859_4;
#endif
#if defined (ICONV_TO_UCS_CCS_ISO_8859_5) \
 || defined (ICONV_FROM_UCS_CCS_ISO_8859_5)
extern _CONST iconv_ccs_t
_iconv_ccs_iso_8859_5;
#endif
#if defined (ICONV_TO_UCS_CCS_ISO_8859_6) \
 || defined (ICONV_FROM_UCS_CCS_ISO_8859_6)
extern _CONST iconv_ccs_t
_iconv_ccs_iso_8859_6;
#endif
#if defined (ICONV_TO_UCS_CCS_ISO_8859_7) \
 || defined (ICONV_FROM_UCS_CCS_ISO_8859_7)
extern _CONST iconv_ccs_t
_iconv_ccs_iso_8859_7;
#endif
#if defined (ICONV_TO_UCS_CCS_ISO_8859_8) \
 || defined (ICONV_FROM_UCS_CCS_ISO_8859_8)
extern _CONST iconv_ccs_t
_iconv_ccs_iso_8859_8;
#endif
#if defined (ICONV_TO_UCS_CCS_ISO_8859_9) \
 || defined (ICONV_FROM_UCS_CCS_ISO_8859_9)
extern _CONST iconv_ccs_t
_iconv_ccs_iso_8859_9;
#endif
#if defined (ICONV_TO_UCS_CCS_ISO_IR_111) \
 || defined (ICONV_FROM_UCS_CCS_ISO_IR_111)
extern _CONST iconv_ccs_t
_iconv_ccs_iso_ir_111;
#endif
#if defined (ICONV_TO_UCS_CCS_JIS_X0201_1976) \
 || defined (ICONV_FROM_UCS_CCS_JIS_X0201_1976)
extern _CONST iconv_ccs_t
_iconv_ccs_jis_x0201_1976;
#endif
#if defined (ICONV_TO_UCS_CCS_JIS_X0208_1990) \
 || defined (ICONV_FROM_UCS_CCS_JIS_X0208_1990)
extern _CONST iconv_ccs_t
_iconv_ccs_jis_x0208_1990;
#endif
#if defined (ICONV_TO_UCS_CCS_JIS_X0212_1990) \
 || defined (ICONV_FROM_UCS_CCS_JIS_X0212_1990)
extern _CONST iconv_ccs_t
_iconv_ccs_jis_x0212_1990;
#endif
#if defined (ICONV_TO_UCS_CCS_KOI8_R) \
 || defined (ICONV_FROM_UCS_CCS_KOI8_R)
extern _CONST iconv_ccs_t
_iconv_ccs_koi8_r;
#endif
#if defined (ICONV_TO_UCS_CCS_KOI8_RU) \
 || defined (ICONV_FROM_UCS_CCS_KOI8_RU)
extern _CONST iconv_ccs_t
_iconv_ccs_koi8_ru;
#endif
#if defined (ICONV_TO_UCS_CCS_KOI8_U) \
 || defined (ICONV_FROM_UCS_CCS_KOI8_U)
extern _CONST iconv_ccs_t
_iconv_ccs_koi8_u;
#endif
#if defined (ICONV_TO_UCS_CCS_KOI8_UNI) \
 || defined (ICONV_FROM_UCS_CCS_KOI8_UNI)
extern _CONST iconv_ccs_t
_iconv_ccs_koi8_uni;
#endif
#if defined (ICONV_TO_UCS_CCS_KSX1001) \
 || defined (ICONV_FROM_UCS_CCS_KSX1001)
extern _CONST iconv_ccs_t
_iconv_ccs_ksx1001;
#endif
#if defined (ICONV_TO_UCS_CCS_WIN_1250) \
 || defined (ICONV_FROM_UCS_CCS_WIN_1250)
extern _CONST iconv_ccs_t
_iconv_ccs_win_1250;
#endif
#if defined (ICONV_TO_UCS_CCS_WIN_1251) \
 || defined (ICONV_FROM_UCS_CCS_WIN_1251)
extern _CONST iconv_ccs_t
_iconv_ccs_win_1251;
#endif
#if defined (ICONV_TO_UCS_CCS_WIN_1252) \
 || defined (ICONV_FROM_UCS_CCS_WIN_1252)
extern _CONST iconv_ccs_t
_iconv_ccs_win_1252;
#endif
#if defined (ICONV_TO_UCS_CCS_WIN_1253) \
 || defined (ICONV_FROM_UCS_CCS_WIN_1253)
extern _CONST iconv_ccs_t
_iconv_ccs_win_1253;
#endif
#if defined (ICONV_TO_UCS_CCS_WIN_1254) \
 || defined (ICONV_FROM_UCS_CCS_WIN_1254)
extern _CONST iconv_ccs_t
_iconv_ccs_win_1254;
#endif
#if defined (ICONV_TO_UCS_CCS_WIN_1255) \
 || defined (ICONV_FROM_UCS_CCS_WIN_1255)
extern _CONST iconv_ccs_t
_iconv_ccs_win_1255;
#endif
#if defined (ICONV_TO_UCS_CCS_WIN_1256) \
 || defined (ICONV_FROM_UCS_CCS_WIN_1256)
extern _CONST iconv_ccs_t
_iconv_ccs_win_1256;
#endif
#if defined (ICONV_TO_UCS_CCS_WIN_1257) \
 || defined (ICONV_FROM_UCS_CCS_WIN_1257)
extern _CONST iconv_ccs_t
_iconv_ccs_win_1257;
#endif
#if defined (ICONV_TO_UCS_CCS_WIN_1258) \
 || defined (ICONV_FROM_UCS_CCS_WIN_1258)
extern _CONST iconv_ccs_t
_iconv_ccs_win_1258;
#endif

#endif /* !_ICONV_ENABLE_EXTERNAL_CCS */


#endif /* __CCSBI_H__ */

