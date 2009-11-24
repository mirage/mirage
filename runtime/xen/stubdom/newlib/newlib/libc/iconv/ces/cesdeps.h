/*
 * This file was automatically generated mkdeps.pl script. Don't edit.
 */

#ifndef __CESDEPS_H__
#define __CESDEPS_H__

/*
 * Some CES converters use another CES converters and the following
 * is such dependencies description.
 */
#ifdef ICONV_TO_UCS_CES_EUC
#  ifndef ICONV_TO_UCS_CES_TABLE
#    define ICONV_TO_UCS_CES_TABLE
#  endif
#  ifndef ICONV_TO_UCS_CES_US_ASCII
#    define ICONV_TO_UCS_CES_US_ASCII
#  endif
#endif
#ifdef ICONV_FROM_UCS_CES_EUC
#  ifndef ICONV_FROM_UCS_CES_TABLE
#    define ICONV_FROM_UCS_CES_TABLE
#  endif
#  ifndef ICONV_FROM_UCS_CES_US_ASCII
#    define ICONV_FROM_UCS_CES_US_ASCII
#  endif
#endif
#ifdef ICONV_TO_UCS_CES_TABLE_PCS
#  ifndef ICONV_TO_UCS_CES_TABLE
#    define ICONV_TO_UCS_CES_TABLE
#  endif
#endif
#ifdef ICONV_FROM_UCS_CES_TABLE_PCS
#  ifndef ICONV_FROM_UCS_CES_TABLE
#    define ICONV_FROM_UCS_CES_TABLE
#  endif
#endif

#endif /* !__CESDEPS_H__ */

