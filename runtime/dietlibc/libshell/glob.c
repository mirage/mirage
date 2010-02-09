/*
 * dietlibc/libshell/glob.c
 *
 * Copyright 2001 Guillaume Cottenceau <gc@mandrakesoft.com>
 *
 * This is free software, licensed under the Gnu General Public License.
 *
 */

/*
 * unsupported: GLOB_BRACE GLOB_ALTDIRFUNC GLOB_MAGCHAR
 */

#define DEBUG(x)

#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <assert.h>
#include <fnmatch.h>
#include <dirent.h>
#include <pwd.h>
#include "dietfeatures.h"

#include <glob.h>



/* If i18n, should be using strcoll */
static int cmp_func(const void * a, const void * b)
{
	const char *const s1 = *(const char *const * const) a;
	const char *const s2 = *(const char *const * const) b;
	if (s1 == NULL)
		return 1;
	if (s2 == NULL)
		return -1;
	return strcoll(s1, s2);
}


/* Like `glob', but PATTERN is a final pathname component,
   and matches are searched for in DIRECTORY.
   The GLOB_NOSORT bit in FLAGS is ignored.  No sorting is ever done.
   The GLOB_APPEND flag is assumed to be set (always appends).
   Prepends DIRECTORY in constructed PGLOB. */
static void close_dir_keep_errno(DIR* dp) {
  int save = errno;
  if (dp)
    closedir (dp);
  errno=save;
}

static int add_entry(const char* name,glob_t *pglob,int* nfound) {
  pglob->gl_pathv	= (char **) realloc(pglob->gl_pathv,
			  (pglob->gl_pathc + pglob->gl_offs + 2)
			  * sizeof (char *));
  if (pglob->gl_pathv == NULL)
    return 1;
  pglob->gl_pathv[pglob->gl_offs + pglob->gl_pathc] = strdup(name);
  pglob->gl_pathv[pglob->gl_offs + pglob->gl_pathc + 1] = NULL;
  pglob->gl_pathc++;
  (*nfound)++;
  return 0;
}

static void build_fullname(char * fullname, const char * directory, const char * filename) {
  char *dest=fullname;
  if (directory[0]=='/' && !directory[1]) {
    *dest='/'; ++dest;
  } else if (directory[0]!='.' || directory[1]) {
    strcpy(dest,directory);
    dest=strchr(dest,0);
    *dest='/'; ++dest;
  }
  strcpy(dest,filename);
}

static int glob_in_dir(const char *pattern, const char *directory, int flags,
		       int errfunc(const char * epath, int eerrno),
		       glob_t *pglob)
{
	DIR *dp = opendir(directory);
	int nfound = 0;

	int i;
	char * ptr;

	if (!dp) {
		if (errno != ENOTDIR
		    && ((errfunc != NULL && (*errfunc) (directory, errno))
			|| (flags & GLOB_ERR)))
		      return GLOB_ABORTED;
	} else {
		int fnm_flags = ((!(flags & GLOB_PERIOD) ? FNM_PERIOD : 0)
				 | ((flags & GLOB_NOESCAPE) ? FNM_NOESCAPE : 0));
		struct dirent *ep;
		while ((ep = readdir(dp))) {
			i = strlen(directory) + strlen(ep->d_name) + 2;
			ptr = (char *) alloca(i);
			build_fullname(ptr, directory, ep->d_name);
			if (flags & GLOB_ONLYDIR) {
				struct stat statr;
				if (stat(ptr, &statr) || !S_ISDIR(statr.st_mode))
					continue;
			}
			if (fnmatch(pattern, ep->d_name, fnm_flags) == 0)
				if (add_entry(ptr,pglob,&nfound))
					goto memory_error;
		}
	}

	close_dir_keep_errno(dp);

	if (nfound != 0)
		pglob->gl_flags = flags;
	else if (flags & GLOB_NOCHECK) {
		/* nfound == 0 */
		i = strlen(directory) + strlen(pattern) + 2;
		ptr = (char *) alloca(i);
		build_fullname(ptr, directory, pattern);
		if (add_entry(ptr,pglob,&nfound))
			goto memory_error;
	}

	return (nfound == 0) ? GLOB_NOMATCH : 0;

 memory_error:
	/* We're in trouble since we can't free the already allocated memory. [allocated from strdup(filame)]
	 * Well, after all, when malloc returns NULL we're already in a bad mood, and no doubt the
	 * program will manage to segfault by itself very soon :-). */
	close_dir_keep_errno(dp);
	return GLOB_NOSPACE;
}



int glob(const char *pattern, int flags, int errfunc(const char * epath, int eerrno), glob_t *pglob)
{
	char * pattern_;
	char * filename;
	char * dirname;
	size_t oldcount;
	struct stat statr;

	size_t i; /* tmp variables are declared here to save a bit of object space */
	int j, k;    /* */
	char * ptr, * ptr2;

	if (pattern == NULL || pglob == NULL || (flags & ~__GLOB_FLAGS) != 0) {
		errno=EINVAL;
		return -1;
	}

	if (!(flags & GLOB_DOOFFS))
		pglob->gl_offs = 0;


	/* Duplicate pattern so I can make modif to it later (to handle
           TILDE stuff replacing old contents, and to null-terminate the
           directory) */
	pattern_ = alloca(strlen(pattern) + 1);
	strcpy(pattern_, pattern);

	/* Check for TILDE stuff */
	if ((flags & (GLOB_TILDE|GLOB_TILDE_CHECK)) && pattern_[0] == '~') {
		char * home_dir = NULL;
		if (pattern_[1] == '\0' || pattern_[1] == '/') {
			/* She's asking for ~, her homedir */
			home_dir = getenv("HOME");
		} else {
			/* She's asking for another one's homedir */
			struct passwd * p;
			ptr2 = alloca(strlen(pattern_) + 1);
			strcpy(ptr2, pattern_ + 1);
			ptr = strchr(ptr2, '/');
			if (ptr != NULL)
				*ptr = '\0';
			if (((p = getpwnam(ptr2)) != NULL))
				home_dir = p->pw_dir;
		}
		if (home_dir != NULL) {
			i = strlen(home_dir) + strlen(pattern_); /* pessimistic (the ~ case) */
			ptr = alloca(i);
			strncpy(ptr, home_dir, i);
			ptr2 = pattern_ + 1;
			while (*ptr2 != '/' && *ptr2 != '\0')
				ptr2++;
			strncat(ptr, ptr2, i);
			pattern_ = ptr;
		} else if (flags & GLOB_TILDE_CHECK)
			return GLOB_NOMATCH;
	}

	/* Find the filename */
	filename = strrchr(pattern_, '/');

	if (filename == NULL) {
		/* We have no '/' in the pattern */
		filename = pattern_;
		dirname = (char*)".";
	} else if (filename == pattern_) {
		/* "/pattern".  */
		dirname = (char*)"/";
		filename++;
	} else {
		dirname = pattern_;
		filename++;
		/* allow dirname to be null terminated */
		*(filename-1) = '\0';

		if (filename[0] == '\0' && strcmp(pattern_, "/")) {
			/* "pattern/".  Expand "pattern", appending slashes.  */
			j = glob(dirname, flags | GLOB_MARK, errfunc, pglob);
			if (j == 0)
				pglob->gl_flags = ((pglob->gl_flags & ~GLOB_MARK)
						   | (flags & GLOB_MARK));
			return j;
		}
	}

	
	/* Reserve memory for pglob */
	if (!(flags & GLOB_APPEND)) {
		pglob->gl_pathc = 0;
		if (!(flags & GLOB_DOOFFS))
			pglob->gl_pathv = NULL;
		else {
			pglob->gl_pathv = (char **) malloc((pglob->gl_offs + 1) * sizeof (char *));
			if (pglob->gl_pathv == NULL)
				return GLOB_NOSPACE;
			for (i = 0; i <= pglob->gl_offs; i++)
				pglob->gl_pathv[i] = NULL;
		}
	}


	oldcount = pglob->gl_pathc + pglob->gl_offs;


	/* Begin real work */
	if (!strcmp(dirname, "/") || !strcmp(dirname, ".")
	    || (!strchr(dirname, '*') && !strchr(dirname, '?') && !strchr(dirname, '['))) {
		/* Approx of a terminal state, glob directly in dir. */
		j = glob_in_dir(filename, dirname, flags, errfunc, pglob);
		if (j != 0)
			return j;
	} else {
		/* We are not in a terminal state, so we have to glob for
		   the directory, and then glob for the pattern in each
		   directory found. */
		glob_t dirs;

		j = glob(dirname, ((flags & (GLOB_ERR | GLOB_NOCHECK | GLOB_NOESCAPE | GLOB_ALTDIRFUNC))
				   | GLOB_NOSORT | GLOB_ONLYDIR),
			 errfunc, &dirs);
		if (j != 0)
			return j;

		/* We have successfully globbed the directory name.
		   For each name we found, call glob_in_dir on it and FILENAME,
		   appending the results to PGLOB.  */
		for (i = 0; i < dirs.gl_pathc; i++) {
			j = glob_in_dir(filename, dirs.gl_pathv[i], ((flags | GLOB_APPEND) & ~GLOB_NOCHECK),
					errfunc, pglob);
			if (j == GLOB_NOMATCH)
				/* No matches in this directory.  Try the next.  */
				continue;
			if (j != 0) {
				globfree(&dirs);
				globfree(pglob);
				return j;
			}
		}

		/* We have ignored the GLOB_NOCHECK flag in the `glob_in_dir' calls.
		   But if we have not found any matching entry and the GLOB_NOCHECK
		   flag was set we must return the list consisting of the disrectory
		   names followed by the filename.  */
		if (pglob->gl_pathc + pglob->gl_offs == oldcount)
		{
			/* No matches.  */
			if (flags & GLOB_NOCHECK)
			{
				for (i = 0; i < dirs.gl_pathc; i++) {
					if (stat(dirs.gl_pathv[i], &statr) || !S_ISDIR(statr.st_mode))
						continue;

					/* stat is okay, we will add the entry, but before let's resize the pathv */
					j = pglob->gl_pathc + pglob->gl_offs;
					pglob->gl_pathv = (char **) realloc(pglob->gl_pathv, (j + 2) * sizeof (char *));
					if (pglob->gl_pathv == NULL) {
						globfree (&dirs);
						return GLOB_NOSPACE;
					}

					/* okay now we add the new entry */
					k = strlen(dirs.gl_pathv[i]) + strlen(filename) + 2;
					if ((pglob->gl_pathv[j] = malloc(k)) == NULL) {
						globfree(&dirs);
						globfree(pglob);
						return GLOB_NOSPACE;
					}
					build_fullname(pglob->gl_pathv[j], dirs.gl_pathv[i], filename);
					pglob->gl_pathc++;
					pglob->gl_pathv[j+1] = NULL;
				}
			} else {
				globfree(&dirs);
				return GLOB_NOMATCH;
			}
		}

		globfree (&dirs);
	}


	if (flags & GLOB_MARK) {
		for (i = oldcount; i < pglob->gl_pathc + pglob->gl_offs; i++)
			if (!stat(pglob->gl_pathv[i], &statr) && S_ISDIR(statr.st_mode)) {
				size_t len = strlen(pglob->gl_pathv[i]) + 2;
				ptr = realloc(pglob->gl_pathv[i], len);
				if (ptr == NULL) {
					globfree(pglob);
					return GLOB_NOSPACE;
				}
				strcpy(&ptr[len - 2], "/");
				pglob->gl_pathv[i] = ptr;
			}
	}

	if (!(flags & GLOB_NOSORT)) {
		qsort(&pglob->gl_pathv[oldcount],
		      pglob->gl_pathc + pglob->gl_offs - oldcount,
		      sizeof(char *), cmp_func);
	}

	return 0;
}


/* Free storage allocated in PGLOB by a previous `glob' call.  */
void globfree (glob_t * pglob)
{
  if (pglob->gl_pathv != NULL) {
      size_t i;
      for (i = 0; i < pglob->gl_pathc; i++)
	      if (pglob->gl_pathv[pglob->gl_offs + i] != NULL)
		      free((void *) pglob->gl_pathv[pglob->gl_offs + i]);
      free((void *) pglob->gl_pathv);
  }
}
