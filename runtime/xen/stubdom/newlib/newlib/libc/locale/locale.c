/*
FUNCTION
<<setlocale>>, <<localeconv>>---select or query locale

INDEX
	setlocale
INDEX
	localeconv
INDEX
	_setlocale_r
INDEX
	_localeconv_r

ANSI_SYNOPSIS
	#include <locale.h>
	char *setlocale(int <[category]>, const char *<[locale]>);
	lconv *localeconv(void);

	char *_setlocale_r(void *<[reent]>,
                        int <[category]>, const char *<[locale]>);
	lconv *_localeconv_r(void *<[reent]>);

TRAD_SYNOPSIS
	#include <locale.h>
	char *setlocale(<[category]>, <[locale]>)
	int <[category]>;
	char *<[locale]>;

	lconv *localeconv();

	char *_setlocale_r(<[reent]>, <[category]>, <[locale]>)
	char *<[reent]>;
	int <[category]>;
	char *<[locale]>;

	lconv *_localeconv_r(<[reent]>);
	char *<[reent]>;

DESCRIPTION
<<setlocale>> is the facility defined by ANSI C to condition the
execution environment for international collating and formatting
information; <<localeconv>> reports on the settings of the current
locale.

This is a minimal implementation, supporting only the required <<"C">>
value for <[locale]>; strings representing other locales are not
honored unless _MB_CAPABLE is defined in which case three new
extensions are allowed for LC_CTYPE or LC_MESSAGES only: <<"C-JIS">>, 
<<"C-EUCJP">>, <<"C-SJIS">>, or <<"C-ISO-8859-1">>.  (<<"">> is 
also accepted; it represents the default locale
for an implementation, here equivalent to <<"C">>.)

If you use <<NULL>> as the <[locale]> argument, <<setlocale>> returns
a pointer to the string representing the current locale (always
<<"C">> in this implementation).  The acceptable values for
<[category]> are defined in `<<locale.h>>' as macros beginning with
<<"LC_">>, but this implementation does not check the values you pass
in the <[category]> argument.

<<localeconv>> returns a pointer to a structure (also defined in
`<<locale.h>>') describing the locale-specific conventions currently
in effect.  

<<_localeconv_r>> and <<_setlocale_r>> are reentrant versions of
<<localeconv>> and <<setlocale>> respectively.  The extra argument
<[reent]> is a pointer to a reentrancy structure.

RETURNS
<<setlocale>> returns either a pointer to a string naming the locale
currently in effect (always <<"C">> for this implementation, or, if
the locale request cannot be honored, <<NULL>>.

<<localeconv>> returns a pointer to a structure of type <<lconv>>,
which describes the formatting and collating conventions in effect (in
this implementation, always those of the C locale).

PORTABILITY
ANSI C requires <<setlocale>>, but the only locale required across all
implementations is the C locale.

No supporting OS subroutines are required.
*/

/*
 * setlocale, localeconv : internationalize your locale.
 *                         (Only "C" or null supported).
 */

#include <newlib.h>
#include <locale.h>
#include <string.h>
#include <limits.h>
#include <reent.h>

#ifdef __CYGWIN__
int __declspec(dllexport) __mb_cur_max = 1;
#else
int __mb_cur_max = 1;
#endif

int __nlocale_changed = 0;
int __mlocale_changed = 0;
char *_PathLocale = NULL;

static _CONST struct lconv lconv = 
{
  ".", "", "", "", "", "", "", "", "", "",
  CHAR_MAX, CHAR_MAX, CHAR_MAX, CHAR_MAX,
  CHAR_MAX, CHAR_MAX, CHAR_MAX, CHAR_MAX,
};


char * _EXFUN(__locale_charset,(_VOID));

static char *charset = "ISO-8859-1";
char __lc_ctype[12] = "C";

char *
_DEFUN(_setlocale_r, (p, category, locale),
       struct _reent *p _AND
       int category _AND
       _CONST char *locale)
{
#ifndef _MB_CAPABLE
  if (locale)
    { 
      if (strcmp (locale, "C") && strcmp (locale, ""))
        return 0;
      p->_current_category = category;  
      p->_current_locale = locale;
    }
  return "C";
#else
  static char last_lc_ctype[12] = "C";
  static char lc_messages[12] = "C";
  static char last_lc_messages[12] = "C";

  if (locale)
    {
      char *locale_name = (char *)locale;
      if (category != LC_CTYPE && category != LC_MESSAGES) 
        { 
          if (strcmp (locale, "C") && strcmp (locale, ""))
            return 0;
          if (category == LC_ALL)
            {
              strcpy (last_lc_ctype, __lc_ctype);
              strcpy (__lc_ctype, "C");
              strcpy (last_lc_messages, lc_messages);
              strcpy (lc_messages, "C");
              __mb_cur_max = 1;
            }
        }
      else
        {
          if (locale[0] == 'C' && locale[1] == '-')
            {
              switch (locale[2])
                {
                case 'U':
                  if (strcmp (locale, "C-UTF-8"))
                    return 0;
                break;
                case 'J':
                  if (strcmp (locale, "C-JIS"))
                    return 0;
                break;
                case 'E':
                  if (strcmp (locale, "C-EUCJP"))
                    return 0;
                break;
                case 'S':
                  if (strcmp (locale, "C-SJIS"))
                    return 0;
                break;
                case 'I':
                  if (strcmp (locale, "C-ISO-8859-1"))
                    return 0;
                break;
                default:
                  return 0;
                }
            }
          else 
            {
              if (strcmp (locale, "C") && strcmp (locale, ""))
                return 0;
              locale_name = "C"; /* C is always the default locale */
            }

          if (category == LC_CTYPE)
            {
              strcpy (last_lc_ctype, __lc_ctype);
              strcpy (__lc_ctype, locale_name);

              __mb_cur_max = 1;
              if (locale[1] == '-')
                {
                  switch (locale[2])
                    {
                    case 'U':
                      __mb_cur_max = 6;
                    break;
                    case 'J':
                      __mb_cur_max = 8;
                    break;
                    case 'E':
                      __mb_cur_max = 2;
                    break;
                    case 'S':
                      __mb_cur_max = 2;
                    break;
                    case 'I':
                    default:
                      __mb_cur_max = 1;
                    }
                }
            }
          else
            {
              strcpy (last_lc_messages, lc_messages);
              strcpy (lc_messages, locale_name);

              charset = "ISO-8859-1";
              if (locale[1] == '-')
                {
                  switch (locale[2])
                    {
                    case 'U':
                      charset = "UTF-8";
                    break;
                    case 'J':
                      charset = "JIS";
                    break;
                    case 'E':
                      charset = "EUCJP";
                    break;
                    case 'S':
                      charset = "SJIS";
                    break;
                    case 'I':
                      charset = "ISO-8859-1";
                    break;
                    default:
                      return 0;
                    }
                }
            }
        }
      p->_current_category = category;  
      p->_current_locale = locale;

      if (category == LC_CTYPE)
        return last_lc_ctype;
      else if (category == LC_MESSAGES)
        return last_lc_messages;
    }
  else
    {
      if (category == LC_CTYPE)
        return __lc_ctype;
      else if (category == LC_MESSAGES)
        return lc_messages;
    }
 
  return "C";
#endif
  
}

char *
_DEFUN_VOID(__locale_charset)
{
  return charset;
}

struct lconv *
_DEFUN(_localeconv_r, (data), 
      struct _reent *data)
{
  return (struct lconv *) &lconv;
}

#ifndef _REENT_ONLY

char *
_DEFUN(setlocale, (category, locale),
       int category _AND
       _CONST char *locale)
{
  return _setlocale_r (_REENT, category, locale);
}


struct lconv *
_DEFUN_VOID(localeconv)
{
  return _localeconv_r (_REENT);
}

#endif
