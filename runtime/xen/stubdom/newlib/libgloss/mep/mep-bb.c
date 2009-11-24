/*
 * Copyright (c) 2000-2001  Red Hat, Inc. All rights reserved.
 *
 * This copyrighted material is made available to anyone wishing to use, modify,
 * copy, or redistribute it subject to the terms and conditions of the BSD 
 * License.  This program is distributed in the hope that it will be useful, 
 * but WITHOUT ANY WARRANTY expressed or implied, including the implied 
 * warranties of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  A copy 
 * of this license is available at http://www.opensource.org/licenses. Any 
 * Red Hat trademarks that are incorporated in the source code or documentation
 * are not subject to the BSD License and may only be used or replicated with 
 * the express permission of Red Hat, Inc.
 */

/* Structure emitted by -a  */
struct bb
{
  long zero_word;
  const char *filename;
  long *counts;
  long ncounts;
  struct bb *next;
  const unsigned long *addresses;

  /* Older GCC's did not emit these fields.  */
  long nwords;
  const char **functions;
  const long *line_nums;
  const char **filenames;
  char *flags;
};

/* Simple minded basic block profiling output dumper for
   systems that don't provide tcov support.  At present,
   it requires atexit and stdio.  */

#undef NULL /* Avoid errors if stdio.h and our stddef.h mismatch.  */
#include <stdio.h>
#include <time.h>
char *ctime (const time_t *);

/*#include "gbl-ctors.h"*/
#include "gcov-io.h"
#include <string.h>

static struct bb *bb_head;

static int num_digits (long value, int base) __attribute__ ((const));

/* Return the number of digits needed to print a value */
/* __inline__ */ static int num_digits (long value, int base)
{
  int minus = (value < 0 && base != 16);
  unsigned long v = (minus) ? -value : value;
  int ret = minus;

  do
    {
      v /= base;
      ret++;
    }
  while (v);

  return ret;
}

void
__bb_exit_func (void)
{
  FILE *da_file, *file;
  long time_value;
  int i;

  if (bb_head == 0)
    return;

  i = strlen (bb_head->filename) - 3;

  if (!strcmp (bb_head->filename+i, ".da"))
    {
      /* Must be -fprofile-arcs not -a.
	 Dump data in a form that gcov expects.  */

      struct bb *ptr;

      for (ptr = bb_head; ptr != (struct bb *) 0; ptr = ptr->next)
	{
	  int firstchar;

	  /* Make sure the output file exists -
	     but don't clobber exiting data.  */
	  if ((da_file = fopen (ptr->filename, "a")) != 0)
	    fclose (da_file);

	  /* Need to re-open in order to be able to write from the start.  */
	  da_file = fopen (ptr->filename, "r+b");
	  /* Some old systems might not allow the 'b' mode modifier.
	     Therefore, try to open without it.  This can lead to a race
	     condition so that when you delete and re-create the file, the
	     file might be opened in text mode, but then, you shouldn't
	     delete the file in the first place.  */
	  if (da_file == 0)
	    da_file = fopen (ptr->filename, "r+");
	  if (da_file == 0)
	    {
	      fprintf (stderr, "arc profiling: Can't open output file %s.\n",
		       ptr->filename);
	      continue;
	    }

	  /* After a fork, another process might try to read and/or write
	     the same file simultanously.  So if we can, lock the file to
	     avoid race conditions.  */

	  /* If the file is not empty, and the number of counts in it is the
	     same, then merge them in.  */
	  firstchar = fgetc (da_file);
	  if (firstchar == EOF)
	    {
	      if (ferror (da_file))
		{
		  fprintf (stderr, "arc profiling: Can't read output file ");
		  perror (ptr->filename);
		}
	    }
	  else
	    {
	      long n_counts = 0;
	      
	      if (ungetc (firstchar, da_file) == EOF)
		rewind (da_file);
	      if (__read_long (&n_counts, da_file, 8) != 0)
		{
		  fprintf (stderr, "arc profiling: Can't read output file %s.\n",
			   ptr->filename);
		  continue;
		}

	      if (n_counts == ptr->ncounts)
		{
		  int i;

		  for (i = 0; i < n_counts; i++)
		    {
		      long v = 0;

		      if (__read_long (&v, da_file, 8) != 0)
			{
			  fprintf (stderr, "arc profiling: Can't read output file %s.\n",
				   ptr->filename);
			  break;
			}
		      ptr->counts[i] += v;
		    }
		}

	    }

	  rewind (da_file);

	  /* ??? Should first write a header to the file.  Preferably, a 4 byte
	     magic number, 4 bytes containing the time the program was
	     compiled, 4 bytes containing the last modification time of the
	     source file, and 4 bytes indicating the compiler options used.

	     That way we can easily verify that the proper source/executable/
	     data file combination is being used from gcov.  */

	  if (__write_long (ptr->ncounts, da_file, 8) != 0)
	    {
	      
	      fprintf (stderr, "arc profiling: Error writing output file %s.\n",
		       ptr->filename);
	    }
	  else
	    {
	      int j;
	      long *count_ptr = ptr->counts;
	      int ret = 0;
	      for (j = ptr->ncounts; j > 0; j--)
		{
		  if (__write_long (*count_ptr, da_file, 8) != 0)
		    {
		      ret=1;
		      break;
		    }
		  count_ptr++;
		}
	      if (ret)
		fprintf (stderr, "arc profiling: Error writing output file %s.\n",
			 ptr->filename);
	    }
	  
	  if (fclose (da_file) == EOF)
	    fprintf (stderr, "arc profiling: Error closing output file %s.\n",
		     ptr->filename);
	}

      return;
    }

  /* Must be basic block profiling.  Emit a human readable output file.  */

  file = fopen ("bb.out", "a");

  if (!file)
    perror ("bb.out");

  else
    {
      struct bb *ptr;

      /* This is somewhat type incorrect, but it avoids worrying about
	 exactly where time.h is included from.  It should be ok unless
	 a void * differs from other pointer formats, or if sizeof (long)
	 is < sizeof (time_t).  It would be nice if we could assume the
	 use of rationale standards here.  */

      time ((void *) &time_value);
      fprintf (file, "Basic block profiling finished on %s\n", ctime ((void *) &time_value));

      /* We check the length field explicitly in order to allow compatibility
	 with older GCC's which did not provide it.  */

      for (ptr = bb_head; ptr != (struct bb *) 0; ptr = ptr->next)
	{
	  int i;
	  int func_p	= (ptr->nwords >= (long) sizeof (struct bb)
			   && ptr->nwords <= 1000
			   && ptr->functions);
	  int line_p	= (func_p && ptr->line_nums);
	  int file_p	= (func_p && ptr->filenames);
	  int addr_p	= (ptr->addresses != 0);
	  long ncounts	= ptr->ncounts;
	  long cnt_max  = 0;
	  long line_max = 0;
	  long addr_max = 0;
	  int file_len	= 0;
	  int func_len	= 0;
	  int blk_len	= num_digits (ncounts, 10);
	  int cnt_len;
	  int line_len;
	  int addr_len;

	  fprintf (file, "File %s, %ld basic blocks \n\n",
		   ptr->filename, ncounts);

	  /* Get max values for each field.  */
	  for (i = 0; i < ncounts; i++)
	    {
	      const char *p;
	      int len;

	      if (cnt_max < ptr->counts[i])
		cnt_max = ptr->counts[i];

	      if (addr_p && (unsigned long) addr_max < ptr->addresses[i])
		addr_max = ptr->addresses[i];

	      if (line_p && line_max < ptr->line_nums[i])
		line_max = ptr->line_nums[i];

	      if (func_p)
		{
		  p = (ptr->functions[i]) ? (ptr->functions[i]) : "<none>";
		  len = strlen (p);
		  if (func_len < len)
		    func_len = len;
		}

	      if (file_p)
		{
		  p = (ptr->filenames[i]) ? (ptr->filenames[i]) : "<none>";
		  len = strlen (p);
		  if (file_len < len)
		    file_len = len;
		}
	    }

	  addr_len = num_digits (addr_max, 16);
	  cnt_len  = num_digits (cnt_max, 10);
	  line_len = num_digits (line_max, 10);

	  /* Now print out the basic block information.  */
	  for (i = 0; i < ncounts; i++)
	    {
	      fprintf (file,
		       "    Block #%*d: executed %*ld time(s)",
		       blk_len, i+1,
		       cnt_len, ptr->counts[i]);

	      if (addr_p)
		fprintf (file, " address= 0x%.*lx", addr_len,
			 ptr->addresses[i]);

	      if (func_p)
		fprintf (file, " function= %-*s", func_len,
			 (ptr->functions[i]) ? ptr->functions[i] : "<none>");

	      if (line_p)
		fprintf (file, " line= %*ld", line_len, ptr->line_nums[i]);

	      if (file_p)
		fprintf (file, " file= %s",
			 (ptr->filenames[i]) ? ptr->filenames[i] : "<none>");

	      fprintf (file, "\n");
	    }

	  fprintf (file, "\n");
	  fflush (file);
	}

      fprintf (file, "\n\n");
      fclose (file);
    }
}

void
__bb_init_func (struct bb *blocks)
{
  /* User is supposed to check whether the first word is non-0,
     but just in case....  */

  if (blocks->zero_word)
    return;

  /* Initialize destructor.  */
  if (!bb_head)
    atexit (__bb_exit_func);

  /* Set up linked list.  */
  blocks->zero_word = 1;
  blocks->next = bb_head;
  bb_head = blocks;
}

/* Called before fork or exec - write out profile information gathered so
   far and reset it to zero.  This avoids duplication or loss of the
   profile information gathered so far.  */
void
__bb_fork_func (void)
{
  struct bb *ptr;

  __bb_exit_func ();
  for (ptr = bb_head; ptr != (struct bb *) 0; ptr = ptr->next)
    {
      long i;
      for (i = ptr->ncounts - 1; i >= 0; i--)
	ptr->counts[i] = 0;
    }
}

#ifndef MACHINE_STATE_SAVE
#define MACHINE_STATE_SAVE(ID)
#endif
#ifndef MACHINE_STATE_RESTORE
#define MACHINE_STATE_RESTORE(ID)
#endif

/* Number of buckets in hashtable of basic block addresses.  */

#define BB_BUCKETS 311

/* Maximum length of string in file bb.in.  */

#define BBINBUFSIZE 500

struct bb_edge
{
  struct bb_edge *next;
  unsigned long src_addr;
  unsigned long dst_addr;
  unsigned long count;
};

enum bb_func_mode
{
  TRACE_KEEP = 0, TRACE_ON = 1, TRACE_OFF = 2
};

struct bb_func
{
  struct bb_func *next;
  char *funcname;
  char *filename;
  enum bb_func_mode mode;
};

/* This is the connection to the outside world.
   The BLOCK_PROFILER macro must set __bb.blocks
   and __bb.blockno.  */

struct {
  unsigned long blockno;
  struct bb *blocks;
} __bb;

/* Vars to store addrs of source and destination basic blocks 
   of a jump.  */

static unsigned long bb_src = 0;
static unsigned long bb_dst = 0;

static FILE *bb_tracefile = (FILE *) 0;
static struct bb_edge **bb_hashbuckets = (struct bb_edge **) 0;
static struct bb_func *bb_func_head = (struct bb_func *) 0;
static unsigned long bb_callcount = 0;
static int bb_mode = 0;

static unsigned long *bb_stack = (unsigned long *) 0;
static size_t bb_stacksize = 0;

static int reported = 0;

/* Trace modes:
Always             :   Print execution frequencies of basic blocks
                       to file bb.out.
bb_mode & 1 != 0   :   Dump trace of basic blocks to file bbtrace[.gz]
bb_mode & 2 != 0   :   Print jump frequencies to file bb.out.
bb_mode & 4 != 0   :   Cut call instructions from basic block flow.
bb_mode & 8 != 0   :   Insert return instructions in basic block flow.
*/

#ifdef HAVE_POPEN

/*#include <sys/types.h>*/
#include <sys/stat.h>
/*#include <malloc.h>*/

/* Commands executed by gopen.  */

#define GOPENDECOMPRESS "gzip -cd "
#define GOPENCOMPRESS "gzip -c >"

/* Like fopen but pipes through gzip.  mode may only be "r" or "w".
   If it does not compile, simply replace gopen by fopen and delete
   '.gz' from any first parameter to gopen.  */

static FILE *
gopen (char *fn, char *mode)
{
  int use_gzip;
  char *p;

  if (mode[1])
    return (FILE *) 0;

  if (mode[0] != 'r' && mode[0] != 'w') 
    return (FILE *) 0;

  p = fn + strlen (fn)-1;
  use_gzip = ((p[-1] == '.' && (p[0] == 'Z' || p[0] == 'z'))
	      || (p[-2] == '.' && p[-1] == 'g' && p[0] == 'z'));

  if (use_gzip)
    {
      if (mode[0]=='r')
        {
          FILE *f;
          char *s = (char *) malloc (sizeof (char) * strlen (fn)
				     + sizeof (GOPENDECOMPRESS));
          strcpy (s, GOPENDECOMPRESS);
          strcpy (s + (sizeof (GOPENDECOMPRESS)-1), fn);
          f = popen (s, mode);
          free (s);
          return f;
        }

      else
        {
          FILE *f;
          char *s = (char *) malloc (sizeof (char) * strlen (fn)
				     + sizeof (GOPENCOMPRESS));
          strcpy (s, GOPENCOMPRESS);
          strcpy (s + (sizeof (GOPENCOMPRESS)-1), fn);
          if (!(f = popen (s, mode)))
            f = fopen (s, mode);
          free (s);
          return f;
        }
    }

  else
    return fopen (fn, mode);
}

static int
gclose (FILE *f)
{
  struct stat buf;

  if (f != 0)
    {
      if (!fstat (fileno (f), &buf) && S_ISFIFO (buf.st_mode))
        return pclose (f);

      return fclose (f);
    }
  return 0;
}

#endif /* HAVE_POPEN */

/* Called once per program.  */

static void
__bb_exit_trace_func (void)
{
  FILE *file = fopen ("bb.out", "a");
  struct bb_func *f;
  struct bb *b;
        
  if (!file)
    perror ("bb.out");

  if (bb_mode & 1)
    {
      if (!bb_tracefile)
        perror ("bbtrace");
      else
#ifdef HAVE_POPEN
        gclose (bb_tracefile);
#else
        fclose (bb_tracefile);
#endif /* HAVE_POPEN */
    }

  /* Check functions in `bb.in'.  */

  if (file)
    {
      long time_value;
      const struct bb_func *p;
      int printed_something = 0;
      struct bb *ptr;
      long blk;

      /* This is somewhat type incorrect.  */
      time ((void *) &time_value);

      for (p = bb_func_head; p != (struct bb_func *) 0; p = p->next)
        {
          for (ptr = bb_head; ptr != (struct bb *) 0; ptr = ptr->next)
            {
              if (!ptr->filename || (p->filename != (char *) 0 && strcmp (p->filename, ptr->filename)))
                continue;
              for (blk = 0; blk < ptr->ncounts; blk++)
                {
                  if (!strcmp (p->funcname, ptr->functions[blk]))
                    goto found;
                }
            }
  
          if (!printed_something)
            {
              fprintf (file, "Functions in `bb.in' not executed during basic block profiling on %s\n", ctime ((void *) &time_value));
              printed_something = 1;
            }

          fprintf (file, "\tFunction %s", p->funcname);
          if (p->filename)
              fprintf (file, " of file %s", p->filename);
          fprintf (file, "\n" );
  
found:        ;
        }

      if (printed_something)
       fprintf (file, "\n");

    }

  if (bb_mode & 2)
    {
      if (!bb_hashbuckets)
        {
          if (!reported)
            {
              fprintf (stderr, "Profiler: out of memory\n");
              reported = 1;
            }
          return;
        }
    
      else if (file)
        {
          long time_value;
          int i;
          unsigned long addr_max = 0;
          unsigned long cnt_max  = 0;
          int cnt_len;
          int addr_len;
    
          /* This is somewhat type incorrect, but it avoids worrying about
             exactly where time.h is included from.  It should be ok unless
             a void * differs from other pointer formats, or if sizeof (long)
             is < sizeof (time_t).  It would be nice if we could assume the
             use of rationale standards here.  */
    
          time ((void *) &time_value);
          fprintf (file, "Basic block jump tracing");

          switch (bb_mode & 12)
            {
              case 0:
                fprintf (file, " (with call)");
              break;

              case 4:
		/* Print nothing.  */
              break;

              case 8:
                fprintf (file, " (with call & ret)");
              break;

              case 12:
                fprintf (file, " (with ret)");
              break;
            }

          fprintf (file, " finished on %s\n", ctime ((void *) &time_value));
    
          for (i = 0; i < BB_BUCKETS; i++)
            {
               struct bb_edge *bucket = bb_hashbuckets[i];
               for ( ; bucket; bucket = bucket->next )
                 {
                   if (addr_max < bucket->src_addr) 
                     addr_max = bucket->src_addr;
                   if (addr_max < bucket->dst_addr) 
                     addr_max = bucket->dst_addr;
                   if (cnt_max < bucket->count) 
                     cnt_max = bucket->count;
                 }
            }
          addr_len = num_digits (addr_max, 16);
          cnt_len  = num_digits (cnt_max, 10);
    
          for ( i = 0; i < BB_BUCKETS; i++)
            {
               struct bb_edge *bucket = bb_hashbuckets[i];
               for ( ; bucket; bucket = bucket->next )
                 {
                   fprintf (file,
	"Jump from block 0x%.*lx to block 0x%.*lx executed %*lu time(s)\n", 
                            addr_len, bucket->src_addr, 
                            addr_len, bucket->dst_addr, 
                            cnt_len, bucket->count);
                 }
            }
  
          fprintf (file, "\n");

        }
    }

   if (file)
     fclose (file);

   /* Free allocated memory.  */

   f = bb_func_head;
   while (f)
     {
       struct bb_func *old = f;

       f = f->next;
       if (old->funcname) free (old->funcname);
       if (old->filename) free (old->filename);
       free (old);
     }

   if (bb_stack)
     free (bb_stack);

   if (bb_hashbuckets)
     {
       int i;

       for (i = 0; i < BB_BUCKETS; i++)
         {
           struct bb_edge *old, *bucket = bb_hashbuckets[i];

           while (bucket)
             {
               old = bucket;
               bucket = bucket->next;
               free (old);
             }
         }
       free (bb_hashbuckets);
     }

   for (b = bb_head; b; b = b->next)
     if (b->flags) free (b->flags);
}

/* Called once per program.  */

static void
__bb_init_prg (void)
{
  FILE *file;
  char buf[BBINBUFSIZE];
  const char *p;
  const char *pos;
  enum bb_func_mode m;
  int i;

  /* Initialize destructor.  */
  atexit (__bb_exit_func);

  if (!(file = fopen ("bb.in", "r")))
    return;

  while(fgets (buf, BBINBUFSIZE, file) != 0)
    {
      i = strlen (buf);
      if (buf[i-1] == '\n')
	buf[--i] = '\0';

      p = buf;
      if (*p == '-') 
        { 
          m = TRACE_OFF; 
          p++; 
        }
      else 
        { 
          m = TRACE_ON; 
        }
      if (!strcmp (p, "__bb_trace__"))
        bb_mode |= 1;
      else if (!strcmp (p, "__bb_jumps__"))
        bb_mode |= 2;
      else if (!strcmp (p, "__bb_hidecall__"))
        bb_mode |= 4;
      else if (!strcmp (p, "__bb_showret__"))
        bb_mode |= 8;
      else 
        {
          struct bb_func *f = (struct bb_func *) malloc (sizeof (struct bb_func));
          if (f)
            {
              unsigned long l;
              f->next = bb_func_head;
              if ((pos = strchr (p, ':')))
                {
                  if (!(f->funcname = (char *) malloc (strlen (pos+1)+1)))
                    continue;
                  strcpy (f->funcname, pos+1);
                  l = pos-p;
                  if ((f->filename = (char *) malloc (l+1)))
                    {
                      strncpy (f->filename, p, l);
                      f->filename[l] = '\0';
                    }
                  else
                    f->filename = (char *) 0;
                }
              else
                {
                  if (!(f->funcname = (char *) malloc (strlen (p)+1)))
                    continue;
                  strcpy (f->funcname, p);
                  f->filename = (char *) 0;
                }
              f->mode = m;
              bb_func_head = f;
	    }
         }
    }
  fclose (file);

#ifdef HAVE_POPEN 

  if (bb_mode & 1)
      bb_tracefile = gopen ("bbtrace.gz", "w");

#else

  if (bb_mode & 1)
      bb_tracefile = fopen ("bbtrace", "w");

#endif /* HAVE_POPEN */

  if (bb_mode & 2)
    {
      bb_hashbuckets = (struct bb_edge **) 
                   malloc (BB_BUCKETS * sizeof (struct bb_edge *));
      if (bb_hashbuckets)
	/* Use a loop here rather than calling bzero to avoid having to
	   conditionalize its existance.  */
	for (i = 0; i < BB_BUCKETS; i++)
	  bb_hashbuckets[i] = 0;
    }

  if (bb_mode & 12)
    {
      bb_stacksize = 10;
      bb_stack = (unsigned long *) malloc (bb_stacksize * sizeof (*bb_stack));
    }

  /* Initialize destructor.  */
  atexit (__bb_exit_trace_func);
}

/* Called upon entering a basic block.  */

void
__bb_trace_func (void)
{
  struct bb_edge *bucket;

  MACHINE_STATE_SAVE("1")

  if (!bb_callcount || (__bb.blocks->flags && (__bb.blocks->flags[__bb.blockno] & TRACE_OFF)))
    goto skip;

  bb_dst = __bb.blocks->addresses[__bb.blockno];
  __bb.blocks->counts[__bb.blockno]++;

  if (bb_tracefile)
    {
      fwrite (&bb_dst, sizeof (unsigned long), 1, bb_tracefile);
    }

  if (bb_hashbuckets)
    {
      struct bb_edge **startbucket, **oldnext;

      oldnext = startbucket
	= & bb_hashbuckets[ (((int) bb_src*8) ^ (int) bb_dst) % BB_BUCKETS ];
      bucket = *startbucket;

      for (bucket = *startbucket; bucket; 
           oldnext = &(bucket->next), bucket = *oldnext)
        {
          if (bucket->src_addr == bb_src
	      && bucket->dst_addr == bb_dst)
            {
              bucket->count++;
              *oldnext = bucket->next;
              bucket->next = *startbucket;
              *startbucket = bucket;
              goto ret;
            }
        }

      bucket = (struct bb_edge *) malloc (sizeof (struct bb_edge));

      if (!bucket)
        {
          if (!reported)
            {
              fprintf (stderr, "Profiler: out of memory\n");
              reported = 1;
            }
        }

      else
        {
          bucket->src_addr = bb_src;
          bucket->dst_addr = bb_dst;
          bucket->next = *startbucket;
          *startbucket = bucket;
          bucket->count = 1;
        }
    }

ret:
  bb_src = bb_dst;

skip:
  ;

  MACHINE_STATE_RESTORE("1")

}

/* Called when returning from a function and `__bb_showret__' is set.  */

static void
__bb_trace_func_ret (void)
{
  struct bb_edge *bucket;

  if (!bb_callcount || (__bb.blocks->flags && (__bb.blocks->flags[__bb.blockno] & TRACE_OFF)))
    goto skip;

  if (bb_hashbuckets)
    {
      struct bb_edge **startbucket, **oldnext;

      oldnext = startbucket
	= & bb_hashbuckets[ (((int) bb_dst * 8) ^ (int) bb_src) % BB_BUCKETS ];
      bucket = *startbucket;

      for (bucket = *startbucket; bucket; 
           oldnext = &(bucket->next), bucket = *oldnext)
        {
          if (bucket->src_addr == bb_dst
	       && bucket->dst_addr == bb_src)
            {
              bucket->count++;
              *oldnext = bucket->next;
              bucket->next = *startbucket;
              *startbucket = bucket;
              goto ret;
            }
        }

      bucket = (struct bb_edge *) malloc (sizeof (struct bb_edge));

      if (!bucket)
        {
          if (!reported)
            {
              fprintf (stderr, "Profiler: out of memory\n");
              reported = 1;
            }
        }

      else
        {
          bucket->src_addr = bb_dst;
          bucket->dst_addr = bb_src;
          bucket->next = *startbucket;
          *startbucket = bucket;
          bucket->count = 1;
        }
    }

ret:
  bb_dst = bb_src;

skip:
  ;

}

/* Called upon entering the first function of a file.  */

static void
__bb_init_file (struct bb *blocks)
{

  const struct bb_func *p;
  long blk, ncounts = blocks->ncounts;
  const char **functions = blocks->functions;

  /* Set up linked list.  */
  blocks->zero_word = 1;
  blocks->next = bb_head;
  bb_head = blocks;

  blocks->flags = 0;
  if (!bb_func_head
      || !(blocks->flags = (char *) malloc (sizeof (char) * blocks->ncounts)))
    return;

  for (blk = 0; blk < ncounts; blk++)
    blocks->flags[blk] = 0;

  for (blk = 0; blk < ncounts; blk++)
    {
      for (p = bb_func_head; p; p = p->next)
        {
          if (!strcmp (p->funcname, functions[blk])
	      && (!p->filename || !strcmp (p->filename, blocks->filename)))
            {
              blocks->flags[blk] |= p->mode;
            }
        }
    }

}

/* Called when exiting from a function.  */

void
__bb_trace_ret (void)
{

  MACHINE_STATE_SAVE("2")

  if (bb_callcount)
    {
      if ((bb_mode & 12) && bb_stacksize > bb_callcount)
        {
          bb_src = bb_stack[bb_callcount];
          if (bb_mode & 8)
            __bb_trace_func_ret ();
        }

      bb_callcount -= 1;
    }

  MACHINE_STATE_RESTORE("2")

}

/* Called when entering a function.  */

void
__bb_init_trace_func (struct bb *blocks, unsigned long blockno)
{
  static int trace_init = 0;

  MACHINE_STATE_SAVE("3")

  if (!blocks->zero_word)
    { 
      if (!trace_init)
        { 
          trace_init = 1;
          __bb_init_prg ();
        }
      __bb_init_file (blocks);
    }

  if (bb_callcount)
    {

      bb_callcount += 1;

      if (bb_mode & 12)
        {
          if (bb_callcount >= bb_stacksize)
            {
              size_t newsize = bb_callcount + 100;

              bb_stack = (unsigned long *) realloc (bb_stack, newsize);
              if (! bb_stack)
                {
                  if (!reported)
                    {
                      fprintf (stderr, "Profiler: out of memory\n");
                      reported = 1;
                    }
                  bb_stacksize = 0;
                  goto stack_overflow;
                }
	      bb_stacksize = newsize;
            }
          bb_stack[bb_callcount] = bb_src;

          if (bb_mode & 4)
            bb_src = 0;

        }

stack_overflow:;

    }

  else if (blocks->flags && (blocks->flags[blockno] & TRACE_ON))
    {
      bb_callcount = 1;
      bb_src = 0;

      if (bb_stack)
          bb_stack[bb_callcount] = bb_src;
    }

  MACHINE_STATE_RESTORE("3")
}

