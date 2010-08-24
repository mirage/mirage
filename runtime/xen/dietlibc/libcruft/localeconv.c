#include <limits.h>
#include <locale.h>

/* these answers are what glibc says */

static struct lconv l =
  {".","","","","","", 		/* decimal_point - mon_decimal_point */
   "","","","",127,127,		/* mon_thousands_sep - frac_digits */
   127,127,127,127,127,127,	/* p_cs_precedes - n_sign_posn */
   127,127,127,127,127,127 };	/* __int_p_cs_precedes - __int_n_sign_posn */


struct lconv* localeconv() {
  return &l;
}
