#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <utmp.h>

static const char *utmp_file_name = _PATH_UTMP;
static int fd = -1;
static off_t utmp_current = 0;

static int lock_record(int type) {
  struct flock fl;
  fl.l_whence	= SEEK_CUR;
  fl.l_start	= 0;
  fl.l_len	= sizeof(struct utmp);
  fl.l_pid	= 0;
  fl.l_type	= type;
  return fcntl(fd, F_SETLKW, &fl);
}

static int unlock_record() {
  struct flock fl;
  fl.l_whence	= SEEK_CUR;
  fl.l_start	= -sizeof(struct utmp);
  fl.l_len	= sizeof(struct utmp);
  fl.l_pid	= 0;
  fl.l_type	= F_UNLCK;
  return fcntl(fd, F_SETLK, &fl);
}

void utmpname(const char *file) {
  if (file)
    utmp_file_name = file;
  else
    utmp_file_name = _PATH_UTMP;
}

void setutent() {
  if (fd<0) fd = open(utmp_file_name,O_RDWR);
  if (fd<0) fd = open(utmp_file_name,O_RDONLY);
  fcntl (fd, F_SETFD, FD_CLOEXEC);
  utmp_current = lseek(fd,0,SEEK_SET);
}

void endutent() {
  if (fd<0) return;
  close(fd); fd=-1;
  utmp_current = 0;
}

struct utmp *getutent(void) {
  static struct utmp getutent_tmp;
  ssize_t ret;

  if (fd<0) {
    setutent();
    if (fd<0) return 0;
  }
  utmp_current = lseek (fd, 0, SEEK_CUR);
  if (lock_record(F_RDLCK)) return 0;
  ret=read(fd, &getutent_tmp, sizeof(struct utmp));
  unlock_record();
  if (ret<1) return 0;
  return &getutent_tmp;
}

struct utmp *getutid(struct utmp *ut) {
  struct utmp *tmp;

  while ((tmp = getutent())) {
    if (ut->ut_type && (ut->ut_type <= OLD_TIME)) {
      if (ut->ut_type == tmp->ut_type) break;
    }
    if ((ut->ut_type >= INIT_PROCESS) && (ut->ut_type <= DEAD_PROCESS)) {
      if (!strncmp(ut->ut_id,tmp->ut_id,4)) break;
    }
  }
  return tmp;
}

struct utmp *getutline(struct utmp *ut) {
  struct utmp *tmp;

  while ((tmp = getutent())) {
    if ((tmp->ut_type == USER_PROCESS) || (tmp->ut_type == LOGIN_PROCESS)) {
      if (!strncmp(ut->ut_line,tmp->ut_line,UT_LINESIZE)) break;
    }
  }
  return tmp;
}

void pututline(struct utmp *ut) {
  struct utmp *tmp;

  /* Seek to the current record before searching. */
  lseek (fd, utmp_current, SEEK_SET);
  if ((tmp = getutid(ut))) {
    lseek(fd, - (off_t)sizeof(struct utmp), SEEK_CUR);
    if (lock_record(F_WRLCK)) return;
    write(fd, ut, sizeof(struct utmp));
    utmp_current += sizeof(struct utmp);
  }
  else {
    utmp_current = lseek(fd, 0, SEEK_END);
    if (lock_record(F_WRLCK)) return;
    write(fd, ut, sizeof(struct utmp));
  }
  unlock_record();
}

