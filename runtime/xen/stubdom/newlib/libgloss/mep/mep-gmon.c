/*-
 * Copyright (c) 1991, 1998, 2001 The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. [rescinded 22 July 1999]
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#ifndef lint
static char sccsid[] = "@(#)gmon.c	5.3 (Berkeley) 5/22/91";
#endif /* not lint */

#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

#define GMON_PTR_SIZE 4

struct phdr
  {
    char *lpc;			/* base pc address of sample buffer */
    char *hpc;			/* max pc address of sampled buffer */
    int ncnt;			/* size of sample buffer (plus this header) */

    char version[4];		/* version number */
    char profrate[4];		/* profiling clock rate */
    char spare[3*4];		/* reserved */
  };

#define GMONVERSION     0x00051879

/*
 * Histogram counters are unsigned shorts:
 */
#define	HISTCOUNTER unsigned short

/*
 * Fraction of text space to allocate for histogram counters here, 1/2:
 */
#define	HISTFRACTION	2

/*
 * Fraction of text space to allocate for from hash buckets.  The
 * value of HASHFRACTION is based on the minimum number of bytes of
 * separation between two subroutine call points in the object code.
 * Given MIN_SUBR_SEPARATION bytes of separation the value of
 * HASHFRACTION is calculated as:
 *
 *      HASHFRACTION = MIN_SUBR_SEPARATION / (2 * sizeof(short) - 1);
 *
 * For the VAX, the shortest two call sequence is:
 *
 *      calls   $0,(r0)
 *      calls   $0,(r0)
 *
 * which is separated by only three bytes, thus HASHFRACTION is
 * calculated as:
 *
 *      HASHFRACTION = 3 / (2 * 2 - 1) = 1
 *
 * Note that the division above rounds down, thus if MIN_SUBR_FRACTION
 * is less than three, this algorithm will not work!
 */
#define	HASHFRACTION 1

/*
 * Percent of text space to allocate for tostructs with a minimum:
 */
#define ARCDENSITY	2
#define MINARCS		50

struct tostruct
  {
    char *selfpc;
    int count;
    unsigned short link;
  };

/*
 * A raw arc, with pointers to the calling site and the called site
 * and a count.  Everything is defined in terms of characters so
 * as to get a packed representation (otherwise, different compilers
 * might introduce different padding):
 */
struct rawarc
  {
    unsigned long raw_frompc;
    unsigned long raw_selfpc;
    int raw_count;
  };

/*
 * General rounding functions:
 */
#define ROUNDDOWN(x,y)	(((x)/(y))*(y))
#define ROUNDUP(x,y)	((((x)+(y)-1)/(y))*(y))


#ifdef __alpha
extern char *sbrk ();
#endif

    /*
     *  froms is actually a bunch of unsigned shorts indexing tos
     */
static int profiling = 3;
static unsigned short *froms;
static struct tostruct *tos = 0;
static long tolimit = 0;
static char *s_lowpc = 0;
static char *s_highpc = 0;
static unsigned long s_textsize = 0;

static int ssiz;
static char *sbuf;
static int s_scale;
    /* see profil(2) where this is describe (incorrectly) */
#define		SCALE_1_TO_1	0x10000L

#define	MSG "No space for profiling buffer(s)\n"

#ifndef O_BINARY
#define O_BINARY 0
#endif

static void
moncleanup ()
{
  int fd;
  int fromindex;
  int endfrom;
  char *frompc;
  int toindex;
  struct rawarc rawarc;

  profiling = 1;
  fd = open ("gmon.out", O_WRONLY|O_TRUNC|O_CREAT|O_BINARY, 0666);
  if (fd < 0)
    {
      perror ("mcount: gmon.out");
      return;
    }
#ifdef DEBUG
  fprintf (stderr, "[mcleanup] sbuf 0x%x ssiz %d\n", sbuf, ssiz);
#endif /* DEBUG */
  write (fd, sbuf, ssiz);
  endfrom = s_textsize / (HASHFRACTION * sizeof (*froms));
  for (fromindex = 0; fromindex < endfrom; fromindex++)
    {
      if (froms[fromindex] == 0)
	{
	  continue;
	}
      frompc = s_lowpc + (fromindex * HASHFRACTION * sizeof (*froms));
      for (toindex = froms[fromindex]; toindex != 0;
	   toindex = tos[toindex].link)
	{
#ifdef DEBUG
	  fprintf (stderr,
		   "[mcleanup] frompc 0x%x selfpc 0x%x count %d\n",
		   frompc, tos[toindex].selfpc, tos[toindex].count);
#endif /* DEBUG */
	  rawarc.raw_frompc = (unsigned long) frompc;
	  rawarc.raw_selfpc = (unsigned long) tos[toindex].selfpc;
	  rawarc.raw_count = tos[toindex].count;
	  write (fd, &rawarc, sizeof rawarc);
	}
    }
  close (fd);
}

static void
monstartup (lowpc, highpc)
     char *lowpc;
     char *highpc;
{
  int monsize;
  char *buffer;
  register int o;

  atexit (moncleanup);

  /*
   *    round lowpc and highpc to multiples of the density we're using
   *    so the rest of the scaling (here and in gprof) stays in ints.
   */
  lowpc = (char *)
    ROUNDDOWN ((unsigned) lowpc, HISTFRACTION * sizeof (HISTCOUNTER));
  s_lowpc = lowpc;
  highpc = (char *)
    ROUNDUP ((unsigned) highpc, HISTFRACTION * sizeof (HISTCOUNTER));
  s_highpc = highpc;
  s_textsize = highpc - lowpc;
  monsize = (s_textsize / HISTFRACTION) + sizeof (struct phdr);
  buffer = sbrk (monsize);
  if (buffer == (char *) -1)
    {
      write (2, MSG, sizeof (MSG));
      return;
    }
  froms = (unsigned short *) sbrk (s_textsize / HASHFRACTION);
  if (froms == (unsigned short *) -1)
    {
      write (2, MSG, sizeof (MSG));
      froms = 0;
      return;
    }
  tolimit = s_textsize * ARCDENSITY / 100;
  if (tolimit < MINARCS)
    {
      tolimit = MINARCS;
    }
  else if (tolimit > 65534)
    {
      tolimit = 65534;
    }
  tos = (struct tostruct *) sbrk (tolimit * sizeof (struct tostruct));
  if (tos == (struct tostruct *) -1)
    {
      write (2, MSG, sizeof (MSG));
      froms = 0;
      tos = 0;
      return;
    }
  tos[0].link = 0;
  sbuf = buffer;
  ssiz = monsize;
  ((struct phdr *) buffer)->lpc = lowpc;
  ((struct phdr *) buffer)->hpc = highpc;
  ((struct phdr *) buffer)->ncnt = ssiz;
  monsize -= sizeof (struct phdr);
  if (monsize <= 0)
    return;
  o = highpc - lowpc;
  if (monsize < o)
#if 0
    s_scale = ((float) monsize / o) * SCALE_1_TO_1;
#else /* avoid floating point */
    {
      int quot = o / monsize;

      if (quot >= 0x10000)
	s_scale = 1;
      else if (quot >= 0x100)
	s_scale = 0x10000 / quot;
      else if (o >= 0x800000)
	s_scale = 0x1000000 / (o / (monsize >> 8));
      else
	s_scale = 0x1000000 / ((o << 8) / monsize);
    }
#endif
  else
    s_scale = SCALE_1_TO_1;
  profiling = 0;
}

/* These happen to be in the right place because of how crt0 works */
extern char __attribute__((far)) _start;
extern char __attribute__((far)) _etext;

void
__mep_mcount_2 (selfpc, frompcindex)
     char *selfpc;
     unsigned short *frompcindex;
{
  struct tostruct *top;
  struct tostruct *prevtop;
  long toindex;
  static int initialized = 0;

  if (!initialized)
    {
      initialized = 1;
      monstartup (&_start, &_etext);
    }

  /*
   *    check that we are profiling
   *    and that we aren't recursively invoked.
   */
  if (profiling)
    {
      goto out;
    }
  profiling++;
  /*
   *    check that frompcindex is a reasonable pc value.
   *    for example:    signal catchers get called from the stack,
   *                    not from text space.  too bad.
   */
  frompcindex = (unsigned short *) ((long) frompcindex - (long) s_lowpc);
  if ((unsigned long) frompcindex > s_textsize)
    {
      goto done;
    }
  frompcindex =
    &froms[((long) frompcindex) / (HASHFRACTION * sizeof (*froms))];
  toindex = *frompcindex;
  if (toindex == 0)
    {
      /*
       *  first time traversing this arc
       */
      toindex = ++tos[0].link;
      if (toindex >= tolimit)
	{
	  goto overflow;
	}
      *frompcindex = toindex;
      top = &tos[toindex];
      top->selfpc = selfpc;
      top->count = 1;
      top->link = 0;
      goto done;
    }
  top = &tos[toindex];
  if (top->selfpc == selfpc)
    {
      /*
       *  arc at front of chain; usual case.
       */
      top->count++;
      goto done;
    }
  /*
   *    have to go looking down chain for it.
   *    top points to what we are looking at,
   *    prevtop points to previous top.
   *    we know it is not at the head of the chain.
   */
  for (; /* goto done */ ;)
    {
      if (top->link == 0)
	{
	  /*
	   *        top is end of the chain and none of the chain
	   *        had top->selfpc == selfpc.
	   *        so we allocate a new tostruct
	   *        and link it to the head of the chain.
	   */
	  toindex = ++tos[0].link;
	  if (toindex >= tolimit)
	    {
	      goto overflow;
	    }
	  top = &tos[toindex];
	  top->selfpc = selfpc;
	  top->count = 1;
	  top->link = *frompcindex;
	  *frompcindex = toindex;
	  goto done;
	}
      /*
       *  otherwise, check the next arc on the chain.
       */
      prevtop = top;
      top = &tos[top->link];
      if (top->selfpc == selfpc)
	{
	  /*
	   *        there it is.
	   *        increment its count
	   *        move it to the head of the chain.
	   */
	  top->count++;
	  toindex = prevtop->link;
	  prevtop->link = top->link;
	  top->link = *frompcindex;
	  *frompcindex = toindex;
	  goto done;
	}

    }
done:
  profiling--;
  /* and fall through */
out:
  return;			/* normal return restores saved registers */

overflow:
  profiling++;			/* halt further profiling */
#   define	TOLIMIT	"mcount: tos overflow\n"
  write (2, TOLIMIT, sizeof (TOLIMIT));
  goto out;
}



