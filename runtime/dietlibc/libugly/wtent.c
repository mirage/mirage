#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <utmp.h>

void updwtmp(const char *wtmp_file, const struct utmp *ut) {
  int fd = open(wtmp_file, O_WRONLY|O_APPEND);
  if (fd<0) return;
  fcntl (fd, F_SETFD, FD_CLOEXEC);
  write(fd, ut, sizeof(struct utmp));
  close(fd);
}

void logwtmp(const char *line, const char *name, const char *host) {
  struct utmp ut;

  memset(&ut, 0, sizeof(struct utmp));

  ut.ut_pid = getpid ();
  ut.ut_type = name[0] ? USER_PROCESS : DEAD_PROCESS;

  memccpy (ut.ut_line, line, 0, sizeof ut.ut_line);
  memccpy (ut.ut_name, name, 0, sizeof ut.ut_name);
  memccpy (ut.ut_host, host, 0, sizeof ut.ut_host);

  if (sizeof(ut.ut_tv) == sizeof(struct timeval))
    gettimeofday((struct timeval *)&ut.ut_tv, NULL);
  else {
	struct timeval tv;
	gettimeofday(&tv, NULL);
	ut.ut_tv.tv_sec = tv.tv_sec;
	ut.ut_tv.tv_usec = tv.tv_usec;
  }

  updwtmp (_PATH_WTMP, &ut);
}

