/*
 * io.c -- all the code to make GCC and the libraries run on
 *         a bare target board.
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>

#include "hppa-defs.h"

extern char *_end;                /* _end is set in the linker command file */

/* just in case, most boards have at least some memory */
#ifndef RAMSIZE
#  define RAMSIZE             (char *)0x100000
#endif

int
print(ptr)
char *ptr;
{
  while (*ptr)
    outbyte (*ptr++);
}

int
putnum (Num)
unsigned int Num;
{
  char	Buffer[9];
  int	Count;
  char	*BufPtr = Buffer;
  int	Digit;
  
  for (Count = 7 ; Count >= 0 ; Count--) {
    Digit = (Num >> (Count * 4)) & 0xf;
    
    if (Digit <= 9)
      *BufPtr++ = (char) ('0' + Digit);
    else
      *BufPtr++ = (char) ('a' - 10 + Digit);
  }

  *BufPtr = (char) 0;
  print (Buffer);
  return;
}

int
delay (x)
     int x;
{
  int  y = 17;
  while (x-- !=0)
    y = y^2;
}

/*
 * strobe -- do a zylons thing, toggling each led in sequence forever...
 */
int
zylons()
{
  while (1) {
    strobe();
  }
}

/*
 * strobe -- toggle each led in sequence up and back once.
 */
int
strobe()
{
  static unsigned char curled = 1;
  static unsigned char dir = 0;

  curled = 1;
  dir = 0;
  while (curled != 0) {
    led_putnum (curled);
    delay (70000);
    if (dir)
      curled >>= 1;
    else
      curled <<= 1;
    
    if (curled == 128) {
      dir = ~dir;
    }
  }
  curled = 1;
  dir = 0;
}

/*
 * iodc_io_call -- this makes a call into the IODC routine
 */
int
iodc_io_call(ep_address,arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11)
int ep_address, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11;
{ 
  int         (*iodc_entry_point)();
  
  iodc_entry_point = (int (*)())ep_address;

  return ((*iodc_entry_point)(arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11));
}

/*
 * pdc_call -- this makes a call into the PDC routine
 */
int
pdc_call(arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11)
     int arg0, arg1, arg2, arg3,  arg4, arg5;
     int arg6, arg7, arg9, arg10, arg11;
{
   return ( CALL_PDC(arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11));
}

/*
 * put_led -- put a bit pattern on the LED's. 
 */
int
led_putnum (byte)
     unsigned short byte;
{
  return (pdc_call(OPT_PDC_CHASSIS,0,byte));
}


/*
 * outbyte -- shove a byte out the serial port
 */
int
outbyte(byte)
     unsigned char byte;
{
  int status;
  int R_addr[32];
  struct _dev *console = (struct _dev *)PGZ_CONSOLE_STRUCT;

  status = iodc_io_call(console->iodc_io, console->hpa, IO_CONSOLE_OUTPUT, console->spa,
			console->layer[0], R_addr, 0, &byte, 1,	0);

  switch(status)
    {
    case 0:  return(1);
    default: return (-1);
    }
}

/*
 * inbyte -- get a byte from the serial port
 */
unsigned char
inbyte()
{
  int status;
  int R_addr[32];
  char inbuf;
  struct _dev *console = (struct _dev *)PGZ_CONSOLE_STRUCT;

  while (status == 0) {
    status = iodc_io_call(console->iodc_io, console->hpa, IO_CONSOLE_INPUT, console->spa,
			  console->layer[0], R_addr, 0, &inbuf, 1, 0);
    
    switch (status) {
    case 0:
    case 2:  					/* recoverable error */
      if (R_addr[0] != 0) {			/* found a character */
	return(inbuf);
      }
      else
	break; 					/* error, no character */
    default: 					/* error, no character */
      return(0);	
    }
  }
}

/*
 * read  -- read bytes from the serial port. Ignore fd, since
 *          we only have stdin.
 */
int
read(fd, buf, nbytes)
     int fd;
     char *buf;
     int nbytes;
{
  int i = 0;
  
  for (i = 0; i < nbytes; i++) {
    *(buf + i) = inbyte();
    if ((*(buf + i) == '\n') || (*(buf + i) == '\r')) {
      (*(buf + i)) = 0;
      break;
    }
  }
  return (i);
}

/*
 * write -- write bytes to the serial port. Ignore fd, since
 *          stdout and stderr are the same. Since we have no filesystem,
 *          open will only return an error.
 */
int
write(fd, buf, nbytes)
     int fd;
     char *buf;
     int nbytes;
{
  int i;

  for (i = 0; i < nbytes; i++) {
    if (*(buf + i) == '\n') {
      outbyte ('\r');
    }
    outbyte (*(buf + i));
  }
  return (nbytes);
}

/*
 * open -- open a file descriptor. We don't have a filesystem, so
 *         we return an error.
 */
int
open(buf, flags, mode)
     char *buf;
     int flags;
     int mode;
{
  errno = EIO;
  return (-1);
}

/*
 * close -- close a file descriptor. We don't need
 *          to do anything, but pretend we did.
 */
int
close(fd)
     int fd;
{
  return (0);
}

/*
 * sbrk -- changes heap size size. Get nbytes more
 *         RAM. We just increment a pointer in what's
 *         left of memory on the board.
 */
char *
sbrk(nbytes)
     int nbytes;
{
  static char * heap_ptr = NULL;
  char *        base;

  if (heap_ptr == NULL) {
    heap_ptr = (char *)&_end;
  }

  if ((RAMSIZE - heap_ptr) >= 0) {
    base = heap_ptr;
    heap_ptr += nbytes;
    return (heap_ptr);
  } else {
    errno = ENOMEM;
    return ((char *)-1);
  }
}

/*
 * isatty -- returns 1 if connected to a terminal device,
 *           returns 0 if not. Since we're hooked up to a
 *           serial port, we'll say yes return a 1.
 */
int
isatty(fd)
     int fd;
{
  return (1);
}

/*
 * lseek -- move read/write pointer. Since a serial port
 *          is non-seekable, we return an error.
 */
off_t
lseek(fd,  offset, whence)
     int fd;
     off_t offset;
     int whence;
{
  errno = ESPIPE;
  return ((off_t)-1);
}

/*
 * fstat -- get status of a file. Since we have no file
 *          system, we just return an error.
 */
int
fstat(fd, buf)
     int fd;
     struct stat *buf;
{
  errno = EIO;
  return (-1);
}

/*
 * getpid -- only one process, so just return 1.
 */
#define __MYPID 1
int
getpid()
{
  return __MYPID;
}

/*
 * kill -- assume mvme.S, and go out via exit...
 */
int
kill(pid, sig)
     int pid;
     int sig;
{
  if(pid == __MYPID)
    _exit(sig);
  return 0;
}
