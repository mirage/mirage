/* Test program for returning the canonical absolute name of a given file.
   Copyright (C) 1996, 1997, 2000, 2002 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by David Mosberger <davidm@azstarnet.com>.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
   02111-1307 USA.  */

/* This file must be run from within a directory called "stdlib".  */

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/param.h>

#define myrealpath realpath
static char	cwd[PATH_MAX];
static size_t	cwd_len;

struct {
  const char *	name;
  const char *	value;
} symlinks[] = {
  {"SYMLINK_LOOP",	"SYMLINK_LOOP"},
  {"SYMLINK_1",		"."},
  {"SYMLINK_2",		"//////./../../etc"},
  {"SYMLINK_3",		"SYMLINK_1"},
  {"SYMLINK_4",		"SYMLINK_2"},
  {"SYMLINK_5",		"doesNotExist"},
};

struct {
  const char * in, * out, *resolved;
  int error;
} tests[] = {
  /*  0 */
  {"/",					"/", "", 0},
  {"/////////////////////////////////",	"/", "" ,0},
  {"/.././.././.././..///",		"/", "",0},
  {"/etc",				"/etc", "",0},
  {"/etc/../etc",			"/etc", "",0},
  /*  5 */
  {"/doesNotExist/../etc",		0, "/doesNotExist", ENOENT},
  {"./././././././././.",		".", "",0},
  {"/etc/.//doesNotExist",		0, "/etc/doesNotExist", ENOENT},
  {"./doesExist",			"./doesExist", "",0},
  {"./doesExist/",			"./doesExist", "",0},
  /* 10 */
  {"./doesExist/../doesExist",		"./doesExist","",0},
  {"foobar",				0, "./foobar", ENOENT},
  {".",					".","",0},
  {"./foobar",				0, "./foobar", ENOENT},
  {"SYMLINK_LOOP",			0, "./SYMLINK_LOOP", ELOOP},
  /* 15 */
  {"./SYMLINK_LOOP",			0, "./SYMLINK_LOOP", ELOOP},
  {"SYMLINK_1",				".","",0},
  {"SYMLINK_1/foobar",			0, "./foobar", ENOENT},
  {"SYMLINK_2",				"/etc","",0},
  {"SYMLINK_3",				".","",0},
  /* 20 */
  {"SYMLINK_4",				"/etc","",0},
  {"../stdlib/SYMLINK_1",		".","",0},
  {"../stdlib/SYMLINK_2",		"/etc","",0},
  {"../stdlib/SYMLINK_3",		".","",0},
  {"../stdlib/SYMLINK_4",		"/etc","",0},
  /* 25 */
  {"./SYMLINK_5",			0, "./doesNotExist", ENOENT},
  {"SYMLINK_5",				0, "./doesNotExist", ENOENT},
  {"SYMLINK_5/foobar",			0, "./doesNotExist", ENOENT},
  {"doesExist/../../stdlib/doesExist",	"./doesExist","",0},
  {"doesExist/.././../stdlib/.",	".","",0}
};


static int
check_path (const char * result, const char * expected)
{
  int good;

  if (!result)
    return (expected == NULL);

  if (!expected)
    return 0;

  if (expected[0] == '.' && (expected[1] == '/' || expected[1] == '\0'))
    good = (strncmp (result, cwd, cwd_len) == 0
	    && strcmp (result + cwd_len, expected + 1) == 0);
  else
    good = (strcmp (expected, result) == 0);

  return good;
}


int
main (int argc, char ** argv)
{
  char * result;
  int fd, i, errors = 0;
  char buf[PATH_MAX];

  getcwd (cwd, sizeof(buf));
  cwd_len = strlen (cwd);

/* this segfaults with dietlibc 
man page documents:
  EINVAL Either path or resolved_path is NULL. (In libc5 this would  just
                cause a segfault.)
  errno = 0;
  if (myrealpath (NULL, buf) != NULL || errno != EINVAL)
    {
      printf ("%s: expected return value NULL and errno set to EINVAL"
	      " for myrealpath(NULL,...)\n", argv[0]);
      ++errors;
    }
*/   

/* according to glibc, this test is invalid 
  errno = 0;
  if (myrealpath ("/", NULL) != NULL || errno != EINVAL)
    {
      printf ("%s: expected return value NULL and errno set to EINVAL"
	      " for myrealpath(...,NULL)\n", argv[0]);
      ++errors;
    }
*/    

  errno = 0;
  if (myrealpath ("", buf) != NULL || errno != ENOENT)
    {
      printf ("%s: expected return value NULL and set errno to ENOENT"
	      " for myrealpath(\"\",...)\n", argv[0]);
      ++errors;
    }

  for (i = 0; i < (int) (sizeof (symlinks) / sizeof (symlinks[0])); ++i)
    symlink (symlinks[i].value, symlinks[i].name);

  fd = open("doesExist", O_CREAT | O_EXCL, 0777);

  for (i = 0; i < (int) (sizeof (tests) / sizeof (tests[0])); ++i)
    {
      buf[0] = '\0';
      result = myrealpath (tests[i].in, buf);

      if (!check_path (result, tests[i].out))
	{
	  printf ("%s: flunked test %d (expected `%s', got `%s')\n",
		  argv[0], i, tests[i].out ? tests[i].out : "NULL",
		  result ? result : "NULL");
	  ++errors;
	  continue;
	}

      if (!check_path (buf, tests[i].out ? tests[i].out : tests[i].resolved))
	{
	  printf ("%s: flunked test %d (expected resolved `%s', got `%s')\n",
		  argv[0], i, tests[i].out ? tests[i].out : tests[i].resolved,
		  buf);
	  ++errors;
	  continue;
	}

      if (!tests[i].out && errno != tests[i].error)
	{
	  printf ("%s: flunked test %d (expected errno %d, got %d)\n",
		  argv[0], i, tests[i].error, errno);
	  ++errors;
	  continue;
	}
    }

  getcwd (buf, sizeof(buf));
  if (strcmp (buf, cwd))
    {
      printf ("%s: current working directory changed from %s to %s\n",
	      argv[0], cwd, buf);
      ++errors;
    }

  if (fd >= 0)
    unlink("doesExist");

  for (i = 0; i < (int) (sizeof (symlinks) / sizeof (symlinks[0])); ++i)
    unlink (symlinks[i].name);

  if (errors != 0)
    {
      printf ("%d errors.\n", errors);
      return EXIT_FAILURE;
    }

  puts ("No errors.");
  return EXIT_SUCCESS;
}

#if 0
static char *sep(char *path)
{
	char *tmp, c;
	
	tmp = strrchr(path, '/');
	if(tmp) {
		c = tmp[1];
		tmp[1] = 0;
		if (chdir(path)) {
			return NULL;
		}
		tmp[1] = c;
		
		return tmp + 1;
	}
	
	return path;

}

char *myrealpath(const char *_path, char *resolved_path)
{
	int fd = open(".", O_RDONLY), l;
	char path[PATH_MAX], lnk[PATH_MAX], *tmp = (char *)"";
	
	if (fd < 0) {
		return NULL;
	}
	strncpy(path, _path, PATH_MAX);
	
	if (chdir(path)) {
		if (errno == ENOTDIR) {
			l = readlink(path, lnk, PATH_MAX);
			if (!(tmp = sep(path))) {
				resolved_path = NULL;
				goto abort;
			}
			if (l < 0) {
				perror("readlink");
				if (errno != EINVAL || errno !=ENOENT) {
					resolved_path = NULL;
					goto abort;
				}
			} else {
				lnk[l] = 0;
				if (!(tmp = sep(lnk))) {
					resolved_path = NULL;
					goto abort;
				}
			}
		} else {
			perror("chdir()");
			resolved_path = NULL;
			goto abort;
		}
	}
	if (!getcwd(resolved_path, PATH_MAX)) {
		resolved_path = NULL;
		goto abort;
	}
	
	if(strcmp(resolved_path, "/") && *tmp) {
		strcat(resolved_path, "/");
	}
	
	strcat(resolved_path, tmp);
      abort:
	fchdir(fd);
	close(fd);
	return resolved_path;
}
#endif
