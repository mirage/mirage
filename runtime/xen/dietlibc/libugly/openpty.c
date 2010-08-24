#include <unistd.h>
#include <pty.h>
#include <fcntl.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>

int openpty(int *amaster, int *aslave, char *name, struct termios
	    *termp, struct winsize *winp) {
  int fd;
  char buf[20];
#if 0
  This is what glibc does:
  open("/dev/ptmx", O_RDWR)               = 4
  statfs("/dev/pts", {f_type=0x1cd1, f_bsize=1024, f_blocks=0, f_bfree=0, f_files=0, f_ffree=0, f_namelen=255}) = 0
  ioctl(4, TCGETS, {B38400 opost isig icanon echo ...}) = 0
  ioctl(4, 0x80045430, [0])               = 0
  stat("/dev/pts/0", {st_mode=S_IFCHR|0620, st_rdev=makedev(136, 0), ...}) = 0
  statfs("/dev/pts/0", {f_type=0x1cd1, f_bsize=1024, f_blocks=0, f_bfree=0, f_files=0, f_ffree=0, f_namelen=255}) = 0
  ioctl(4, 0x40045431, [0])               = 0
  ioctl(4, TCGETS, {B38400 opost isig icanon echo ...}) = 0
  ioctl(4, 0x80045430, [0])               = 0
  stat("/dev/pts/0", {st_mode=S_IFCHR|0620, st_rdev=makedev(136, 0), ...}) = 0
  open("/dev/pts/0", O_RDWR|O_NOCTTY)     = 5
#endif
  if ((fd=open("/dev/ptmx",O_RDWR))<0) return -1;
#if 0
  if (ioctl(fd,TCGETS,&ts)<0) goto kaputt;
#endif
  {
    int unlock=0;
    while (ioctl(fd,TIOCSPTLCK, &unlock)<0) if (errno!=EINTR) goto kaputt;
  }
  {
    int ptyno;
    while (ioctl(fd,TIOCGPTN,&ptyno)<0) if (errno!=EINTR) goto kaputt;
    strcpy(buf,"/dev/pts/");
    __ltostr(buf+9,10,ptyno,10,0);
  }
  *aslave=open(buf,O_RDWR|O_NOCTTY);
  if (*aslave<0) goto kaputt;
  *amaster=fd;
  if (name) strcpy(name,buf);
  if (termp)
    while (tcsetattr(*aslave,TCSAFLUSH,termp) && errno==EINTR);
  if (winp) while (ioctl(*aslave, TIOCSWINSZ, winp) && errno==EINTR);
  return 0;
kaputt:
  close(fd);
  return -1;
}
