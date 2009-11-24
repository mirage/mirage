/*
 * Copyright (c) 1990 The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that the above copyright notice and this paragraph are
 * duplicated in all such forms and that any documentation,
 * advertising materials, and other materials related to such
 * distribution and use acknowledge that the software was developed
 * by the University of California, Berkeley.  The name of the
 * University may not be used to endorse or promote products derived
 * from this software without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */

/*
FUNCTION
<<sprintf>>, <<fprintf>>, <<printf>>, <<snprintf>>, <<asprintf>>, <<asnprintf>>---format output

INDEX
	fprintf
INDEX
	printf
INDEX
	asprintf
INDEX
	sprintf
INDEX
	snprintf
INDEX
	asnprintf

ANSI_SYNOPSIS
        #include <stdio.h>

        int printf(const char *<[format]> [, <[arg]>, ...]);
        int fprintf(FILE *<[fd]>, const char *<[format]> [, <[arg]>, ...]);
        int sprintf(char *<[str]>, const char *<[format]> [, <[arg]>, ...]);
        int snprintf(char *<[str]>, size_t <[size]>, const char *<[format]>
                     [, <[arg]>, ...]);
        int asprintf(char **<[strp]>, const char *<[format]> [, <[arg]>, ...]);
        char *asnprintf(char *<[str]>, size_t *<[size]>, const char *<[format]>
                        [, <[arg]>, ...]);

        int _printf_r(struct _reent *<[ptr]>, const char *<[format]>
                      [, <[arg]>, ...]);
        int _fprintf_r(struct _reent *<[ptr]>, FILE *<[fd]>,
                       const char *<[format]> [, <[arg]>, ...]);
        int _sprintf_r(struct _reent *<[ptr]>, char *<[str]>,
                       const char *<[format]> [, <[arg]>, ...]);
        int _snprintf_r(struct _reent *<[ptr]>, char *<[str]>, size_t <[size]>,
                        const char *<[format]> [, <[arg]>, ...]);
        int _asprintf_r(struct _reent *<[ptr]>, char **<[strp]>,
                        const char *<[format]> [, <[arg]>, ...]);
        char *_asnprintf_r(struct _reent *<[ptr]>, char *<[str]>,
                           size_t *<[size]>, const char *<[format]>
                           [, <[arg]>, ...]);

DESCRIPTION
        <<printf>> accepts a series of arguments, applies to each a
        format specifier from <<*<[format]>>>, and writes the
        formatted data to <<stdout>>, without a terminating NUL
        character.  The behavior of <<printf>> is undefined if there
        are not enough arguments for the format.  <<printf>> returns
        when it reaches the end of the format string.  If there are
        more arguments than the format requires, excess arguments are
        ignored.

        <<fprintf>> is like <<printf>>, except that output is directed
        to the stream <[fd]> rather than <<stdout>>.

        <<sprintf>> is like <<printf>>, except that output is directed
        to the buffer <[str]>, and a terminating NUL is output.
        Behavior is undefined if more output is generated than the
        buffer can hold.

        <<snprintf>> is like <<sprintf>>, except that output is
        limited to at most <[size]> bytes, including the terminating
        <<NUL>>.  As a special case, if <[size]> is 0, <[str]> can be
        NULL, and <<snprintf>> merely calculates how many bytes would
        be printed.

        <<asprintf>> is like <<sprintf>>, except that the output is
        stored in a dynamically allocated buffer, <[pstr]>, which
        should be freed later with <<free>>.

        <<asnprintf>> is like <<sprintf>>, except that the return type
        is either the original <[str]> if it was large enough, or a
        dynamically allocated string if the output exceeds *<[size]>;
        the length of the result is returned in *<[size]>.  When
        dynamic allocation occurs, the contents of the original
        <[str]> may have been modified.

        For <<sprintf>>, <<snprintf>>, and <<asnprintf>>, the behavior
	is undefined if the output <<*<[str]>>> overlaps with one of
	the arguments.  Behavior is also undefined if the argument for
	<<%n>> within <<*<[format]>>> overlaps another argument.

        <[format]> is a pointer to a character string containing two
	types of objects: ordinary characters (other than <<%>>),
	which are copied unchanged to the output, and conversion
	specifications, each of which is introduced by <<%>>. (To
	include <<%>> in the output, use <<%%>> in the format string.)
	A conversion specification has the following form:

.       %[<[pos]>][<[flags]>][<[width]>][.<[prec]>][<[size]>]<[type]>

        The fields of the conversion specification have the following
        meanings:

        O+
	o <[pos]>

        Conversions normally consume arguments in the order that they
        are presented.  However, it is possible to consume arguments
        out of order, and reuse an argument for more than one
        conversion specification (although the behavior is undefined
        if the same argument is requested with different types), by
        specifying <[pos]>, which is a decimal integer followed by
        '$'.  The integer must be between 1 and <NL_ARGMAX> from
        limits.h, and if argument <<%n$>> is requested, all earlier
        arguments must be requested somewhere within <[format]>.  If
        positional parameters are used, then all conversion
        specifications except for <<%%>> must specify a position.

	o <[flags]>

	<[flags]> is an optional sequence of characters which control
	output justification, numeric signs, decimal points, trailing
	zeros, and octal and hex prefixes.  The flag characters are
	minus (<<->>), plus (<<+>>), space ( ), zero (<<0>>), sharp
	(<<#>>), and quote (<<'>>).  They can appear in any
	combination, although not all flags can be used for all
	conversion specification types.

		o+
		o '
			Since newlib only supports the C locale, this
			flag has no effect in this implementation.
			But in other locales, when <[type]> is <<i>>,
			<<d>>, <<u>>, <<f>>, <<F>>, <<g>>, or <<G>>,
			the locale-dependent thousand's separator is
			inserted prior to zero padding.

		o -
			The result of the conversion is left
			justified, and the right is padded with
			blanks.  If you do not use this flag, the
			result is right justified, and padded on the
			left.

	        o +
			The result of a signed conversion (as
			determined by <[type]> of <<d>>, <<i>>, <<a>>,
			<<A>>, <<e>>, <<E>>, <<f>>, <<F>>, <<g>>, or
			<<G>>) will always begin with a plus or minus
			sign.  (If you do not use this flag, positive
			values do not begin with a plus sign.)

		o " " (space)
			If the first character of a signed conversion
		        specification is not a sign, or if a signed
		        conversion results in no characters, the
		        result will begin with a space.  If the space
		        ( ) flag and the plus (<<+>>) flag both
		        appear, the space flag is ignored.

	        o 0
			If the <[type]> character is <<d>>, <<i>>,
			<<o>>, <<u>>, <<x>>, <<X>>, <<a>>, <<A>>,
			<<e>>, <<E>>, <<f>>, <<g>>, or <<G>>: leading
			zeros are used to pad the field width
			(following any indication of sign or base); no
			spaces are used for padding.  If the zero
			(<<0>>) and minus (<<->>) flags both appear,
			the zero (<<0>>) flag will be ignored.  For
			<<d>>, <<i>>, <<o>>, <<u>>, <<x>>, and <<X>>
			conversions, if a precision <[prec]> is
			specified, the zero (<<0>>) flag is ignored.

			Note that <<0>> is interpreted as a flag, not
		        as the beginning of a field width.

	        o #
			The result is to be converted to an
			alternative form, according to the <[type]>
			character:

			o+
			o o
				Increases precision to force the first
				digit of the result to be a zero.

			o x
				A non-zero result will have a <<0x>>
				prefix.

			o X
				A non-zero result will have a <<0X>>
				prefix.

			o a, A, e, E, f, or F
				The result will always contain a
			        decimal point even if no digits follow
			        the point.  (Normally, a decimal point
			        appears only if a digit follows it.)
			        Trailing zeros are removed.

			o g or G
				The result will always contain a
			        decimal point even if no digits follow
			        the point.  Trailing zeros are not
			        removed.

			o all others
				Undefined.

			o-
		o-

	o <[width]>

		<[width]> is an optional minimum field width.  You can
		either specify it directly as a decimal integer, or
		indirectly by using instead an asterisk (<<*>>), in
		which case an <<int>> argument is used as the field
		width.  If positional arguments are used, then the
		width must also be specified positionally as <<*m$>>,
		with m as a decimal integer.  Negative field widths
		are treated as specifying the minus (<<->>) flag for
		left justfication, along with a positive field width.
		The resulting format may be wider than the specified
		width.

	o <[prec]>

		<[prec]> is an optional field; if present, it is
		introduced with `<<.>>' (a period). You can specify
		the precision either directly as a decimal integer or
		indirectly by using an asterisk (<<*>>), in which case
		an <<int>> argument is used as the precision.  If
		positional arguments are used, then the precision must
		also be specified positionally as <<*m$>>, with m as a
		decimal integer.  Supplying a negative precision is
		equivalent to omitting the precision.  If only a
		period is specified the precision is zero. The effect
		depends on the conversion <[type]>.

		o+
		o d, i, o, u, x, or X
			Minimum number of digits to appear.  If no
			precision is given, defaults to 1.

		o a or A
			Number of digits to appear after the decimal
			point.  If no precision is given, the
			precision defaults to the minimum needed for
			an exact representation.

		o e, E, f or F
			Number of digits to appear after the decimal
			point.  If no precision is given, the
			precision defaults to 6.

		o g or G
			Maximum number of significant digits.  A
			precision of 0 is treated the same as a
			precision of 1.  If no precision is given, the
			precision defaults to 6.

		o s or S
			Maximum number of characters to print from the
			string.  If no precision is given, the entire
			string is printed.

		o all others
			undefined.

		o-

	o <[size]>

		<[size]> is an optional modifier that changes the data
		type that the corresponding argument has.  Behavior is
		unspecified if a size is given that does not match the
		<[type]>.

		o+
		o hh
			With <<d>>, <<i>>, <<o>>, <<u>>, <<x>>, or
			<<X>>, specifies that the argument should be
			converted to a <<signed char>> or <<unsigned
			char>> before printing.

			With <<n>>, specifies that the argument is a
			pointer to a <<signed char>>.

		o h
			With <<d>>, <<i>>, <<o>>, <<u>>, <<x>>, or
			<<X>>, specifies that the argument should be
			converted to a <<short>> or <<unsigned short>>
			before printing.

			With <<n>>, specifies that the argument is a
			pointer to a <<short>>.

		o l
			With <<d>>, <<i>>, <<o>>, <<u>>, <<x>>, or
			<<X>>, specifies that the argument is a
			<<long>> or <<unsigned long>>.

			With <<c>>, specifies that the argument has
			type <<wint_t>>.

			With <<s>>, specifies that the argument is a
			pointer to <<wchar_t>>.

			With <<n>>, specifies that the argument is a
			pointer to a <<long>>.

			With <<a>>, <<A>>, <<e>>, <<E>>, <<f>>, <<F>>,
			<<g>>, or <<G>>, has no effect (because of
			vararg promotion rules, there is no need to
			distinguish between <<float>> and <<double>>).

		o ll
			With <<d>>, <<i>>, <<o>>, <<u>>, <<x>>, or
			<<X>>, specifies that the argument is a
			<<long long>> or <<unsigned long long>>.

			With <<n>>, specifies that the argument is a
			pointer to a <<long long>>.

		o j
			With <<d>>, <<i>>, <<o>>, <<u>>, <<x>>, or
			<<X>>, specifies that the argument is an
			<<intmax_t>> or <<uintmax_t>>.

			With <<n>>, specifies that the argument is a
			pointer to an <<intmax_t>>.

		o z
			With <<d>>, <<i>>, <<o>>, <<u>>, <<x>>, or
			<<X>>, specifies that the argument is a
			<<ssize_t>> or <<size_t>>.

			With <<n>>, specifies that the argument is a
			pointer to a <<ssize_t>>.

		o t
			With <<d>>, <<i>>, <<o>>, <<u>>, <<x>>, or
			<<X>>, specifies that the argument is a
			<<ptrdiff_t>>.

			With <<n>>, specifies that the argument is a
			pointer to a <<ptrdiff_t>>.

		o L
			With <<a>>, <<A>>, <<e>>, <<E>>, <<f>>, <<F>>,
			<<g>>, or <<G>>, specifies that the argument
			is a <<long double>>.

		o-

	o   <[type]>

		<[type]> specifies what kind of conversion <<printf>>
		performs.  Here is a table of these:

		o+
		o %
			Prints the percent character (<<%>>).

		o c
			Prints <[arg]> as single character.  If the
			<<l>> size specifier is in effect, a multibyte
			character is printed.

		o C
			Short for <<%lc>>.

		o s
			Prints the elements of a pointer to <<char>>
			until the precision or a null character is
			reached.  If the <<l>> size specifier is in
			effect, the pointer is to an array of
			<<wchar_t>>, and the string is converted to
			multibyte characters before printing.

		o S
			Short for <<%ls>>.

		o d or i
			Prints a signed decimal integer; takes an
			<<int>>.  Leading zeros are inserted as
			necessary to reach the precision.  A precision
			of 0 produces an empty string.

		o D
			Newlib extension, short for <<%ld>>.

		o o
			Prints an unsigned octal integer; takes an
			<<unsigned>>.  Leading zeros are inserted as
			necessary to reach the precision.  A precision
			of 0 produces an empty string.

		o O
			Newlib extension, short for <<%lo>>.

		o u
			Prints an unsigned decimal integer; takes an
			<<unsigned>>.  Leading zeros are inserted as
			necessary to reach the precision.  A precision
			of 0 produces an empty string.

		o U
			Newlib extension, short for <<%lu>>.

		o x
			Prints an unsigned hexadecimal integer (using
			<<abcdef>> as digits beyond <<9>>); takes an
			<<unsigned>>.  Leading zeros are inserted as
			necessary to reach the precision.  A precision
			of 0 produces an empty string.

		o X
			Like <<x>>, but uses <<ABCDEF>> as digits
			beyond <<9>>.

		o f
			Prints a signed value of the form
			<<[-]9999.9999>>, with the precision
			determining how many digits follow the decimal
			point; takes a <<double>> (remember that
			<<float>> promotes to <<double>> as a vararg).
			The low order digit is rounded to even.  If
			the precision results in at most DECIMAL_DIG
			digits, the result is rounded correctly; if
			more than DECIMAL_DIG digits are printed, the
			result is only guaranteed to round back to the
			original value.

			If the value is infinite, the result is
			<<inf>>, and no zero padding is performed.  If
			the value is not a number, the result is
			<<nan>>, and no zero padding is performed.

		o F
			Like <<f>>, but uses <<INF>> and <<NAN>> for
			non-finite numbers.

		o e
			Prints a signed value of the form
			<<[-]9.9999e[+|-]999>>; takes a <<double>>.
			The digit before the decimal point is non-zero
			if the value is non-zero.  The precision
			determines how many digits appear between
			<<.>> and <<e>>, and the exponent always
			contains at least two digits.  The value zero
			has an exponent of zero.  If the value is not
			finite, it is printed like <<f>>.

		o E
			Like <<e>>, but using <<E>> to introduce the
			exponent, and like <<F>> for non-finite
			values.

		o g
			Prints a signed value in either <<f>> or <<e>>
			form, based on the given value and
			precision---an exponent less than -4 or
			greater than the precision selects the <<e>>
			form.  Trailing zeros and the decimal point
			are printed only if necessary; takes a
			<<double>>.

		o G
			Like <<g>>, except use <<F>> or <<E>> form.

		o a
			Prints a signed value of the form
			<<[-]0x1.ffffp[+|-]9>>; takes a <<double>>.
			The letters <<abcdef>> are used for digits
			beyond <<9>>.  The precision determines how
			many digits appear after the decimal point.
			The exponent contains at least one digit, and
			is a decimal value representing the power of
			2; a value of 0 has an exponent of 0.
			Non-finite values are printed like <<f>>.

		o A
			Like <<a>>, except uses <<X>>, <<P>>, and
			<<ABCDEF>> instead of lower case.

		o n
			Takes a pointer to <<int>>, and stores a count
			of the number of bytes written so far.  No
			output is created.

		o p
			Takes a pointer to <<void>>, and prints it in
			an implementation-defined format.  This
			implementation is similar to <<%#tx>>), except
			that <<0x>> appears even for the NULL pointer.

		o-
	O-

        <<_printf_r>>, <<_fprintf_r>>, <<_asprintf_r>>,
        <<_sprintf_r>>, <<_snprintf_r>>, <<_asnprintf_r>> are simply
        reentrant versions of the functions above.

RETURNS
On success, <<sprintf>> and <<asprintf>> return the number of bytes in
the output string, except the concluding <<NUL>> is not counted.
<<snprintf>> returns the number of bytes that would be in the output
string, except the concluding <<NUL>> is not counted.  <<printf>> and
<<fprintf>> return the number of characters transmitted.
<<asnprintf>> returns the original <[str]> if there was enough room,
otherwise it returns an allocated string.

If an error occurs, the result of <<printf>>, <<fprintf>>,
<<snprintf>>, and <<asprintf>> is a negative value, and the result of
<<asnprintf>> is NULL.  No error returns occur for <<sprintf>>.  For
<<printf>> and <<fprintf>>, <<errno>> may be set according to
<<fputc>>.  For <<asprintf>> and <<asnprintf>>, <<errno>> may be set
to ENOMEM if allocation fails, and for <<snprintf>>, <<errno>> may be
set to EOVERFLOW if <[size]> or the output length exceeds INT_MAX.

PORTABILITY
ANSI C requires <<printf>>, <<fprintf>>, <<sprintf>>, and
<<snprintf>>.  <<asprintf>> and <<asnprintf>> are newlib extensions.

The ANSI C standard specifies that implementations must support at
least formatted output of up to 509 characters.  This implementation
has no inherent limit.

Depending on how newlib was configured, not all format specifiers are
supported.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/

#include <_ansi.h>
#include <reent.h>
#include <stdio.h>
#ifdef _HAVE_STDC
#include <stdarg.h>
#else
#include <varargs.h>
#endif
#include <limits.h>
#include "local.h"

int
#ifdef _HAVE_STDC
_DEFUN(_sprintf_r, (ptr, str, fmt),
       struct _reent *ptr _AND
       char *str          _AND
       _CONST char *fmt _DOTS)
#else
_sprintf_r(ptr, str, fmt, va_alist)
           struct _reent *ptr;
           char *str;
           _CONST char *fmt;
           va_dcl
#endif
{
  int ret;
  va_list ap;
  FILE f;

  f._flags = __SWR | __SSTR;
  f._bf._base = f._p = (unsigned char *) str;
  f._bf._size = f._w = INT_MAX;
  f._file = -1;  /* No file. */
#ifdef _HAVE_STDC
  va_start (ap, fmt);
#else
  va_start (ap);
#endif
  ret = _vfprintf_r (ptr, &f, fmt, ap);
  va_end (ap);
  *f._p = 0;
  return (ret);
}

#ifndef _REENT_ONLY

int
#ifdef _HAVE_STDC
_DEFUN(sprintf, (str, fmt),
       char *str _AND
       _CONST char *fmt _DOTS)
#else
sprintf(str, fmt, va_alist)
        char *str;
        _CONST char *fmt;
        va_dcl
#endif
{
  int ret;
  va_list ap;
  FILE f;

  f._flags = __SWR | __SSTR;
  f._bf._base = f._p = (unsigned char *) str;
  f._bf._size = f._w = INT_MAX;
  f._file = -1;  /* No file. */
#ifdef _HAVE_STDC
  va_start (ap, fmt);
#else
  va_start (ap);
#endif
  ret = _vfprintf_r (_REENT, &f, fmt, ap);
  va_end (ap);
  *f._p = 0;
  return (ret);
}

#endif
