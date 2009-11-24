#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <utmp.h>
#include <fcntl.h>
#include <_syslist.h>

char *
getlogin ()
{
  int utmp_fd;
  struct utmp utmp_buf;
  static char buf[10];
  extern char *ttyname ();
  char *tty;

  if (((tty = ttyname (0)) == 0)
      || ((tty = ttyname (1)) == 0)
      || ((tty = ttyname (2)) == 0))
    return 0;

  if ((utmp_fd = open (UTMP_FILE, O_RDONLY)) == -1)
    return 0;

  if (!strncmp (tty, "/dev/", 5))
    tty += 5;

  while (read (utmp_fd, &utmp_buf, sizeof (utmp_buf)) == sizeof (utmp_buf))
    {
      if (!strncmp (tty, utmp_buf.ut_line, sizeof (utmp_buf.ut_line))
	  && utmp_buf.ut_type == USER_PROCESS)
	{
	  close (utmp_fd);
	  memset (buf, 0, sizeof (buf));
	  strncpy (buf, utmp_buf.ut_user, sizeof (utmp_buf.ut_user));
	  return buf;
	}
    }

  close (utmp_fd);
  return 0;
}
