#ifndef _AR_H
#define _AR_H

/* this header is obsolete, don't rely on it! */

#include <sys/cdefs.h>

#define ARMAG	"!<arch>\n"	/* String that begins an archive file.  */
#define SARMAG	8		/* Size of that string.  */

#define ARFMAG	"`\n"		/* String in ar_fmag at end of each header.  */

__BEGIN_DECLS

struct ar_hdr
  {
    char ar_name[16];		/* Member file name, sometimes / terminated. */
    char ar_date[12];		/* File date, decimal seconds since Epoch.  */
    char ar_uid[6], ar_gid[6];	/* User and group IDs, in ASCII decimal.  */
    char ar_mode[8];		/* File mode, in ASCII octal.  */
    char ar_size[10];		/* File size, in ASCII decimal.  */
    char ar_fmag[2];		/* Always contains ARFMAG.  */
  };

__END_DECLS

#endif
