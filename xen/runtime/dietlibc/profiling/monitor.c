/**************************************************************
   Copyright (C) 2001, 2002 Thomas M. Ogrisegg

   This is free software. You can redistribute and modify
   it under the terms of the GNU General Public License.

   This file is part of the profiling support for dietlibc

   monitor(3) interface

 *************************************************************/
#include <sys/uio.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <sys/gmon.h>

typedef unsigned short u_short;

struct monparam mparam;

void monitor (unsigned long, unsigned long) PROF_SECTION;
void _stop_monitor (void) PROF_SECTION;

/*
  monitor is called by _start, to start profiling
  lowpc  -> lowest valid program counter  (normally .text)
  highpc -> highest valid program counter (normally _etext)
*/
void
monitor (unsigned long lowpc, unsigned long highpc)
{
	mparam.highpc     = highpc;
	mparam.lowpc      = lowpc;
	mparam.kcountsize = (mparam.textsize = highpc-lowpc) << 1;
	mparam.kcount = (u_short *) malloc (mparam.kcountsize);
	mparam.arcs = (struct rawarc *) malloc (MAXARCS*sizeof (struct rawarc));
	if (!mparam.kcount || !mparam.arcs)
		exit (42);
	mparam.arcnum = 0;
	/* start profiling */
	profil (mparam.kcount, highpc-lowpc, lowpc, 10000);
}

/*
  write_gmon - write all data collected by the helper routines
  to gmon.out
*/
static void
write_gmon (void)
{
	struct gmon_hdr ghdr = { "gmon", 1, "" };
	int fd = open ("gmon.out", O_CREAT | O_RDWR | O_TRUNC, 0666);

	if (fd < 0) return;
	write (fd, &ghdr, sizeof (ghdr));
	if (mparam.kcountsize)
	{
		char tag = GMON_TAG_TIME_HIST;
		struct gmon_hist_hdr ghdr = {
			mparam.lowpc, mparam.highpc,
			(mparam.kcountsize >> 1), 100, "seconds", 's' 
		};
		struct iovec iov[3] = {
			{ &tag,  sizeof (tag)  },
			{ &ghdr, sizeof (ghdr) },
			{ mparam.kcount, mparam.kcountsize >> 1 << 1 }
		};
		writev (fd, iov, 3);
	}
	if (mparam.arcnum)
	{
		char tag = GMON_TAG_CG_ARC;
		struct iovec iov[mparam.arcnum*2];
		unsigned long l;
		for (l=0;l<mparam.arcnum;l++) {
			iov[l*2].iov_base = &tag;
			iov[l*2].iov_len  = sizeof (tag);
			iov[l*2+1].iov_base = &mparam.arcs[l];
			iov[l*2+1].iov_len  = sizeof (mparam.arcs[l]);
		}
		writev (fd, iov, mparam.arcnum*2);
	}
	close (fd);
}

/* called by _start before exit */
void
_stop_monitor (void)
{
	profil (NULL, 0, 0, 0);
	write_gmon ();
}
