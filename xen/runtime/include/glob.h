#ifndef _GLOB_H
#define _GLOB_H

#include <sys/cdefs.h>
#include <sys/types.h>

__BEGIN_DECLS

typedef struct {
	size_t gl_pathc;    /* Count of paths matched so far  */
	char **gl_pathv;    /* List of matched pathnames.  */
	size_t gl_offs;     /* Slots to reserve in `gl_pathv'.  */
	int gl_flags;		/* Set to FLAGS, maybe | GLOB_MAGCHAR.  */
} glob_t;


int glob(const char *pattern, int flags,
	 int errfunc(const char * epath, int eerrno),
	 glob_t *pglob) __THROW;

void globfree(glob_t *pglob) __THROW;



/* Bits set in the FLAGS argument to `glob'.  */
#define	GLOB_ERR	(1 << 0)/* Return on read errors.  */
#define	GLOB_MARK	(1 << 1)/* Append a slash to each name.  */
#define	GLOB_NOSORT	(1 << 2)/* Don't sort the names.  */
#define	GLOB_DOOFFS	(1 << 3)/* Insert PGLOB->gl_offs NULLs.  */
#define	GLOB_NOCHECK	(1 << 4)/* If nothing matches, return the pattern.  */
#define	GLOB_APPEND	(1 << 5)/* Append to results of a previous call.  */
#define	GLOB_NOESCAPE	(1 << 6)/* Backslashes don't quote metacharacters.  */
#define	GLOB_PERIOD	(1 << 7)/* Leading `.' can be matched by metachars.  */

#define GLOB_MAGCHAR	 (1 << 8)/* Set in gl_flags if any metachars seen.  */
#define GLOB_ALTDIRFUNC  (1 << 9)/* Use gl_opendir et al functions.  */
#define GLOB_BRACE	 (1 << 10)/* Expand "{a,b}" to "a" "b".  */
#define GLOB_NOMAGIC	 (1 << 11)/* If no magic chars, return the pattern.  */
#define GLOB_TILDE	 (1 << 12)/* Expand ~user and ~ to home directories. */
#define GLOB_ONLYDIR	 (1 << 13)/* Match only directories.  */
#define GLOB_TILDE_CHECK (1 << 14)/* Like GLOB_TILDE but return an error
				      if the user name is not available.  */
#define __GLOB_FLAGS	(GLOB_ERR|GLOB_MARK|GLOB_NOSORT|GLOB_DOOFFS| \
			 GLOB_NOESCAPE|GLOB_NOCHECK|GLOB_APPEND|     \
			 GLOB_PERIOD|GLOB_ALTDIRFUNC|GLOB_BRACE|     \
			 GLOB_NOMAGIC|GLOB_TILDE|GLOB_ONLYDIR|GLOB_TILDE_CHECK)


/* Error returns from `glob'.  */
#define	GLOB_NOSPACE	1	/* Ran out of memory.  */
#define	GLOB_ABORTED	2	/* Read error.  */
#define	GLOB_NOMATCH	3	/* No matches found.  */
#define GLOB_NOSYS	4	/* Not implemented.  */
/* Previous versions of this file defined GLOB_ABEND instead of
   GLOB_ABORTED.  Provide a compatibility definition here.  */
#define GLOB_ABEND GLOB_ABORTED

__END_DECLS

#endif
