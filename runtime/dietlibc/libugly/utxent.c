#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>
#include <utmpx.h>
#include <signal.h>

static const char *utmp_file_name = _PATH_UTMPX;
static int fd = -1;
static off_t utmp_current = 0;

/* Forward declaration for utmp common functions */
void *__utmp_io(int fd, void *ut, ssize_t len, off_t *offset, int type);
sigset_t *__utmp_block_signals (sigset_t *oldset);

/* See libcompat for utmpxname() */
void __utmpxname(const char *file);   /* keep the compiler happy */
void __utmpxname(const char *file) {
  if (file)
    utmp_file_name = file;
  else
    utmp_file_name = _PATH_UTMPX;
}

void setutxent() {
  sigset_t oldset, *savedset;

  savedset = __utmp_block_signals(&oldset);
  if (fd<0) fd = open(utmp_file_name,O_RDWR);
  if (fd<0) fd = open(utmp_file_name,O_RDONLY);
  fcntl (fd, F_SETFD, FD_CLOEXEC);
  utmp_current = lseek(fd,0,SEEK_SET);
  if (savedset)
      sigprocmask (SIG_SETMASK, savedset, 0);
}

void endutxent() {
  if (fd<0) return;
  close(fd); fd=-1;
  utmp_current = 0;
}

struct utmpx *getutxent(void) {
  static struct utmpx getutent_tmp, *retval;
  ssize_t ret;
  sigset_t oldset, *savedset;

  if (fd<0) {
    setutxent();
    if (fd<0) return 0;
  }
  savedset = __utmp_block_signals (&oldset);

  retval = __utmp_io(fd, &getutent_tmp, sizeof(struct utmpx),
	      &utmp_current, F_RDLCK);

  if (savedset)
      sigprocmask (SIG_SETMASK, savedset, 0);

  return retval;
}

struct utmpx *getutxid(struct utmpx *ut) {
  struct utmpx *tmp;

  while ((tmp = getutxent())) {
    if (ut->ut_type && (ut->ut_type <= OLD_TIME)) {
      if (ut->ut_type == tmp->ut_type) break;
    }
    if ((ut->ut_type >= INIT_PROCESS) && (ut->ut_type <= DEAD_PROCESS)) {
      if (!strncmp(ut->ut_id,tmp->ut_id,4)) break;
    }
  }
  return tmp;
}

struct utmpx *getutxline(struct utmpx *ut) {
  struct utmpx *tmp;

  while ((tmp = getutxent())) {
    if ((tmp->ut_type == USER_PROCESS) || (tmp->ut_type == LOGIN_PROCESS)) {
      if (!strncmp(ut->ut_line,tmp->ut_line,__UT_LINESIZE)) break;
    }
  }
  return tmp;
}

struct utmpx *pututxline(struct utmpx *ut) {
  struct utmpx *tmp, ut_copy, *retval = 0, *result;
  int e;
  ssize_t bytes_written;
  sigset_t oldset, *savedset;

  /* It's kosher to call this function with a pointer to our own static
   * utmp structure, so work with a copy of "ut" */

  memcpy (&ut_copy, ut, sizeof (struct utmpx));

  savedset = __utmp_block_signals (&oldset);

  /* Seek to the current record before searching. */
  lseek (fd, utmp_current, SEEK_SET);
  if ((tmp = getutxid(&ut_copy))) {
    lseek(fd, - (off_t)sizeof(struct utmpx), SEEK_CUR);
    result = __utmp_io (fd, &ut_copy, sizeof(struct utmpx),
	    &utmp_current, F_WRLCK);
    e = errno;
  } else {
    utmp_current = lseek(fd, 0, SEEK_END);
    result = __utmp_io (fd, &ut_copy, sizeof(struct utmpx),
	    &utmp_current, F_WRLCK);
    e = errno;
  }
  if (savedset)
      sigprocmask (SIG_SETMASK, savedset, 0);

  if (result) {
      retval = ut;
  }

  memcpy (ut, &ut_copy, sizeof (struct utmpx));
  errno = e;
  return retval;
}

