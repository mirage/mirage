#ifndef _SYS_TIMEX_H
#define _SYS_TIMEX_H

#include <sys/cdefs.h>
#include <sys/types.h>

__BEGIN_DECLS

struct timex {
  uint32_t modes;	/* mode selector */
  long int offset;	/* time offset (usec) */
  long int freq;	/* frequency offset (scaled ppm) */
  long int maxerror;	/* maximum error (usec) */
  long int esterror;	/* estimated error (usec) */
  int32_t status;	/* clock command/status */
  long int constant;	/* pll time constant */
  long int precision;	/* clock precision (usec) (read only) */
  long int tolerance;	/* clock frequency tolerance (ppm) (read only) */
  struct timeval time;	/* (read only) */
  long int tick;	/* (modified) usecs between clock ticks */

  long int ppsfreq;	/* pps frequency (scaled ppm) (ro) */
  long int jitter;	/* pps jitter (us) (ro) */
  int32_t shift;	/* interval duration (s) (shift) (ro) */
  long int stabil;	/* pps stability (scaled ppm) (ro) */
  long int jitcnt;	/* jitter limit exceeded (ro) */
  long int calcnt;	/* calibration intervals (ro) */
  long int errcnt;	/* calibration errors (ro) */
  long int stbcnt;	/* stability limit exceeded (ro) */

  /* ??? */
  int32_t  :32; int32_t  :32; int32_t  :32; int32_t  :32;
  int32_t  :32; int32_t  :32; int32_t  :32; int32_t  :32;
  int32_t  :32; int32_t  :32; int32_t  :32; int32_t  :32;
};

#define ADJ_OFFSET            0x0001 /* time offset */
#define ADJ_FREQUENCY         0x0002 /* frequency offset */
#define ADJ_MAXERROR          0x0004 /* maximum time error */
#define ADJ_ESTERROR          0x0008 /* estimated time error */
#define ADJ_STATUS            0x0010 /* clock status */
#define ADJ_TIMECONST         0x0020 /* pll time constant */
#define ADJ_TICK              0x4000 /* tick value */
#define ADJ_OFFSET_SINGLESHOT 0x8001 /* old-fashioned adjtime */

#define TIME_OK   0 /* clock synchronized */
#define TIME_INS  1 /* insert leap second */
#define TIME_DEL  2 /* delete leap second */
#define TIME_OOP  3 /* leap second in progress */
#define TIME_WAIT 4 /* leap second has occurred */
#define TIME_BAD  5 /* clock not synchronized */

int adjtimex(struct timex *buf);

__END_DECLS

#endif
