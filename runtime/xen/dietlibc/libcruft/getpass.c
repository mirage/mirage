#include <termios.h>
#include <unistd.h>
#include <limits.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>

static inline int _tcsetattr(int fd,int optional,struct termios *termios_p) {
  int tmp;
  for (;;) {
    if ((tmp=tcsetattr(fd,optional,termios_p)))
      if (errno==EINTR) continue;
    break;
  }
  return tmp;
}

char *getpass(const char* prompt) {
  struct termios old,tmp;
  int out,in=open("/dev/tty",O_RDWR);
  int doclose=(in>=0);
  static char buf[PASS_MAX];
  if (!doclose) { in=0; out=2; } else out=in;
  if (!tcgetattr(in,&old)) {
    tmp=old;
    tmp.c_lflag &= ~(ECHO|ISIG);
    _tcsetattr(in,TCSAFLUSH,&tmp);
  }
  write(out,prompt,strlen(prompt));
  {
    int nread,ofs=0;
    for (;;) {
      nread=read(in,buf+ofs,1);
      if (nread<=0) {
	if (errno==EINTR) continue;
	buf[ofs]=0;
	break;
      } else if (ofs+nread>=PASS_MAX) {
	buf[PASS_MAX-1]=0;
	break;
      } else if (buf[ofs]=='\n') {
	buf[ofs+nread-1]=0;
	break;
      }
      ofs+=nread;
    }
    write(out,"\n",1);
  }
  _tcsetattr(in,TCSAFLUSH,&old);
  if (doclose) close(in);
  return buf;
}
