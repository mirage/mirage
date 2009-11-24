/* FIXME: From sys/sysvi386/sys */
#ifndef _SYS_DIRENT_H
# define _SYS_DIRENT_H

/*
 * This file was written to be compatible with the BSD directory
 * routines, so it looks like it.  But it was written from scratch.
 * Sean Eric Fagan, sef@Kithrup.COM
 */

typedef struct __dirdesc {
	int	dd_fd;
	long	dd_loc;
	long	dd_size;
	char	*dd_buf;
	int	dd_len;
	long	dd_seek;
} DIR;

# define __dirfd(dp)	((dp)->dd_fd)

DIR *opendir (const char *);
struct dirent *readdir (DIR *);
void rewinddir (DIR *);
int closedir (DIR *);

#include <sys/types.h>

#undef  MAXNAMLEN	/* from unistd.h */
#ifdef __svr4__
#define MAXNAMLEN	512
#else
#define MAXNAMLEN	255
#endif

#define d_ino	d_fileno	/* compatibility */

struct dirent {
	off_t		d_off;
	unsigned long	d_fileno;
	unsigned short	d_reclen;
	unsigned short	d_namlen;
	char		d_name[MAXNAMLEN + 1];
};

/* FIXME: include definition of DIRSIZ() ? */

#endif
