#include "sys/syscall.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <_ansi.h>
#include <errno.h>

extern char _start_heap;
extern char _end_heap;
extern char _start_bss;
extern char _end_bss;


static int argl(long value)
{
  asm("ld r0,%H0" : : "r" (value));
  asm("ld r1,%I0" : : "r" (value));
  asm("sc %0" : : "i" (SYS_ARG)); 
}


static int argw(value)
{
  asm("ld r1,%H0" : : "r" ( value));
  asm("ld  r0,#0");
  asm("sc %0" : : "i" (SYS_ARG)); 
}

static int argp(void *value)
{
#ifdef __Z8001__  
  asm("ld r0,%H0" : : "r" (value));
  asm("ld r1,%I0" : : "r" (value));
#else
  asm("ld r1,%H0" : : "r" ( value));
  asm("ld  r0,#0");
#endif
  asm("sc %0" : : "i" (SYS_ARG)); 

}



#define ARGL(n, value)  argl(value)
#define ARGW(n, value)  argw(value)
#define ARGP(n, value) argp(value)

#define MACRO(n) asm("sc %0" : : "i" (n));

int _read (int fd, char *buf,size_t nbytes)
{
  ARGW(0,fd);
  ARGP(1,buf);
  ARGP(2,(void *)(nbytes));
  MACRO(SYS_read);
}

int _write (int fd, char *buf, size_t nbytes)
{
  ARGW(0,fd);
  ARGP(1,buf);
  ARGP(2,(void *)(nbytes));
  MACRO(SYS_write);
}

int _open (const char *buf, int flags, int mode)
{
  ARGP(0, buf);
  ARGW(1, flags);
  ARGW(2, mode);
  MACRO(SYS_open);
}

int _close (int fd)
{
  ARGW(0,fd);
  MACRO(SYS_close );
}

/*
 * sbrk -- changes heap size size. Get nbytes more
 *         RAM. We just increment a pointer in what's
 *         left of memory on the board.
 */
caddr_t _sbrk (size_t nbytes)
{
  static char* heap_ptr = NULL;
  caddr_t        base;

  if (heap_ptr == NULL) {
    heap_ptr = (caddr_t)&_start_heap;
  }

  if (heap_ptr + nbytes < &_end_heap) {
    base = heap_ptr;
    heap_ptr += nbytes;
    return (heap_ptr);
  } else {
    errno = ENOMEM;
    return ((caddr_t)-1);
  }
}

int isatty (int fd)
{
  ARGW(0,fd);
  MACRO(SYS_isatty);
}

off_t _lseek (int fd,  off_t offset, int whence)
{
  ARGW(0,fd);
  ARGL(1,offset);
  ARGW(2, whence);
  MACRO(SYS_lseek);
}

int _fstat (int fd, struct stat *buf)
{
  ARGW(0,fd);
  ARGP(1,buf);
  MACRO(SYS_fstat);
}




int
_exit(int val)
{
  ARGW(0,val);
  MACRO(SYS_exit);
}

time_t _time(time_t *timer)
{
  ARGP(0,timer);
  MACRO(SYS_time);
}

int
_creat (const char *path, int mode)
{
  ARGP(0, path);
  ARGW(1, mode);
  MACRO(SYS_creat);
}

_kill(int pid, int val)
{
  _exit(val);
}

_getpid() 
{
  return 1;
}
