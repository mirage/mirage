#ifndef __ICONV_ICONVNLS_H__
#define __ICONV_ICONVNLS_H__

#include <newlib.h>

/*
 * Include ucs-2-internal or ucs-4-internal if Newlib is configured as
 * "multibyte-capable".
 * ============================================================================
 */
#ifdef _MB_CAPABLE
/*
 * Determine size of wchar_t. If size of wchar_t is 2, UCS-2-INTERNAL is used
 * as widechar's encoding. If size of wchar_t is 4, UCS-4-INTERNAL is used as
 * widechar's encoding.
 */
# if WCHAR_MAX > 0xFFFF
#  ifndef _ICONV_FROM_ENCODING_UCS_4_INTERNAL
#   define _ICONV_FROM_ENCODING_UCS_4_INTERNAL
#  endif
#  ifndef _ICONV_TO_ENCODING_UCS_4_INTERNAL
#   define _ICONV_TO_ENCODING_UCS_4_INTERNAL
#  endif
# elif WCHAR_MAX > 0xFF
#  ifndef _ICONV_FROM_ENCODING_UCS_2_INTERNAL
#   define _ICONV_FROM_ENCODING_UCS_2_INTERNAL
#  endif
#  ifndef _ICONV_TO_ENCODING_UCS_2_INTERNAL
#   define _ICONV_TO_ENCODING_UCS_2_INTERNAL
#  endif
# else
#  error Do not know how to work with 1 byte widechars.
# endif
#endif /* _MB_CAPABLE */

#endif /* !__ICONV_ICONVNLS_H__ */

