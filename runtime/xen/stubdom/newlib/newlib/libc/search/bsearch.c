/*
 * bsearch.c
 * Original Author:	G. Haley
 * Rewritten by:	G. Noer
 *
 * Searches an array of nmemb members, the initial member of which is pointed
 * to by base, for a member that matches the object pointed to by key. The
 * contents of the array shall be in ascending order according to a comparison
 * function pointed to by compar. The function shall return an integer less
 * than, equal to or greater than zero if the first argument is considered to be
 * respectively less than, equal to or greater than the second. Returns a
 * pointer to the matching member of the array, or a null pointer if no match
 * is found.
 */

/*
FUNCTION
<<bsearch>>---binary search

INDEX
	bsearch

ANSI_SYNOPSIS
	#include <stdlib.h>
	void *bsearch(const void *<[key]>, const void *<[base]>,
		size_t <[nmemb]>, size_t <[size]>,
		int (*<[compar]>)(const void *, const void *));

TRAD_SYNOPSIS
	#include <stdlib.h>
	char *bsearch(<[key]>, <[base]>, <[nmemb]>, <[size]>, <[compar]>)
	char *<[key]>;
	char *<[base]>;
	size_t <[nmemb]>, <[size]>;
	int (*<[compar]>)();

DESCRIPTION
<<bsearch>> searches an array beginning at <[base]> for any element
that matches <[key]>, using binary search.  <[nmemb]> is the element
count of the array; <[size]> is the size of each element.

The array must be sorted in ascending order with respect to the
comparison function <[compar]> (which you supply as the last argument of
<<bsearch>>).

You must define the comparison function <<(*<[compar]>)>> to have two
arguments; its result must be negative if the first argument is
less than the second, zero if the two arguments match, and
positive if the first argument is greater than the second (where
``less than'' and ``greater than'' refer to whatever arbitrary
ordering is appropriate).

RETURNS
Returns a pointer to an element of <[array]> that matches <[key]>.  If
more than one matching element is available, the result may point to
any of them.

PORTABILITY
<<bsearch>> is ANSI.

No supporting OS subroutines are required.
*/

#include <stdlib.h>

_PTR
_DEFUN (bsearch, (key, base, nmemb, size, compar),
	_CONST _PTR key _AND
	_CONST _PTR base _AND
	size_t nmemb _AND
	size_t size _AND
	int _EXFUN ((*compar), (const _PTR, const _PTR)))
{
  _PTR current;
  size_t lower = 0;
  size_t upper = nmemb;
  size_t index;
  int result;

  if (nmemb == 0 || size == 0)
    return NULL;

  while (lower < upper)
    {
      index = (lower + upper) / 2;
      current = (_PTR) (((char *) base) + (index * size));

      result = compar (key, current);

      if (result < 0)
        upper = index;
      else if (result > 0)
        lower = index + 1;
      else
	return current;
    }

  return NULL;
}

