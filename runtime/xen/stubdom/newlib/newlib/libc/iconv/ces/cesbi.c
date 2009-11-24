/*
 * This file was automatically generated mkdeps.pl script. Don't edit.
 */

#include <_ansi.h>
#include <newlib.h>
#include "../lib/ucsconv.h"
#include "cesbi.h"

/*
 * Each CES converter provides the list of supported encodings.
 */
#if defined (ICONV_TO_UCS_CES_EUC) \
 || defined (ICONV_FROM_UCS_CES_EUC)
static _CONST char *
iconv_ces_names_euc[] =
{
# if defined (_ICONV_FROM_ENCODING_EUC_JP) \
  || defined (_ICONV_TO_ENCODING_EUC_JP)
  ICONV_ENCODING_EUC_JP,
#endif
# if defined (_ICONV_FROM_ENCODING_EUC_KR) \
  || defined (_ICONV_TO_ENCODING_EUC_KR)
  ICONV_ENCODING_EUC_KR,
#endif
# if defined (_ICONV_FROM_ENCODING_EUC_TW) \
  || defined (_ICONV_TO_ENCODING_EUC_TW)
  ICONV_ENCODING_EUC_TW,
#endif
  NULL
};
#endif

#if defined (ICONV_TO_UCS_CES_TABLE) \
 || defined (ICONV_FROM_UCS_CES_TABLE)
static _CONST char *
iconv_ces_names_table[] =
{
# if defined (_ICONV_FROM_ENCODING_CP775) \
  || defined (_ICONV_TO_ENCODING_CP775)
  ICONV_ENCODING_CP775,
#endif
# if defined (_ICONV_FROM_ENCODING_CP850) \
  || defined (_ICONV_TO_ENCODING_CP850)
  ICONV_ENCODING_CP850,
#endif
# if defined (_ICONV_FROM_ENCODING_CP852) \
  || defined (_ICONV_TO_ENCODING_CP852)
  ICONV_ENCODING_CP852,
#endif
# if defined (_ICONV_FROM_ENCODING_CP855) \
  || defined (_ICONV_TO_ENCODING_CP855)
  ICONV_ENCODING_CP855,
#endif
# if defined (_ICONV_FROM_ENCODING_CP866) \
  || defined (_ICONV_TO_ENCODING_CP866)
  ICONV_ENCODING_CP866,
#endif
# if defined (_ICONV_FROM_ENCODING_ISO_8859_1) \
  || defined (_ICONV_TO_ENCODING_ISO_8859_1)
  ICONV_ENCODING_ISO_8859_1,
#endif
# if defined (_ICONV_FROM_ENCODING_ISO_8859_10) \
  || defined (_ICONV_TO_ENCODING_ISO_8859_10)
  ICONV_ENCODING_ISO_8859_10,
#endif
# if defined (_ICONV_FROM_ENCODING_ISO_8859_11) \
  || defined (_ICONV_TO_ENCODING_ISO_8859_11)
  ICONV_ENCODING_ISO_8859_11,
#endif
# if defined (_ICONV_FROM_ENCODING_ISO_8859_13) \
  || defined (_ICONV_TO_ENCODING_ISO_8859_13)
  ICONV_ENCODING_ISO_8859_13,
#endif
# if defined (_ICONV_FROM_ENCODING_ISO_8859_14) \
  || defined (_ICONV_TO_ENCODING_ISO_8859_14)
  ICONV_ENCODING_ISO_8859_14,
#endif
# if defined (_ICONV_FROM_ENCODING_ISO_8859_15) \
  || defined (_ICONV_TO_ENCODING_ISO_8859_15)
  ICONV_ENCODING_ISO_8859_15,
#endif
# if defined (_ICONV_FROM_ENCODING_ISO_8859_2) \
  || defined (_ICONV_TO_ENCODING_ISO_8859_2)
  ICONV_ENCODING_ISO_8859_2,
#endif
# if defined (_ICONV_FROM_ENCODING_ISO_8859_3) \
  || defined (_ICONV_TO_ENCODING_ISO_8859_3)
  ICONV_ENCODING_ISO_8859_3,
#endif
# if defined (_ICONV_FROM_ENCODING_ISO_8859_4) \
  || defined (_ICONV_TO_ENCODING_ISO_8859_4)
  ICONV_ENCODING_ISO_8859_4,
#endif
# if defined (_ICONV_FROM_ENCODING_ISO_8859_5) \
  || defined (_ICONV_TO_ENCODING_ISO_8859_5)
  ICONV_ENCODING_ISO_8859_5,
#endif
# if defined (_ICONV_FROM_ENCODING_ISO_8859_6) \
  || defined (_ICONV_TO_ENCODING_ISO_8859_6)
  ICONV_ENCODING_ISO_8859_6,
#endif
# if defined (_ICONV_FROM_ENCODING_ISO_8859_7) \
  || defined (_ICONV_TO_ENCODING_ISO_8859_7)
  ICONV_ENCODING_ISO_8859_7,
#endif
# if defined (_ICONV_FROM_ENCODING_ISO_8859_8) \
  || defined (_ICONV_TO_ENCODING_ISO_8859_8)
  ICONV_ENCODING_ISO_8859_8,
#endif
# if defined (_ICONV_FROM_ENCODING_ISO_8859_9) \
  || defined (_ICONV_TO_ENCODING_ISO_8859_9)
  ICONV_ENCODING_ISO_8859_9,
#endif
# if defined (_ICONV_FROM_ENCODING_ISO_IR_111) \
  || defined (_ICONV_TO_ENCODING_ISO_IR_111)
  ICONV_ENCODING_ISO_IR_111,
#endif
# if defined (_ICONV_FROM_ENCODING_KOI8_R) \
  || defined (_ICONV_TO_ENCODING_KOI8_R)
  ICONV_ENCODING_KOI8_R,
#endif
# if defined (_ICONV_FROM_ENCODING_KOI8_RU) \
  || defined (_ICONV_TO_ENCODING_KOI8_RU)
  ICONV_ENCODING_KOI8_RU,
#endif
# if defined (_ICONV_FROM_ENCODING_KOI8_U) \
  || defined (_ICONV_TO_ENCODING_KOI8_U)
  ICONV_ENCODING_KOI8_U,
#endif
# if defined (_ICONV_FROM_ENCODING_KOI8_UNI) \
  || defined (_ICONV_TO_ENCODING_KOI8_UNI)
  ICONV_ENCODING_KOI8_UNI,
#endif
# if defined (_ICONV_FROM_ENCODING_WIN_1250) \
  || defined (_ICONV_TO_ENCODING_WIN_1250)
  ICONV_ENCODING_WIN_1250,
#endif
# if defined (_ICONV_FROM_ENCODING_WIN_1251) \
  || defined (_ICONV_TO_ENCODING_WIN_1251)
  ICONV_ENCODING_WIN_1251,
#endif
# if defined (_ICONV_FROM_ENCODING_WIN_1252) \
  || defined (_ICONV_TO_ENCODING_WIN_1252)
  ICONV_ENCODING_WIN_1252,
#endif
# if defined (_ICONV_FROM_ENCODING_WIN_1253) \
  || defined (_ICONV_TO_ENCODING_WIN_1253)
  ICONV_ENCODING_WIN_1253,
#endif
# if defined (_ICONV_FROM_ENCODING_WIN_1254) \
  || defined (_ICONV_TO_ENCODING_WIN_1254)
  ICONV_ENCODING_WIN_1254,
#endif
# if defined (_ICONV_FROM_ENCODING_WIN_1255) \
  || defined (_ICONV_TO_ENCODING_WIN_1255)
  ICONV_ENCODING_WIN_1255,
#endif
# if defined (_ICONV_FROM_ENCODING_WIN_1256) \
  || defined (_ICONV_TO_ENCODING_WIN_1256)
  ICONV_ENCODING_WIN_1256,
#endif
# if defined (_ICONV_FROM_ENCODING_WIN_1257) \
  || defined (_ICONV_TO_ENCODING_WIN_1257)
  ICONV_ENCODING_WIN_1257,
#endif
# if defined (_ICONV_FROM_ENCODING_WIN_1258) \
  || defined (_ICONV_TO_ENCODING_WIN_1258)
  ICONV_ENCODING_WIN_1258,
#endif
  NULL
};
#endif

#if defined (ICONV_TO_UCS_CES_TABLE_PCS) \
 || defined (ICONV_FROM_UCS_CES_TABLE_PCS)
static _CONST char *
iconv_ces_names_table_pcs[] =
{
# if defined (_ICONV_FROM_ENCODING_BIG5) \
  || defined (_ICONV_TO_ENCODING_BIG5)
  ICONV_ENCODING_BIG5,
#endif
  NULL
};
#endif

#if defined (ICONV_TO_UCS_CES_UCS_2) \
 || defined (ICONV_FROM_UCS_CES_UCS_2)
static _CONST char *
iconv_ces_names_ucs_2[] =
{
# if defined (_ICONV_FROM_ENCODING_UCS_2) \
  || defined (_ICONV_TO_ENCODING_UCS_2)
  ICONV_ENCODING_UCS_2,
#endif
# if defined (_ICONV_FROM_ENCODING_UCS_2BE) \
  || defined (_ICONV_TO_ENCODING_UCS_2BE)
  ICONV_ENCODING_UCS_2BE,
#endif
# if defined (_ICONV_FROM_ENCODING_UCS_2LE) \
  || defined (_ICONV_TO_ENCODING_UCS_2LE)
  ICONV_ENCODING_UCS_2LE,
#endif
  NULL
};
#endif

#if defined (ICONV_TO_UCS_CES_UCS_2_INTERNAL) \
 || defined (ICONV_FROM_UCS_CES_UCS_2_INTERNAL)
static _CONST char *
iconv_ces_names_ucs_2_internal[] =
{
# if defined (_ICONV_FROM_ENCODING_UCS_2_INTERNAL) \
  || defined (_ICONV_TO_ENCODING_UCS_2_INTERNAL)
  ICONV_ENCODING_UCS_2_INTERNAL,
#endif
  NULL
};
#endif

#if defined (ICONV_TO_UCS_CES_UCS_4) \
 || defined (ICONV_FROM_UCS_CES_UCS_4)
static _CONST char *
iconv_ces_names_ucs_4[] =
{
# if defined (_ICONV_FROM_ENCODING_UCS_4) \
  || defined (_ICONV_TO_ENCODING_UCS_4)
  ICONV_ENCODING_UCS_4,
#endif
# if defined (_ICONV_FROM_ENCODING_UCS_4BE) \
  || defined (_ICONV_TO_ENCODING_UCS_4BE)
  ICONV_ENCODING_UCS_4BE,
#endif
# if defined (_ICONV_FROM_ENCODING_UCS_4LE) \
  || defined (_ICONV_TO_ENCODING_UCS_4LE)
  ICONV_ENCODING_UCS_4LE,
#endif
  NULL
};
#endif

#if defined (ICONV_TO_UCS_CES_UCS_4_INTERNAL) \
 || defined (ICONV_FROM_UCS_CES_UCS_4_INTERNAL)
static _CONST char *
iconv_ces_names_ucs_4_internal[] =
{
# if defined (_ICONV_FROM_ENCODING_UCS_4_INTERNAL) \
  || defined (_ICONV_TO_ENCODING_UCS_4_INTERNAL)
  ICONV_ENCODING_UCS_4_INTERNAL,
#endif
  NULL
};
#endif

#if defined (ICONV_TO_UCS_CES_US_ASCII) \
 || defined (ICONV_FROM_UCS_CES_US_ASCII)
static _CONST char *
iconv_ces_names_us_ascii[] =
{
# if defined (_ICONV_FROM_ENCODING_US_ASCII) \
  || defined (_ICONV_TO_ENCODING_US_ASCII)
  ICONV_ENCODING_US_ASCII,
#endif
  NULL
};
#endif

#if defined (ICONV_TO_UCS_CES_UTF_16) \
 || defined (ICONV_FROM_UCS_CES_UTF_16)
static _CONST char *
iconv_ces_names_utf_16[] =
{
# if defined (_ICONV_FROM_ENCODING_UTF_16) \
  || defined (_ICONV_TO_ENCODING_UTF_16)
  ICONV_ENCODING_UTF_16,
#endif
# if defined (_ICONV_FROM_ENCODING_UTF_16BE) \
  || defined (_ICONV_TO_ENCODING_UTF_16BE)
  ICONV_ENCODING_UTF_16BE,
#endif
# if defined (_ICONV_FROM_ENCODING_UTF_16LE) \
  || defined (_ICONV_TO_ENCODING_UTF_16LE)
  ICONV_ENCODING_UTF_16LE,
#endif
  NULL
};
#endif

#if defined (ICONV_TO_UCS_CES_UTF_8) \
 || defined (ICONV_FROM_UCS_CES_UTF_8)
static _CONST char *
iconv_ces_names_utf_8[] =
{
# if defined (_ICONV_FROM_ENCODING_UTF_8) \
  || defined (_ICONV_TO_ENCODING_UTF_8)
  ICONV_ENCODING_UTF_8,
#endif
  NULL
};
#endif

/*
 * The following structure contains the list of "to UCS" linked-in CES converters.
 */
_CONST iconv_to_ucs_ces_t
_iconv_to_ucs_ces[] =
{
#ifdef ICONV_TO_UCS_CES_EUC
  {(_CONST char **)iconv_ces_names_euc,
   &_iconv_to_ucs_ces_handlers_euc},
#endif
#ifdef ICONV_TO_UCS_CES_TABLE
  {(_CONST char **)iconv_ces_names_table,
   &_iconv_to_ucs_ces_handlers_table},
#endif
#ifdef ICONV_TO_UCS_CES_TABLE_PCS
  {(_CONST char **)iconv_ces_names_table_pcs,
   &_iconv_to_ucs_ces_handlers_table_pcs},
#endif
#ifdef ICONV_TO_UCS_CES_UCS_2
  {(_CONST char **)iconv_ces_names_ucs_2,
   &_iconv_to_ucs_ces_handlers_ucs_2},
#endif
#ifdef ICONV_TO_UCS_CES_UCS_2_INTERNAL
  {(_CONST char **)iconv_ces_names_ucs_2_internal,
   &_iconv_to_ucs_ces_handlers_ucs_2_internal},
#endif
#ifdef ICONV_TO_UCS_CES_UCS_4
  {(_CONST char **)iconv_ces_names_ucs_4,
   &_iconv_to_ucs_ces_handlers_ucs_4},
#endif
#ifdef ICONV_TO_UCS_CES_UCS_4_INTERNAL
  {(_CONST char **)iconv_ces_names_ucs_4_internal,
   &_iconv_to_ucs_ces_handlers_ucs_4_internal},
#endif
#ifdef ICONV_TO_UCS_CES_US_ASCII
  {(_CONST char **)iconv_ces_names_us_ascii,
   &_iconv_to_ucs_ces_handlers_us_ascii},
#endif
#ifdef ICONV_TO_UCS_CES_UTF_16
  {(_CONST char **)iconv_ces_names_utf_16,
   &_iconv_to_ucs_ces_handlers_utf_16},
#endif
#ifdef ICONV_TO_UCS_CES_UTF_8
  {(_CONST char **)iconv_ces_names_utf_8,
   &_iconv_to_ucs_ces_handlers_utf_8},
#endif
  {(_CONST char **)NULL,
  (iconv_to_ucs_ces_handlers_t *)NULL}
};

/*
 * The following structure contains the list of "from UCS" linked-in CES converters.
 */
_CONST iconv_from_ucs_ces_t
_iconv_from_ucs_ces[] =
{
#ifdef ICONV_FROM_UCS_CES_EUC
  {(_CONST char **)iconv_ces_names_euc,
   &_iconv_from_ucs_ces_handlers_euc},
#endif
#ifdef ICONV_FROM_UCS_CES_TABLE
  {(_CONST char **)iconv_ces_names_table,
   &_iconv_from_ucs_ces_handlers_table},
#endif
#ifdef ICONV_FROM_UCS_CES_TABLE_PCS
  {(_CONST char **)iconv_ces_names_table_pcs,
   &_iconv_from_ucs_ces_handlers_table_pcs},
#endif
#ifdef ICONV_FROM_UCS_CES_UCS_2
  {(_CONST char **)iconv_ces_names_ucs_2,
   &_iconv_from_ucs_ces_handlers_ucs_2},
#endif
#ifdef ICONV_FROM_UCS_CES_UCS_2_INTERNAL
  {(_CONST char **)iconv_ces_names_ucs_2_internal,
   &_iconv_from_ucs_ces_handlers_ucs_2_internal},
#endif
#ifdef ICONV_FROM_UCS_CES_UCS_4
  {(_CONST char **)iconv_ces_names_ucs_4,
   &_iconv_from_ucs_ces_handlers_ucs_4},
#endif
#ifdef ICONV_FROM_UCS_CES_UCS_4_INTERNAL
  {(_CONST char **)iconv_ces_names_ucs_4_internal,
   &_iconv_from_ucs_ces_handlers_ucs_4_internal},
#endif
#ifdef ICONV_FROM_UCS_CES_US_ASCII
  {(_CONST char **)iconv_ces_names_us_ascii,
   &_iconv_from_ucs_ces_handlers_us_ascii},
#endif
#ifdef ICONV_FROM_UCS_CES_UTF_16
  {(_CONST char **)iconv_ces_names_utf_16,
   &_iconv_from_ucs_ces_handlers_utf_16},
#endif
#ifdef ICONV_FROM_UCS_CES_UTF_8
  {(_CONST char **)iconv_ces_names_utf_8,
   &_iconv_from_ucs_ces_handlers_utf_8},
#endif
  {(_CONST char **)NULL,
  (iconv_from_ucs_ces_handlers_t *)NULL}
};
