#ifndef _DIRENT_H
#define _DIRENT_H       1

#include <sys/cdefs.h>
#include <sys/types.h>
#include <limits.h>

__BEGIN_DECLS

struct dirent {
  long		d_ino;
  off_t		d_off;
  uint16_t	d_reclen;
  char		d_name[256]; /* We must not include limits.h! */
};

#if !defined(__STRICT_ANSI__) || __STDC_VERSION__ + 0 >= 199900L
struct dirent64 {
  uint64_t	d_ino;
  int64_t	d_off;
  uint16_t	d_reclen;
  unsigned char	d_type;
  char		d_name[256];
};
#endif

#define d_fileno	d_ino	/* Backwards compatibility.  */

#undef  _DIRENT_HAVE_D_NAMLEN
#define _DIRENT_HAVE_D_RECLEN
#define _DIRENT_HAVE_D_OFF

typedef struct __dirstream DIR;

DIR *opendir (const char *__name) __THROW;
int closedir (DIR *__dirp) __THROW;
struct dirent *readdir (DIR *__dirp) __THROW;
struct dirent64 *readdir64 (DIR *__dirp) __THROW;
void rewinddir (DIR *__dirp) __THROW;
void seekdir (DIR *__dirp, long int __pos) __THROW;
long int telldir (DIR *__dirp) __THROW;

int scandir(const char *dir, struct dirent ***namelist,
      int (*selection)(const struct dirent *),
      int (*compar)(const struct dirent **, const struct dirent **));
int scandir64(const char *dir, struct dirent64 ***namelist,
      int (*selection)(const struct dirent64 *),
      int (*compar)(const struct dirent64 **, const struct dirent64 **));

int alphasort(const struct dirent **a, const struct dirent **b) __THROW __attribute__((const));
int alphasort64(const struct dirent64 **a, const struct dirent64 **b) __THROW __attribute__((const));

#define MAXNAMLEN NAME_MAX

#ifdef _BSD_SOURCE
extern int dirfd(DIR *dirp) __THROW __attribute_dontuse__;
#endif

#if defined _FILE_OFFSET_BITS && _FILE_OFFSET_BITS == 64
#define dirent dirent64
#define readdir readdir64
#define scandir scandir64
#define alphasort alphasort64
#endif

#ifdef _BSD_SOURCE
/* File types for `d_type'.  */
enum
  {
    DT_UNKNOWN = 0,
# define DT_UNKNOWN	DT_UNKNOWN
    DT_FIFO = 1,
# define DT_FIFO	DT_FIFO
    DT_CHR = 2,
# define DT_CHR		DT_CHR
    DT_DIR = 4,
# define DT_DIR		DT_DIR
    DT_BLK = 6,
# define DT_BLK		DT_BLK
    DT_REG = 8,
# define DT_REG		DT_REG
    DT_LNK = 10,
# define DT_LNK		DT_LNK
    DT_SOCK = 12,
# define DT_SOCK	DT_SOCK
    DT_WHT = 14
# define DT_WHT		DT_WHT
  };

/* Convert between stat structure types and directory types.  */
# define IFTODT(mode)	(((mode) & 0170000) >> 12)
# define DTTOIF(dirtype)	((dirtype) << 12)
#endif

__END_DECLS

#endif
