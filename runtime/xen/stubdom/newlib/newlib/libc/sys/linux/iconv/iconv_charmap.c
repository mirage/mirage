/* Convert using charmaps and possibly iconv().
   Copyright (C) 2001 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by Ulrich Drepper <drepper@redhat.com>, 2001.

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

#include <assert.h>
#include <errno.h>
#include <error.h>
#include <fcntl.h>
#include <iconv.h>
#include <libintl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>

#include "iconv_prog.h"


/* Prototypes for a few program-wide used functions.  */
extern void *xmalloc (size_t __n);
extern void *xcalloc (size_t __n, size_t __s);


struct convtable
{
  int term[256 / 8];
  union
  {
    struct convtable *sub;
    struct charseq *out;
  } val[256];
};


static inline struct convtable *
allocate_table (void)
{
  return (struct convtable *) xcalloc (1, sizeof (struct convtable));
}


static inline int
is_term (struct convtable *tbl, unsigned int idx)
{
  return tbl->term[idx / 8] & (1 << (idx % 8));
}


static inline void
clear_term (struct convtable *tbl, unsigned int idx)
{
  tbl->term[idx / 8] &= ~(1 << (idx % 8));
}


static inline void
set_term (struct convtable *tbl, unsigned int idx)
{
  tbl->term[idx / 8] |= 1 << (idx % 8);
}


/* Generate the conversion table.  */
static struct convtable *use_from_charmap (struct charmap_t *from_charmap,
					   const char *to_code);
static struct convtable *use_to_charmap (const char *from_code,
					 struct charmap_t *to_charmap);
static struct convtable *use_both_charmaps (struct charmap_t *from_charmap,
					    struct charmap_t *to_charmap);

/* Prototypes for the functions doing the actual work.  */
static int process_block (struct convtable *tbl, char *addr, size_t len,
			  FILE *output);
static int process_fd (struct convtable *tbl, int fd, FILE *output);
static int process_file (struct convtable *tbl, FILE *input, FILE *output);


int
charmap_conversion (const char *from_code, struct charmap_t *from_charmap,
		    const char *to_code, struct charmap_t *to_charmap,
		    int argc, int remaining, char *argv[], FILE *output)
{
  struct convtable *cvtbl;
  int status = EXIT_SUCCESS;

  /* We have three different cases to handle:

     - both, from_charmap and to_charmap, are available.  This means we
       can assume that the symbolic names match and use them to create
       the mapping.

     - only from_charmap is available.  In this case we can only hope that
       the symbolic names used are of the <Uxxxx> form in which case we
       can use a UCS4->"to_code" iconv() conversion for the second step.

     - only to_charmap is available.  This is similar, only that we would
       use iconv() for the "to_code"->UCS4 conversion.

       We first create a table which maps input bytes into output bytes.
       Once this is done we can handle all three of the cases above
       equally.  */
  if (from_charmap != NULL)
    {
      if (to_charmap == NULL)
	cvtbl = use_from_charmap (from_charmap, to_code);
      else
	cvtbl = use_both_charmaps (from_charmap, to_charmap);
    }
  else
    {
      assert (to_charmap != NULL);
      cvtbl = use_to_charmap (from_code, to_charmap);
    }

  /* If we couldn't generate a table stop now.  */
  if (cvtbl == NULL)
    return EXIT_FAILURE;

  /* We can now start the conversion.  */
  if (remaining == argc)
    {
      if (process_file (cvtbl, stdin, output) != 0)
	status = EXIT_FAILURE;
    }
  else
    do
      {
	struct stat st;
	char *addr;
	int fd;

	if (verbose)
	  printf ("%s:\n", argv[remaining]);
	if (strcmp (argv[remaining], "-") == 0)
	  fd = 0;
	else
	  {
	    fd = open (argv[remaining], O_RDONLY);

	    if (fd == -1)
	      {
		error (0, errno, _("cannot open input file `%s'"),
		       argv[remaining]);
		status = EXIT_FAILURE;
		continue;
	      }
	  }

#ifdef _POSIX_MAPPED_FILES
	/* We have possibilities for reading the input file.  First try
	   to mmap() it since this will provide the fastest solution.  */
	if (fstat (fd, &st) == 0
	    && ((addr = mmap (NULL, st.st_size, PROT_READ, MAP_PRIVATE,
			      fd, 0)) != MAP_FAILED))
	  {
	    /* Yes, we can use mmap().  The descriptor is not needed
	       anymore.  */
	    if (close (fd) != 0)
	      error (EXIT_FAILURE, errno,
		     _("error while closing input `%s'"), argv[remaining]);

	    if (process_block (cvtbl, addr, st.st_size, output) < 0)
	      {
		/* Something went wrong.  */
		status = EXIT_FAILURE;

		/* We don't need the input data anymore.  */
		munmap ((void *) addr, st.st_size);

		/* We cannot go on with producing output since it might
		   lead to problem because the last output might leave
		   the output stream in an undefined state.  */
		break;
	      }

	    /* We don't need the input data anymore.  */
	    munmap ((void *) addr, st.st_size);
	  }
	else
#endif	/* _POSIX_MAPPED_FILES */
	  {
	    /* Read the file in pieces.  */
	    if (process_fd (cvtbl, fd, output) != 0)
	      {
		/* Something went wrong.  */
		status = EXIT_FAILURE;

		/* We don't need the input file anymore.  */
		close (fd);

		/* We cannot go on with producing output since it might
		   lead to problem because the last output might leave
		   the output stream in an undefined state.  */
		break;
	      }

	    /* Now close the file.  */
	    close (fd);
	  }
      }
    while (++remaining < argc);

  /* All done.  */
  return status;
}


static void
add_bytes (struct convtable *tbl, struct charseq *in, struct charseq *out)
{
  int n = 0;
  unsigned int byte;

  assert (in->nbytes > 0);

  byte = ((unsigned char *) in->bytes)[n];
  while (n + 1 < in->nbytes)
    {
      if (is_term (tbl, byte) || tbl->val[byte].sub == NULL)
	{
	  /* Note that we simply ignore a definition for a byte sequence
	     which is also the prefix for a longer one.  */
	  clear_term (tbl, byte);
	  tbl->val[byte].sub =
	    (struct convtable *) xcalloc (1, sizeof (struct convtable));
	}

      tbl = tbl->val[byte].sub;

      byte = ((unsigned char *) in->bytes)[++n];
    }

  /* Only add the new sequence if there is none yet and the byte sequence
     is not part of an even longer one.  */
  if (! is_term (tbl, byte) && tbl->val[byte].sub == NULL)
    {
      set_term (tbl, byte);
      tbl->val[byte].out = out;
    }
}


static struct convtable *
use_from_charmap (struct charmap_t *from_charmap, const char *to_code)
{
  /* We iterate over all entries in the from_charmap and for those which
     have a known UCS4 representation we use an iconv() call to determine
     the mapping to the to_code charset.  */
  struct convtable *rettbl;
  iconv_t cd;
  void *ptr = NULL;
  const void *key;
  size_t keylen;
  void *data;

  cd = iconv_open (to_code, "WCHAR_T");
  if (cd == (iconv_t) -1)
    /* We cannot do anything.  */
    return NULL;

  rettbl = allocate_table ();

  while (iterate_table (&from_charmap->char_table, &ptr, &key, &keylen, &data)
	 >= 0)
    {
      struct charseq *in = (struct charseq *) data;

      if (in->ucs4 != UNINITIALIZED_CHAR_VALUE)
	{
	  /* There is a chance.  Try the iconv module.  */
	  wchar_t inbuf[1] = { in->ucs4 };
	  unsigned char outbuf[64];
	  char *inptr = (char *) inbuf;
	  size_t inlen = sizeof (inbuf);
	  char *outptr = (char *) outbuf;
	  size_t outlen = sizeof (outbuf);

	  (void) iconv (cd, &inptr, &inlen, &outptr, &outlen);

	  if (outptr != (char *) outbuf)
	    {
	      /* We got some output.  Good, use it.  */
	      struct charseq *newp;

	      outlen = sizeof (outbuf) - outlen;
	      assert ((char *) outbuf + outlen == outptr);

	      newp = (struct charseq *) xmalloc (sizeof (struct charseq)
						 + outlen);
	      newp->name = in->name;
	      newp->ucs4 = in->ucs4;
	      newp->nbytes = outlen;
	      memcpy (newp->bytes, outbuf, outlen);

	      add_bytes (rettbl, in, newp);
	    }

	  /* Clear any possible state left behind.  */
	  (void) iconv (cd, NULL, NULL, NULL, NULL);
	}
    }

  iconv_close (cd);

  return rettbl;
}


static struct convtable *
use_to_charmap (const char *from_code, struct charmap_t *to_charmap)
{
  /* We iterate over all entries in the to_charmap and for those which
     have a known UCS4 representation we use an iconv() call to determine
     the mapping to the from_code charset.  */
  struct convtable *rettbl;
  iconv_t cd;
  void *ptr = NULL;
  const void *key;
  size_t keylen;
  void *data;

  /* Note that the conversion we use here is the reverse direction.  Without
     exhaustive search we cannot figure out which input yields the UCS4
     character we are looking for.  Therefore we determine it the other
     way round.  */
  cd = iconv_open (from_code, "WCHAR_T");
  if (cd == (iconv_t) -1)
    /* We cannot do anything.  */
    return NULL;

  rettbl = allocate_table ();

  while (iterate_table (&to_charmap->char_table, &ptr, &key, &keylen, &data)
	 >= 0)
    {
      struct charseq *out = (struct charseq *) data;

      if (out->ucs4 != UNINITIALIZED_CHAR_VALUE)
	{
	  /* There is a chance.  Try the iconv module.  */
	  wchar_t inbuf[1] = { out->ucs4 };
	  unsigned char outbuf[64];
	  char *inptr = (char *) inbuf;
	  size_t inlen = sizeof (inbuf);
	  char *outptr = (char *) outbuf;
	  size_t outlen = sizeof (outbuf);

	  (void) iconv (cd, &inptr, &inlen, &outptr, &outlen);

	  if (outptr != (char *) outbuf)
	    {
	      /* We got some output.  Good, use it.  */
	      struct charseq *newp;

	      outlen = sizeof (outbuf) - outlen;
	      assert ((char *) outbuf + outlen == outptr);

	      newp = (struct charseq *) xmalloc (sizeof (struct charseq)
						 + outlen);
	      newp->name = out->name;
	      newp->ucs4 = out->ucs4;
	      newp->nbytes = outlen;
	      memcpy (newp->bytes, outbuf, outlen);

	      add_bytes (rettbl, newp, out);
	    }

	  /* Clear any possible state left behind.  */
	  (void) iconv (cd, NULL, NULL, NULL, NULL);
	}
    }

  iconv_close (cd);

  return rettbl;
}


static struct convtable *
use_both_charmaps (struct charmap_t *from_charmap,
		   struct charmap_t *to_charmap)
{
  /* In this case we iterate over all the entries in the from_charmap,
     determine the internal name, and find an appropriate entry in the
     to_charmap (if it exists).  */
  struct convtable *rettbl = allocate_table ();
  void *ptr = NULL;
  const void *key;
  size_t keylen;
  void *data;

  while (iterate_table (&from_charmap->char_table, &ptr, &key, &keylen, &data)
	 >= 0)
    {
      struct charseq *in = (struct charseq *) data;
      struct charseq *out = charmap_find_value (to_charmap, key, keylen);

      if (out != NULL)
	add_bytes (rettbl, in, out);
    }

  return rettbl;
}


static int
process_block (struct convtable *tbl, char *addr, size_t len, FILE *output)
{
  size_t n = 0;

  while (n < len)
    {
      struct convtable *cur = tbl;
      unsigned char *curp = (unsigned char *) addr;
      unsigned int byte = *curp;
      int cnt;
      struct charseq *out;

      while (! is_term (cur, byte))
	if (cur->val[byte].sub == NULL)
	  {
	    /* This is a invalid sequence.  Skip the first byte if we are
	       ignoring errors.  Otherwise punt.  */
	    if (! omit_invalid)
	      {
		error (0, 0, _("illegal input sequence at position %Zd"), n);
		return -1;
	      }

	    n -= curp - (unsigned char *) addr;

	    byte = *(curp = (unsigned char *) ++addr);
	    if (++n >= len)
	      /* All converted.  */
	      return 0;

	    cur = tbl;
	  }
	else
	  {
	    cur = cur->val[byte].sub;

	    if (++n >= len)
	      {
		error (0, 0, _("\
incomplete character or shift sequence at end of buffer"));
		return -1;
	      }

	    byte = *++curp;
	  }

      /* We found a final byte.  Write the output bytes.  */
      out = cur->val[byte].out;
      for (cnt = 0; cnt < out->nbytes; ++cnt)
	fputc_unlocked (out->bytes[cnt], output);

      addr = (char *) curp + 1;
      ++n;
    }

  return 0;
}


static int
process_fd (struct convtable *tbl, int fd, FILE *output)
{
  /* we have a problem with reading from a desriptor since we must not
     provide the iconv() function an incomplete character or shift
     sequence at the end of the buffer.  Since we have to deal with
     arbitrary encodings we must read the whole text in a buffer and
     process it in one step.  */
  static char *inbuf = NULL;
  static size_t maxlen = 0;
  char *inptr = NULL;
  size_t actlen = 0;

  while (actlen < maxlen)
    {
      ssize_t n = read (fd, inptr, maxlen - actlen);

      if (n == 0)
	/* No more text to read.  */
	break;

      if (n == -1)
	{
	  /* Error while reading.  */
	  error (0, errno, _("error while reading the input"));
	  return -1;
	}

      inptr += n;
      actlen += n;
    }

  if (actlen == maxlen)
    while (1)
      {
	ssize_t n;

	/* Increase the buffer.  */
	maxlen += 32768;
	inbuf = realloc (inbuf, maxlen);
	if (inbuf == NULL)
	  error (0, errno, _("unable to allocate buffer for input"));
	inptr = inbuf + actlen;

	do
	  {
	    n = read (fd, inptr, maxlen - actlen);

	    if (n == 0)
	      /* No more text to read.  */
	      break;

	    if (n == -1)
	      {
		/* Error while reading.  */
		error (0, errno, _("error while reading the input"));
		return -1;
	      }

	    inptr += n;
	    actlen += n;
	  }
	while (actlen < maxlen);

	if (n == 0)
	  /* Break again so we leave both loops.  */
	  break;
      }

  /* Now we have all the input in the buffer.  Process it in one run.  */
  return process_block (tbl, inbuf, actlen, output);
}


static int
process_file (struct convtable *tbl, FILE *input, FILE *output)
{
  /* This should be safe since we use this function only for `stdin' and
     we haven't read anything so far.  */
  return process_fd (tbl, fileno (input), output);
}
