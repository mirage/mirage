/* libc/sys/linux/psignal.c - print signal message to stderr */

/* Copyright 2002, Red Hat Inc. */

#include <stdio.h>
#include <string.h>

void
psignal (int sig, const char *s)
{
  if (s != NULL)
    fprintf (stderr, "%s: %s\n", s, strsignal (sig));
  else
    fprintf (stderr, "%s\n", strsignal (sig));
}
