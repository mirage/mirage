/* Cache code for SPARClite
 *
 * Copyright (c) 1998 Cygnus Support
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */

#include "sparclite.h"

/* Ancillary registers on the DANlite */

#define DIAG 30
#define ICCR 31

/* Bits in the DIAG register */

#define ICD 0x40000000		/* ICACHE disable */
#define DCD 0x20000000		/* DCACHE disable */

/* Bits in the ICCR register */

#define CE 1			/* cache enable*/


/* Forward declarations. */

void flush_i_cache ();


/* Determine if this is a DANlite (MB8686x), as opposed to an earlier
   SPARClite (MB8683x).  This is done by examining the impl and ver
   fields in the PSR:

   MB8683x: impl(bit31-28)=0x0; ver(bit27-24)=0xf;
   MB8686x: impl(bit31-28)=0x1; ver(bit27-24)=0xe;
*/

static int
is_danlite ()
{
  static int checked = 0;
  static int danlite = 0;
  
  if (!checked)
    {
      int psr = read_psr ();
      danlite = (psr & 0xff000000) == 0x1e000000;
      checked = 1;
    }
  return danlite;
}

/* This cache code is known to work on both the 930 & 932 processors.  It just
   cheats and clears the all of the address space that could contain tags, as
   opposed to striding the tags at 8 or 16 word intervals, or using the cache
   flush registers, which don't exist on all processors.  */

void
cache_off ()
{
  if (is_danlite ())
    {
      /* Disable the ICACHE.  Disabling the DCACHE crashes the machine. */
      unsigned int diag = read_asr (DIAG);
      write_asr (DIAG, diag | ICD);
    }
  else
    {
      write_asi (1, 0, 0);
    }
}

void
cache_on ()
{
  if (is_danlite ())
    {
      unsigned int diag;

      /* Flush the caches. */
      flush_i_cache ();

      /* Enable the ICACHE and DCACHE */
      diag = read_asr (DIAG);
      write_asr (DIAG, diag & ~ (ICD | DCD));
    }
  else
    {
      unsigned long addr;

      cache_off ();			/* Make sure the cache is off */

      /* Reset all of the cache line valid bits */

      for (addr = 0; addr < 0x1000; addr += 8)
	{
	  write_asi (0xc, addr, 0);	/* Clear bank 1, icache */
	  write_asi (0xc, addr + 0x80000000, 0); /* Clear bank 2, icache */

	  write_asi (0xe, addr, 0);	/* Clear bank 1, dcache */
	  write_asi (0xe, addr + 0x80000000, 0); /* Clear bank 2, dcache */
	}

      /* turn on the cache */

      write_asi (1, 0, 0x35);	/* Write buf ena, prefetch buf ena, data
				       & inst caches enab */
    }
}

/* Flush the instruction cache.  We need to do this for the debugger stub so
   that breakpoints, et. al. become visible to the instruction stream after
   storing them in memory.
 */

void
flush_i_cache ()
{
  if (is_danlite ())
    {
      write_asi (0x31, 0, 0);	/* Flush entire i/d caches */
    }
  else
    {
      int cache_reg;
      unsigned long addr;

      cache_reg = read_asi (1, 0);	/* Read cache/bus interface reg */

      if (!(cache_reg & 1))
	return;			/* Just return if cache is already off */

      for (addr = 0; addr < 0x1000; addr += 8)
	{
	  write_asi (0xc, addr, 0);	/* Clear bank 1, icache */
	  write_asi (0xc, addr + 0x80000000, 0); /* Clear bank 2, icache */
	}
    }
}
