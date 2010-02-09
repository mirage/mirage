/*
 * (c) 2003 Andreas Krennmair <krennmair@webdynamite.com>
 */
#include <dietwarning.h>
#define _BSD_SOURCE
#include <sys/time.h>
#include <utime.h>
#include <sys/types.h>

int utimes(const char *filename, struct timeval *tvp) {
  struct utimbuf b;
  if (!tvp) {
    return utime(filename,NULL);
  }
  b.actime = tvp[0].tv_sec;
  b.modtime = tvp[1].tv_sec;
  return utime(filename,&b);
}

link_warning("utimes","utimes is obsolete junk, don't use!");
