
#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

int 
_read (file, ptr, len)
     int file;
     char *ptr;
     size_t len;

{
  return 0;
}


int 
_lseek (file, ptr, dir)
     int file;
     int ptr;
     int dir;

{
  return 0;

}

static 
writechar (c)
     char c;


{
  register int n asm ("r3");
  n = c;
asm ("clr.w	r1;mov.w %0,r0; mov.w #6,r3; trapa #15": :"g" (n) : "r3","r1","r0");
}



int 
_write (file, ptr, len)
     int file;
     char *ptr;
     size_t len;
{

  int todo;

  for (todo = 0; todo < len; todo++)
    {
      writechar (*ptr++);
    }
  return len;

}



int 
_close (file)
     int file;
{

  return -1;
}



caddr_t
_sbrk (incr)
     size_t incr;
{
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
  return (caddr_t) prev_heap_end;
}



int 
isatty (file)
     int file;
{
  return 1;
}



int 
_fstat (file, stat)
     int file;
     struct stat *stat;

{
  stat->st_mode = S_IFCHR;
  return 0;
}

int 
_open (path, flags)
     const char *path;
     int flags;

{
  return 0;
}


void 
_exit (status)
     int status;
{
  asm (" mov.w #33,r3; trapa #15");
}
