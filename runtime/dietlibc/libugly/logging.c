#include <errno.h>
#include "dietfeatures.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <syslog.h>
#include <string.h>
#include <time.h>
#include <sys/socket.h>
#include <signal.h>

#define _PATH_CONSOLE	"/dev/console"
#define BUF_SIZE 2048	/* messagebuffer size (>= 200) */

#define MAX_LOGTAG 1000

/* declare internal functions */
int __libc_open(const char*name,int flags, ...);
ssize_t __libc_write(int fd,void*buf,size_t len);
int __libc_fcntl(int fd,int op,...);
int __libc_close(int fd);

/* those have to be global *sigh* */
static volatile int	connected;	/* have done connect */
static volatile int	LogMask = 0xff; /* mask of priorities to be logged */
static char		LogTag[MAX_LOGTAG];	/* string to tag the entry with */
static int		LogFile = -1;   /* fd for log */
static int		LogType = SOCK_DGRAM; /* type of socket connection */
static int		LogFacility = LOG_USER; /* default facility code */
static int		LogStat;	/* status bits, set by openlog() */
extern char		*__progname;	/* Program name, from crt0. */
static struct sockaddr	SyslogAddr;	/* AF_UNIX address of local logger */

static void closelog_intern(void)
{
  if (!connected) return;
  __libc_close(LogFile);
  LogFile = -1;
  connected = 0;
}

void __libc_closelog(void);
void __libc_closelog(void)
{
  closelog_intern();

  LogTag[0]=0;
  LogType = SOCK_DGRAM;
}
void closelog(void) __attribute__((weak,alias("__libc_closelog")));

static void openlog_intern(int option, int facility)
{
  LogStat = option;
  if (facility && ((facility & ~LOG_FACMASK) == 0))
    LogFacility = facility;

  /* yep, there is a continue inside ;) */
  while(1) {
    if (LogFile == -1) {
      SyslogAddr.sa_family = AF_UNIX;
      strncpy(SyslogAddr.sa_data, _PATH_LOG, sizeof(SyslogAddr.sa_data));
      if (LogStat & LOG_NDELAY)
      {
	if ((LogFile = socket(AF_UNIX, LogType, 0)) == -1) return;
	__libc_fcntl(LogFile, F_SETFD, 1);
      }
    }
    if ((LogFile != -1) && !connected) {
      int old_errno=errno;
      if(connect(LogFile, &SyslogAddr, sizeof(SyslogAddr)) == -1) {
	int saved_errno=errno;
	__libc_close(LogFile);
	LogFile = -1;
	if((LogType == SOCK_DGRAM) && (saved_errno == EPROTOTYPE)) {
	  /* retry with SOCK_STREAM instead of SOCK_DGRAM */
	  LogType = SOCK_STREAM;
	  errno=old_errno;
	  continue;
	}
      }
      else connected = 1;
    }
    break;
  }
}

/* has to be secured against multiple, simultanious call's in threaded environment */
void __libc_openlog(const char *ident, int option, int facility);
void __libc_openlog(const char *ident, int option, int facility)
{
  if (ident) {
    strncpy(LogTag,ident,MAX_LOGTAG);
    LogTag[MAX_LOGTAG-1]=0;
  }
  openlog_intern(option, facility);
}
void openlog(const char *ident, int option, int facility) __attribute__((weak,alias("__libc_openlog")));

int setlogmask(int mask)
{
  int old = LogMask;
  if (mask) LogMask = mask;
  return old;
}

void __libc_vsyslog(int priority, const char *format, va_list arg_ptr);
void __libc_vsyslog(int priority, const char *format, va_list arg_ptr)
{
  char buffer[BUF_SIZE];
  char time_buf[20];
  int buflen, headerlen;
  time_t now;
  struct tm now_tm;
  pid_t pid;
  int fd;
  int sigpipe;
  struct sigaction action, oldaction;
  struct sigaction *oldaction_ptr = NULL;
  int saved_errno = errno;

  /* check for invalid priority/facility bits */
  if (priority & ~(LOG_PRIMASK|LOG_FACMASK)) {
    syslog(LOG_ERR|LOG_CONS|LOG_PERROR|LOG_PID, "syslog: unknown facility/priorityority: %x", priority);
    priority &= LOG_PRIMASK|LOG_FACMASK;
  }

  /* check priority against setlogmask */
  if ((LOG_MASK(LOG_PRI(priority)) && LogMask) == 0) return;

  /* Set default facility if none specified. */
  if ((priority & LOG_FACMASK) == 0) priority |= LogFacility;

  pid = getpid();
  time(&now);
  strftime(time_buf, 20, "%h %e %T", localtime_r (&now, &now_tm));

  if (LogStat & LOG_PID)
    headerlen = snprintf(buffer, 130, "<%d>%s %s[%ld]: ", priority, time_buf, LogTag, (long) pid);
  else
    headerlen = snprintf(buffer, 130, "<%d>%s %s: ", priority, time_buf, LogTag);

  if (!LogTag[0]) {
    if ((LogStat & LOG_PID) != LOG_PID)
      headerlen = snprintf(buffer, 130, "<%d>%s (unknown)[%ld]: ", priority, time_buf, (long) pid);
    strcat(buffer+headerlen, "syslog without openlog w/ ident, please check code!");
    buflen = 41;
  }
  else {
    errno=saved_errno;
    buflen = vsnprintf(buffer+headerlen, BUF_SIZE - headerlen, format, arg_ptr);
  }
  if (LogStat & LOG_PERROR) {
    __libc_write(1, buffer+headerlen, buflen);
    if (buffer[headerlen+buflen] != '\n') __libc_write(1,"\n", 1);
  }

  /* prepare for broken connection */
  memset(&action, 0, sizeof(action));
  action.sa_handler = SIG_IGN;
  sigemptyset(&action.sa_mask);

  if ((sigpipe = sigaction (SIGPIPE, &action, &oldaction))==0)
    oldaction_ptr = &oldaction;

  if (!connected) openlog_intern(LogStat | LOG_NDELAY, 0);

  /* If we have a SOCK_STREAM connection, also send ASCII NUL as a
   * record terminator. */
  if (LogType == SOCK_STREAM) buflen++;

  if (!connected || (send(LogFile, buffer, buflen+headerlen, 0) != buflen+headerlen)) {
    if (LogType == SOCK_STREAM) buflen--;
    closelog_intern();
    /*
     * Output the message to the console; don't worry about blocking,
     * if console blocks everything will.  Make sure the error reported
     * is the one from the syslogd failure.
     */
    if ((LogStat & LOG_CONS) &&
       ((fd = __libc_open(_PATH_CONSOLE, O_WRONLY|O_NOCTTY, 0)) >= 0))
    {
      __libc_write(fd, buffer, buflen+headerlen);
      __libc_write(fd, "\r\n", 2);
      __libc_close(fd);
    }
  }

  if (sigpipe == 0)
    sigaction(SIGPIPE, &oldaction, (struct sigaction *) NULL);
}
void vsyslog(int priority, const char *format, va_list arg_ptr) __attribute__((weak,alias("__libc_vsyslog")));

void syslog(int priority, const char *format, ...)
{
  va_list arg_ptr;
  va_start(arg_ptr, format);
  vsyslog(priority, format, arg_ptr);
  va_end(arg_ptr);
}
