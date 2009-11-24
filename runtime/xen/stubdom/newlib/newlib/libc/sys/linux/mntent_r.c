/* Utilities for reading/writing fstab, mtab, etc.
   Copyright (C) 1995-2000, 2001 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

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

#include <alloca.h>
#include <mntent.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <machine/weakalias.h>

/* Prepare to begin reading and/or writing mount table entries from the
   beginning of FILE.  MODE is as for `fopen'.  */
FILE *
__setmntent (const char *file, const char *mode)
{
  FILE *result = fopen (file, mode);

  return result;
}
weak_alias (__setmntent, setmntent)


/* Close a stream opened with `setmntent'.  */
int
__endmntent (FILE *stream)
{
  if (stream)		/* SunOS 4.x allows for NULL stream */
    fclose (stream);
  return 1;		/* SunOS 4.x says to always return 1 */
}
weak_alias (__endmntent, endmntent)


/* Since the values in a line are separated by spaces, a name cannot
   contain a space.  Therefore some programs encode spaces in names
   by the strings "\040".  We undo the encoding when reading an entry.
   The decoding happens in place.  */
static char *
decode_name (char *buf)
{
  char *rp = buf;
  char *wp = buf;

  do
    if (rp[0] == '\\' && rp[1] == '0' && rp[2] == '4' && rp[3] == '0')
      {
	/* \040 is a SPACE.  */
	*wp++ = ' ';
	rp += 3;
      }
    else if (rp[0] == '\\' && rp[1] == '0' && rp[2] == '1' && rp[3] == '2')
      {
	/* \012 is a TAB.  */
	*wp++ = '\t';
	rp += 3;
      }
    else if (rp[0] == '\\' && rp[1] == '\\')
      {
	/* We have to escape \\ to be able to represent all characters.  */
	*wp++ = '\\';
	rp += 1;
      }
    else
      *wp++ = *rp;
  while (*rp++ != '\0');

  return buf;
}


/* Read one mount table entry from STREAM.  Returns a pointer to storage
   reused on the next call, or null for EOF or error (use feof/ferror to
   check).  */
struct mntent *
__getmntent_r (FILE *stream, struct mntent *mp, char *buffer, int bufsiz)
{
  char *cp;
  char *head;

  flockfile (stream);
  do
    {
      char *end_ptr;

      if (fgets (buffer, bufsiz, stream) == NULL)
	{
	  funlockfile (stream);
	  return NULL;
	}

      end_ptr = strchr (buffer, '\n');
      if (end_ptr != NULL)	/* chop newline */
	*end_ptr = '\0';
      else
	{
	  /* Not the whole line was read.  Do it now but forget it.  */
	  char tmp[1024];
	  while (fgets (tmp, sizeof tmp, stream) != NULL)
	    if (strchr (tmp, '\n') != NULL)
	      break;
	}

      head = buffer + strspn (buffer, " \t");
      /* skip empty lines and comment lines:  */
    }
  while (head[0] == '\0' || head[0] == '#');

  cp = strsep (&head, " \t");
  mp->mnt_fsname = cp != NULL ? decode_name (cp) : (char *) "";
  if (head)
    head += strspn (head, " \t");
  cp = strsep (&head, " \t");
  mp->mnt_dir = cp != NULL ? decode_name (cp) : (char *) "";
  if (head)
    head += strspn (head, " \t");
  cp = strsep (&head, " \t");
  mp->mnt_type = cp != NULL ? decode_name (cp) : (char *) "";
  if (head)
    head += strspn (head, " \t");
  cp = strsep (&head, " \t");
  mp->mnt_opts = cp != NULL ? decode_name (cp) : (char *) "";
  switch (head ? sscanf (head, " %d %d ", &mp->mnt_freq, &mp->mnt_passno) : 0)
    {
    case 0:
      mp->mnt_freq = 0;
    case 1:
      mp->mnt_passno = 0;
    case 2:
      break;
    }
  funlockfile (stream);

  return mp;
}
weak_alias (__getmntent_r, getmntent_r)


/* We have to use an encoding for names if they contain spaces or tabs.
   To be able to represent all characters we also have to escape the
   backslash itself.  This "function" must be a macro since we use
   `alloca'.  */
#define encode_name(name) \
  do {									      \
    const char *rp = name;						      \
									      \
    while (*rp != '\0')							      \
      if (*rp == ' ' || *rp == '\t' || *rp == '\\')			      \
	break;								      \
      else								      \
	++rp;								      \
									      \
    if (*rp != '\0')							      \
      {									      \
	/* In the worst case the length of the string can increase to	      \
	   founr times the current length.  */				      \
	char *wp;							      \
									      \
	rp = name;							      \
	name = wp = (char *) alloca (strlen (name) * 4 + 1);		      \
									      \
	do								      \
	  if (*rp == ' ')						      \
	    {								      \
	      *wp++ = '\\';						      \
	      *wp++ = '0';						      \
	      *wp++ = '4';						      \
	      *wp++ = '0';						      \
	    }								      \
	  else if (*rp == '\t')						      \
	    {								      \
	      *wp++ = '\\';						      \
	      *wp++ = '0';						      \
	      *wp++ = '1';						      \
	      *wp++ = '2';						      \
	    }								      \
	  else if (*rp == '\\')						      \
	    {								      \
	      *wp++ = '\\';						      \
	      *wp++ = '\\';						      \
	    }								      \
	  else								      \
	    *wp++ = *rp;						      \
	while (*rp++ != '\0');						      \
      }									      \
  } while (0)


/* Write the mount table entry described by MNT to STREAM.
   Return zero on success, nonzero on failure.  */
int
__addmntent (FILE *stream, const struct mntent *mnt)
{
  struct mntent mntcopy = *mnt;
  if (fseek (stream, 0, SEEK_END))
    return 1;

  /* Encode spaces and tabs in the names.  */
  encode_name (mntcopy.mnt_fsname);
  encode_name (mntcopy.mnt_dir);
  encode_name (mntcopy.mnt_type);
  encode_name (mntcopy.mnt_opts);

  return (fprintf (stream, "%s %s %s %s %d %d\n",
		   mntcopy.mnt_fsname,
		   mntcopy.mnt_dir,
		   mntcopy.mnt_type,
		   mntcopy.mnt_opts,
		   mntcopy.mnt_freq,
		   mntcopy.mnt_passno)
	  < 0 ? 1 : 0);
}
weak_alias (__addmntent, addmntent)


/* Search MNT->mnt_opts for an option matching OPT.
   Returns the address of the substring, or null if none found.  */
char *
__hasmntopt (const struct mntent *mnt, const char *opt)
{
  const size_t optlen = strlen (opt);
  char *rest = mnt->mnt_opts, *p;

  while ((p = strstr (rest, opt)) != NULL)
    {
      if (p == rest
	  || (p[-1] == ','
	      && (p[optlen] == '\0' ||
		  p[optlen] == '='  ||
		  p[optlen] == ',')))
	return p;

      rest = strchr (rest, ',');
      if (rest == NULL)
	break;
      ++rest;
    }

  return NULL;
}
weak_alias (__hasmntopt, hasmntopt)
