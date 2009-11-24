/*
FUNCTION
<<rand>>, <<srand>>---pseudo-random numbers

INDEX
	rand
INDEX
	srand
INDEX
	rand_r

ANSI_SYNOPSIS
	#include <stdlib.h>
	int rand(void);
	void srand(unsigned int <[seed]>);
	int rand_r(unsigned int *<[seed]>);

TRAD_SYNOPSIS
	#include <stdlib.h>
	int rand();

	void srand(<[seed]>)
	unsigned int <[seed]>;

	void rand_r(<[seed]>)
	unsigned int *<[seed]>;


DESCRIPTION
<<rand>> returns a different integer each time it is called; each
integer is chosen by an algorithm designed to be unpredictable, so
that you can use <<rand>> when you require a random number.
The algorithm depends on a static variable called the ``random seed'';
starting with a given value of the random seed always produces the
same sequence of numbers in successive calls to <<rand>>.

You can set the random seed using <<srand>>; it does nothing beyond
storing its argument in the static variable used by <<rand>>.  You can
exploit this to make the pseudo-random sequence less predictable, if
you wish, by using some other unpredictable value (often the least
significant parts of a time-varying value) as the random seed before
beginning a sequence of calls to <<rand>>; or, if you wish to ensure
(for example, while debugging) that successive runs of your program
use the same ``random'' numbers, you can use <<srand>> to set the same
random seed at the outset.

RETURNS
<<rand>> returns the next pseudo-random integer in sequence; it is a
number between <<0>> and <<RAND_MAX>> (inclusive).

<<srand>> does not return a result.

NOTES
<<rand>> and <<srand>> are unsafe for multi-threaded applications.
<<rand_r>> is thread-safe and should be used instead.


PORTABILITY
<<rand>> is required by ANSI, but the algorithm for pseudo-random
number generation is not specified; therefore, even if you use
the same random seed, you cannot expect the same sequence of results
on two different systems.

<<rand>> requires no supporting OS subroutines.
*/

#ifndef _REENT_ONLY

#include <stdlib.h>
#include <reent.h>

void
_DEFUN (srand, (seed), unsigned int seed)
{
  _REENT_CHECK_RAND48(_REENT);
  _REENT_RAND_NEXT(_REENT) = seed;
}

int
_DEFUN_VOID (rand)
{
  /* This multiplier was obtained from Knuth, D.E., "The Art of
     Computer Programming," Vol 2, Seminumerical Algorithms, Third
     Edition, Addison-Wesley, 1998, p. 106 (line 26) & p. 108 */
  _REENT_CHECK_RAND48(_REENT);
  _REENT_RAND_NEXT(_REENT) = 
     _REENT_RAND_NEXT(_REENT) * __extension__ 6364136223846793005LL + 1;
  return (int)((_REENT_RAND_NEXT(_REENT) >> 32) & RAND_MAX);
}

#endif /* _REENT_ONLY */
