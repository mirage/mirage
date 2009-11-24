/* Operating system  and traps for mvme187bug, the motorolola BUG
   monitor for m88k */

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/times.h>
#include <errno.h>

#include "sys/systraps.h"

static void writechar(int c) {
  register int n asm ("r2");
  n = c;
  SYSTRAP(OUTCHR);
  return;
}

static int readchar(void) {
  register int n asm ("r2");
  SYSTRAP(INCHR);
  return(n);
}

int read(int file, char *ptr, int len) {
  int todo;

  for (todo = len; todo; --todo) {
    *ptr++ = readchar();
  }

  return(len);
}

int lseek(int file, int ptr, int dir) {
  return 0;
}

int write(int file, char *ptr, int len) {
  int todo;
  
  for (todo = len; todo; --todo) {
    writechar(*ptr++);
  }
  return(len);
}

int close(int file) {
  return(-1);
}

caddr_t sbrk(int incr) {
  extern char end;		/* Defined by the linker */
  static char *heap_end;
  char *prev_heap_end;

  if (heap_end == 0) 
  {
    heap_end = &end;
  }
  prev_heap_end = heap_end;
  if (heap_end + incr > stack_ptr)
    {
      _write (1, "Heap and stack collision\n", 25);
      abort ();
    }
  heap_end += incr;
  return((caddr_t) prev_heap_end);
}

int isatty(int file) {
  return(1);
}

int fstat(int file, struct stat *st) {
  st->st_mode = S_IFCHR;
  return(0);
}

int stat(char *filename, struct stat *st) {
  st->st_mode = S_IFCHR;
  return(0);
}

int open(const char *path, int flags) {
  return(0);
}


int _exit() {
  SYSTRAP(RETURN);
}

int execve(char *name, char **argv, char **env) {
  errno = ENOMEM;
  return(-1);
}

int fork() {
  errno = EAGAIN;
  return(-1);
}

int getpid() {
  return(1);
}

int kill(int pid, int sig) {
  errno = EINVAL;
  return(-1);
}

int link(char *old, char *new) {
  errno = EMLINK;
  return(-1);
}

clock_t times(struct tms *buf) {
  return(-1);
}

int unlink(char *name) {
  errno = ENOENT;
  return(-1);
}

int wait(int *status) {
  errno = ECHILD;
  return(-1);
}

/* end of syscalls.c */
