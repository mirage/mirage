/* wctrans constants */

#include <_ansi.h>

/* valid values for wctrans_t */
#define WCT_TOLOWER 1
#define WCT_TOUPPER 2

/* valid values for wctype_t */
#define WC_ALNUM	1
#define WC_ALPHA	2
#define WC_BLANK	3
#define WC_CNTRL	4
#define WC_DIGIT	5
#define WC_GRAPH	6
#define WC_LOWER	7
#define WC_PRINT	8
#define WC_PUNCT	9
#define WC_SPACE	10
#define WC_UPPER	11
#define WC_XDIGIT	12

extern char __lc_ctype[12];

/* Japanese encoding types supported */
#define JP_JIS		1
#define JP_SJIS		2
#define JP_EUCJP	3

/* internal function to translate JP to Unicode */
wint_t _EXFUN (__jp2uc, (wint_t, int));

