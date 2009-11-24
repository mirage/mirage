/*
 * This file was automatically generated mkdeps.pl script. Don't edit.
 */

#ifndef __CESBI_H__
#define __CESBI_H__

#include <newlib.h>
#include <_ansi.h>
#include "../lib/encnames.h"
#include "../lib/ucsconv.h"

/*
 * Enable CES converter if correspondent encoding is requested.
 * Defining ICONV_TO_UCS_CES_XXX macro or ICONV_FROM_UCS_CES_XXX
 * macro is needed to enable "XXX encoding -> UCS" or "UCS -> XXX encoding"
 * part of UCS-based CES converter.
 */
#if defined (_ICONV_FROM_ENCODING_EUC_JP) \
 || defined (_ICONV_FROM_ENCODING_EUC_KR) \
 || defined (_ICONV_FROM_ENCODING_EUC_TW)
#  define ICONV_TO_UCS_CES_EUC
#endif
#if defined (_ICONV_TO_ENCODING_EUC_JP) \
 || defined (_ICONV_TO_ENCODING_EUC_KR) \
 || defined (_ICONV_TO_ENCODING_EUC_TW)
#  define ICONV_FROM_UCS_CES_EUC
#endif

#if defined (_ICONV_FROM_ENCODING_CP775) \
 || defined (_ICONV_FROM_ENCODING_CP850) \
 || defined (_ICONV_FROM_ENCODING_CP852) \
 || defined (_ICONV_FROM_ENCODING_CP855) \
 || defined (_ICONV_FROM_ENCODING_CP866) \
 || defined (_ICONV_FROM_ENCODING_ISO_8859_1) \
 || defined (_ICONV_FROM_ENCODING_ISO_8859_10) \
 || defined (_ICONV_FROM_ENCODING_ISO_8859_11) \
 || defined (_ICONV_FROM_ENCODING_ISO_8859_13) \
 || defined (_ICONV_FROM_ENCODING_ISO_8859_14) \
 || defined (_ICONV_FROM_ENCODING_ISO_8859_15) \
 || defined (_ICONV_FROM_ENCODING_ISO_8859_2) \
 || defined (_ICONV_FROM_ENCODING_ISO_8859_3) \
 || defined (_ICONV_FROM_ENCODING_ISO_8859_4) \
 || defined (_ICONV_FROM_ENCODING_ISO_8859_5) \
 || defined (_ICONV_FROM_ENCODING_ISO_8859_6) \
 || defined (_ICONV_FROM_ENCODING_ISO_8859_7) \
 || defined (_ICONV_FROM_ENCODING_ISO_8859_8) \
 || defined (_ICONV_FROM_ENCODING_ISO_8859_9) \
 || defined (_ICONV_FROM_ENCODING_ISO_IR_111) \
 || defined (_ICONV_FROM_ENCODING_KOI8_R) \
 || defined (_ICONV_FROM_ENCODING_KOI8_RU) \
 || defined (_ICONV_FROM_ENCODING_KOI8_U) \
 || defined (_ICONV_FROM_ENCODING_KOI8_UNI) \
 || defined (_ICONV_FROM_ENCODING_WIN_1250) \
 || defined (_ICONV_FROM_ENCODING_WIN_1251) \
 || defined (_ICONV_FROM_ENCODING_WIN_1252) \
 || defined (_ICONV_FROM_ENCODING_WIN_1253) \
 || defined (_ICONV_FROM_ENCODING_WIN_1254) \
 || defined (_ICONV_FROM_ENCODING_WIN_1255) \
 || defined (_ICONV_FROM_ENCODING_WIN_1256) \
 || defined (_ICONV_FROM_ENCODING_WIN_1257) \
 || defined (_ICONV_FROM_ENCODING_WIN_1258)
#  define ICONV_TO_UCS_CES_TABLE
#endif
#if defined (_ICONV_TO_ENCODING_CP775) \
 || defined (_ICONV_TO_ENCODING_CP850) \
 || defined (_ICONV_TO_ENCODING_CP852) \
 || defined (_ICONV_TO_ENCODING_CP855) \
 || defined (_ICONV_TO_ENCODING_CP866) \
 || defined (_ICONV_TO_ENCODING_ISO_8859_1) \
 || defined (_ICONV_TO_ENCODING_ISO_8859_10) \
 || defined (_ICONV_TO_ENCODING_ISO_8859_11) \
 || defined (_ICONV_TO_ENCODING_ISO_8859_13) \
 || defined (_ICONV_TO_ENCODING_ISO_8859_14) \
 || defined (_ICONV_TO_ENCODING_ISO_8859_15) \
 || defined (_ICONV_TO_ENCODING_ISO_8859_2) \
 || defined (_ICONV_TO_ENCODING_ISO_8859_3) \
 || defined (_ICONV_TO_ENCODING_ISO_8859_4) \
 || defined (_ICONV_TO_ENCODING_ISO_8859_5) \
 || defined (_ICONV_TO_ENCODING_ISO_8859_6) \
 || defined (_ICONV_TO_ENCODING_ISO_8859_7) \
 || defined (_ICONV_TO_ENCODING_ISO_8859_8) \
 || defined (_ICONV_TO_ENCODING_ISO_8859_9) \
 || defined (_ICONV_TO_ENCODING_ISO_IR_111) \
 || defined (_ICONV_TO_ENCODING_KOI8_R) \
 || defined (_ICONV_TO_ENCODING_KOI8_RU) \
 || defined (_ICONV_TO_ENCODING_KOI8_U) \
 || defined (_ICONV_TO_ENCODING_KOI8_UNI) \
 || defined (_ICONV_TO_ENCODING_WIN_1250) \
 || defined (_ICONV_TO_ENCODING_WIN_1251) \
 || defined (_ICONV_TO_ENCODING_WIN_1252) \
 || defined (_ICONV_TO_ENCODING_WIN_1253) \
 || defined (_ICONV_TO_ENCODING_WIN_1254) \
 || defined (_ICONV_TO_ENCODING_WIN_1255) \
 || defined (_ICONV_TO_ENCODING_WIN_1256) \
 || defined (_ICONV_TO_ENCODING_WIN_1257) \
 || defined (_ICONV_TO_ENCODING_WIN_1258)
#  define ICONV_FROM_UCS_CES_TABLE
#endif

#if defined (_ICONV_FROM_ENCODING_BIG5)
#  define ICONV_TO_UCS_CES_TABLE_PCS
#endif
#if defined (_ICONV_TO_ENCODING_BIG5)
#  define ICONV_FROM_UCS_CES_TABLE_PCS
#endif

#if defined (_ICONV_FROM_ENCODING_UCS_2) \
 || defined (_ICONV_FROM_ENCODING_UCS_2BE) \
 || defined (_ICONV_FROM_ENCODING_UCS_2LE)
#  define ICONV_TO_UCS_CES_UCS_2
#endif
#if defined (_ICONV_TO_ENCODING_UCS_2) \
 || defined (_ICONV_TO_ENCODING_UCS_2BE) \
 || defined (_ICONV_TO_ENCODING_UCS_2LE)
#  define ICONV_FROM_UCS_CES_UCS_2
#endif

#if defined (_ICONV_FROM_ENCODING_UCS_2_INTERNAL)
#  define ICONV_TO_UCS_CES_UCS_2_INTERNAL
#endif
#if defined (_ICONV_TO_ENCODING_UCS_2_INTERNAL)
#  define ICONV_FROM_UCS_CES_UCS_2_INTERNAL
#endif

#if defined (_ICONV_FROM_ENCODING_UCS_4) \
 || defined (_ICONV_FROM_ENCODING_UCS_4BE) \
 || defined (_ICONV_FROM_ENCODING_UCS_4LE)
#  define ICONV_TO_UCS_CES_UCS_4
#endif
#if defined (_ICONV_TO_ENCODING_UCS_4) \
 || defined (_ICONV_TO_ENCODING_UCS_4BE) \
 || defined (_ICONV_TO_ENCODING_UCS_4LE)
#  define ICONV_FROM_UCS_CES_UCS_4
#endif

#if defined (_ICONV_FROM_ENCODING_UCS_4_INTERNAL)
#  define ICONV_TO_UCS_CES_UCS_4_INTERNAL
#endif
#if defined (_ICONV_TO_ENCODING_UCS_4_INTERNAL)
#  define ICONV_FROM_UCS_CES_UCS_4_INTERNAL
#endif

#if defined (_ICONV_FROM_ENCODING_US_ASCII)
#  define ICONV_TO_UCS_CES_US_ASCII
#endif
#if defined (_ICONV_TO_ENCODING_US_ASCII)
#  define ICONV_FROM_UCS_CES_US_ASCII
#endif

#if defined (_ICONV_FROM_ENCODING_UTF_16) \
 || defined (_ICONV_FROM_ENCODING_UTF_16BE) \
 || defined (_ICONV_FROM_ENCODING_UTF_16LE)
#  define ICONV_TO_UCS_CES_UTF_16
#endif
#if defined (_ICONV_TO_ENCODING_UTF_16) \
 || defined (_ICONV_TO_ENCODING_UTF_16BE) \
 || defined (_ICONV_TO_ENCODING_UTF_16LE)
#  define ICONV_FROM_UCS_CES_UTF_16
#endif

#if defined (_ICONV_FROM_ENCODING_UTF_8)
#  define ICONV_TO_UCS_CES_UTF_8
#endif
#if defined (_ICONV_TO_ENCODING_UTF_8)
#  define ICONV_FROM_UCS_CES_UTF_8
#endif

/*
 * Some encodings require another encodings to be enabled.
 * These dependencies are handled in cesdeps.h header file.
 */
#include "cesdeps.h"

/*
 * NLS uses iconv's capabilities and require one of encodings
 * to be enabled for internal wchar_t representation.
 */
#include "../lib/iconvnls.h"

/*
 * Forward declarations of CES converter handlers.
 * These handlers are actually defined in correspondent CES converter files.
 */
#ifdef ICONV_TO_UCS_CES_EUC
extern _CONST iconv_to_ucs_ces_handlers_t
_iconv_to_ucs_ces_handlers_euc;
#endif
#ifdef ICONV_FROM_UCS_CES_EUC
extern _CONST iconv_from_ucs_ces_handlers_t
_iconv_from_ucs_ces_handlers_euc;
#endif

#ifdef ICONV_TO_UCS_CES_TABLE
extern _CONST iconv_to_ucs_ces_handlers_t
_iconv_to_ucs_ces_handlers_table;
#endif
#ifdef ICONV_FROM_UCS_CES_TABLE
extern _CONST iconv_from_ucs_ces_handlers_t
_iconv_from_ucs_ces_handlers_table;
#endif

#ifdef ICONV_TO_UCS_CES_TABLE_PCS
extern _CONST iconv_to_ucs_ces_handlers_t
_iconv_to_ucs_ces_handlers_table_pcs;
#endif
#ifdef ICONV_FROM_UCS_CES_TABLE_PCS
extern _CONST iconv_from_ucs_ces_handlers_t
_iconv_from_ucs_ces_handlers_table_pcs;
#endif

#ifdef ICONV_TO_UCS_CES_UCS_2
extern _CONST iconv_to_ucs_ces_handlers_t
_iconv_to_ucs_ces_handlers_ucs_2;
#endif
#ifdef ICONV_FROM_UCS_CES_UCS_2
extern _CONST iconv_from_ucs_ces_handlers_t
_iconv_from_ucs_ces_handlers_ucs_2;
#endif

#ifdef ICONV_TO_UCS_CES_UCS_2_INTERNAL
extern _CONST iconv_to_ucs_ces_handlers_t
_iconv_to_ucs_ces_handlers_ucs_2_internal;
#endif
#ifdef ICONV_FROM_UCS_CES_UCS_2_INTERNAL
extern _CONST iconv_from_ucs_ces_handlers_t
_iconv_from_ucs_ces_handlers_ucs_2_internal;
#endif

#ifdef ICONV_TO_UCS_CES_UCS_4
extern _CONST iconv_to_ucs_ces_handlers_t
_iconv_to_ucs_ces_handlers_ucs_4;
#endif
#ifdef ICONV_FROM_UCS_CES_UCS_4
extern _CONST iconv_from_ucs_ces_handlers_t
_iconv_from_ucs_ces_handlers_ucs_4;
#endif

#ifdef ICONV_TO_UCS_CES_UCS_4_INTERNAL
extern _CONST iconv_to_ucs_ces_handlers_t
_iconv_to_ucs_ces_handlers_ucs_4_internal;
#endif
#ifdef ICONV_FROM_UCS_CES_UCS_4_INTERNAL
extern _CONST iconv_from_ucs_ces_handlers_t
_iconv_from_ucs_ces_handlers_ucs_4_internal;
#endif

#ifdef ICONV_TO_UCS_CES_US_ASCII
extern _CONST iconv_to_ucs_ces_handlers_t
_iconv_to_ucs_ces_handlers_us_ascii;
#endif
#ifdef ICONV_FROM_UCS_CES_US_ASCII
extern _CONST iconv_from_ucs_ces_handlers_t
_iconv_from_ucs_ces_handlers_us_ascii;
#endif

#ifdef ICONV_TO_UCS_CES_UTF_16
extern _CONST iconv_to_ucs_ces_handlers_t
_iconv_to_ucs_ces_handlers_utf_16;
#endif
#ifdef ICONV_FROM_UCS_CES_UTF_16
extern _CONST iconv_from_ucs_ces_handlers_t
_iconv_from_ucs_ces_handlers_utf_16;
#endif

#ifdef ICONV_TO_UCS_CES_UTF_8
extern _CONST iconv_to_ucs_ces_handlers_t
_iconv_to_ucs_ces_handlers_utf_8;
#endif
#ifdef ICONV_FROM_UCS_CES_UTF_8
extern _CONST iconv_from_ucs_ces_handlers_t
_iconv_from_ucs_ces_handlers_utf_8;
#endif

#endif /* !__CESBI_H__ */

