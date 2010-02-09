#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <stdlib.h>
#include "dietfeatures.h"

/*
 * by Olaf Dreesen
 *
 * arm			NO SMP ?!? (return 1)
 *
 * alpha	->	cpus detected\t\t: <nr>\n
 * sparc	->	ncpus active\t: <nr>\n
 *
 * default	->	processor\t: <cpunr>\n	(one per cpu)
 */

#ifdef SLASH_PROC_OK
int __sc_nr_cpus(void);
int __sc_nr_cpus() {
#if defined(__arm__)
  return 1;
#else
  int fd;
  fd = open("/proc/cpuinfo", O_RDONLY);
  if (fd==-1) return 1; /* fallback if no proc-fs mounted */
  else {
    int n,nr=0;
    char buf[2048]; /* holds ~6 cpuinfos */

    while((n=read(fd,buf,sizeof(buf)))>0) {
      register int i=0;
      while (i<n) {
#if defined(__alpha__)
	if ((buf[i]=='c')&&(!memcmp(buf+i,"cpus detected",13))) {
	  i+=17;
	  nr=atoi(buf+i);
	  break;
	}
#elif defined(__sparc__)
	if ((buf[i]=='n')&&(!memcmp(buf+i,"ncpus active",12))) {
	  i+=15;
	  nr=atoi(buf+i);
	  break;
	}
#else	/* DEFAULT */
	if ((buf[i]=='p')&&(!memcmp(buf+i,"processor",9))) {
	  ++nr;
	  i+=9;
	}
#endif
	while(buf[i++]!='\n');	/* skip rest of line */
      }
    }
    close(fd);
    return nr;
  }
#endif
}
#else
int __sc_nr_cpus() {
  return 1;	/* kludge kludge ;-) */
}
#endif
