/* FIXME: From sys/sysvi386/sys */
#ifndef _SYS_DIRENT_H
# define _SYS_DIRENT_H

/*
 * This file was written to be compatible with the BSD directory
 * routines, so it looks like it.  But it was written from scratch.
 * Sean Eric Fagan, sef@Kithrup.COM
 *
 * Modified by dje@cygnus.com for sun.
 * Modified by eichin@cygnus.com for decstation (ultrix 4.2)
 */

typedef struct __dirdesc {
	int	dd_fd;
	long	dd_loc;
	long	dd_size;
	long	dd_bbase;
	long	dd_entno;
	long	dd_bsize;
	char	*dd_buf;
} DIR;

# define __dirfd(dp)	((dp)->dd_fd)

DIR *opendir (const char *);
struct dirent *readdir (DIR *);
void rewinddir (DIR *);
int closedir (DIR *);

#include <sys/types.h>

#define MAXNAMLEN	255

#define d_ino	d_fileno	/* compatibility */

struct dirent {
	unsigned long	d_fileno;
	unsigned short	d_reclen;
	unsigned short	d_namlen;
	char		d_name[MAXNAMLEN + 1];
};

/* FIXME: include definition of DIRSIZ() ? */

#endif
