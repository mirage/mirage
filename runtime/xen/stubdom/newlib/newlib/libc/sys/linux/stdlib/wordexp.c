/* Copyright (C) 2002 by  Red Hat, Incorporated. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

#include <sys/param.h>
#include <sys/stat.h>

#include <ctype.h>
#include <dirent.h>
#include <errno.h>
#include <glob.h>
#include <pwd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>

#include <wordexp.h>

#define MAXLINELEN 500

/* Note: This implementation of wordexp requires a version of bash
   that supports the --wordexp and --protected arguments to be present
   on the system.  It does not support the WRDE_UNDEF flag. */
int
wordexp(const char *words, wordexp_t *pwordexp, int flags)
{
  FILE *f;
  FILE *f_err;
  char tmp[MAXLINELEN];
  int i = 0;
  int offs = 0;
  char *iter;
  pid_t pid;
  int num_words = 0;
  int num_bytes = 0;
  int fd[2];
  int fd_err[2];
  int err = 0;

  if (pwordexp == NULL)
    {
      return WRDE_NOSPACE;
    }

  if (flags & WRDE_REUSE)
    wordfree(pwordexp);

  if ((flags & WRDE_APPEND) == 0)
    {
      pwordexp->we_wordc = 0;
      pwordexp->we_wordv = NULL;
    }

  if (flags & WRDE_DOOFFS)
    {
      offs = pwordexp->we_offs;

      if(!(pwordexp->we_wordv = (char **)realloc(pwordexp->we_wordv, (pwordexp->we_wordc + offs + 1) * sizeof(char *))))
        return WRDE_NOSPACE;

      for (i = 0; i < offs; i++)
        pwordexp->we_wordv[i] = NULL;
    }

  pipe(fd);
  pipe(fd_err);
  pid = fork();

  if (pid > 0)
    {
      /* In parent process. */

      /* Close write end of parent's pipe. */
      close(fd[1]);
      close(fd_err[1]);

      /* f_err is the standard error from the shell command. */
      f_err = fdopen(fd_err[0], "r");

      /* Check for errors. */
      if (fgets(tmp, MAXLINELEN, f_err))
        {
          if (strstr(tmp, "EOF"))
            err = WRDE_SYNTAX;
          else if (strstr(tmp, "`\n'") || strstr(tmp, "`|'")
                   || strstr(tmp, "`&'") || strstr(tmp, "`;'")
                   || strstr(tmp, "`<'") || strstr(tmp, "`>'")
                   || strstr(tmp, "`('") || strstr(tmp, "`)'")
                   || strstr(tmp, "`{'") || strstr(tmp, "`}'"))
            err = WRDE_BADCHAR;
          else if (strstr(tmp, "command substitution"))
            err = WRDE_CMDSUB;
          else
            err = WRDE_SYNTAX;

          if (flags & WRDE_SHOWERR)
            {
              fprintf(stderr, tmp);
              while(fgets(tmp, MAXLINELEN, f_err))
                fprintf(stderr, tmp);
            }

          return err;
        }

      /* f is the standard output from the shell command. */
      f = fdopen(fd[0], "r");

      /* Get number of words expanded by shell. */
      fgets(tmp, MAXLINELEN, f);

      if((iter = strchr(tmp, '\n')))
          *iter = '\0';

      num_words = atoi(tmp);

      if(!(pwordexp->we_wordv = (char **)realloc(pwordexp->we_wordv,
                                                 (pwordexp->we_wordc + num_words + offs + 1) * sizeof(char *))))
        return WRDE_NOSPACE;

      /* Get number of bytes required for storage of num_words words. */
      fgets(tmp, MAXLINELEN, f);

      if((iter = strchr(tmp, '\n')))
          *iter = '\0';

      num_bytes = atoi(tmp) + pwordexp->we_wordc;

      /* Get each expansion from the shell output, and store each in
         pwordexp's we_wordv vector. */
      for(i = 0; i < num_words; i++)
        {
          fgets(tmp, MAXLINELEN, f);

          if((iter = strchr(tmp, '\n')))
            *iter = '\0';

          pwordexp->we_wordv[pwordexp->we_wordc + offs + i] = strdup(tmp);
        }

      pwordexp->we_wordv[pwordexp->we_wordc + offs + i] = NULL;
      pwordexp->we_wordc += num_words;

      close(fd[0]);
      close(fd_err[0]);

      /* Wait for child to finish. */
      waitpid (pid, NULL, 0);

      return WRDE_SUCCESS;
    }
  else
    {
      /* In child process. */

      /* Close read end of child's pipe. */
      close(fd[0]);
      close(fd_err[0]);

      /* Pipe standard output to parent process via fd. */
      if (fd[1] != STDOUT_FILENO)
        {
          dup2(fd[1], STDOUT_FILENO);
          /* fd[1] no longer required. */
          close(fd[1]);
        }

      /* Pipe standard error to parent process via fd_err. */
      if (fd_err[1] != STDERR_FILENO)
        {
          dup2(fd_err[1], STDERR_FILENO);
          /* fd_err[1] no longer required. */
          close(fd_err[1]);
        }

      if (flags & WRDE_NOCMD)
        execl("/bin/bash", "bash", "--protected", "--wordexp", words, (char *)0);
      else
        execl("/bin/bash", "bash", "--wordexp", words, (char *)0);
    }
  return WRDE_SUCCESS;
}
