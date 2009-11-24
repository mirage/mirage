#ifndef _SYS_DIRENT_H
# define _SYS_DIRENT_H

#ifdef __cplusplus
extern "C" {
#endif

/*
 * This file was written to be compatible with the BSD directory
 * routines, so it looks like it.  But it was written from scratch.
 * Sean Eric Fagan, sef@Kithrup.COM
 *
 *  Copied to RTEMS configuration without modification.
 */

typedef struct _dirdesc {
	int	dd_fd;
	long	dd_loc;
	long	dd_size;
	char	*dd_buf;
	int	dd_len;
	long	dd_seek;
} DIR;

# define __dirfd(dp)	((dp)->dd_fd)

DIR *opendir(const char *);
struct dirent *readdir(DIR *);
void rewinddir(DIR *);
int closedir(DIR *);
void seekdir(DIR *dir, long loc);
long telldir(DIR *dir);

#include <sys/types.h>

#include <limits.h>

struct dirent {
	long	d_ino;
	off_t	d_off;
	unsigned short	d_reclen;
	/* we need better syntax for variable-sized arrays */
	unsigned short	d_namlen;
	char		d_name[NAME_MAX + 1];
};

int scandir ( const char *dirname,
   struct dirent *** namelist,
   int (*select)(struct dirent *),
   int (*dcomp)(const struct dirent **, const struct dirent **)
);

#ifdef __cplusplus
}
#endif 


#endif
