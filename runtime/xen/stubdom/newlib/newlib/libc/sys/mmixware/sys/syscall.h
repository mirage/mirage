/* syscall defines for MMIXware.

   Copyright (C) 2001, 2002, 2007 Hans-Peter Nilsson

   Permission to use, copy, modify, and distribute this software is
   freely granted, provided that the above copyright notice, this notice
   and the following disclaimer are preserved with no changes.

   THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
   PURPOSE.  */

/* These are the mmixware simulator calls that are of use in newlib.  */

#define SYS_halt	0
#define	SYS_Fopen	1
#define	SYS_Fclose	2
#define	SYS_Fread	3
#define	SYS_Fgets	4
#define	SYS_Fwrite	6
#define	SYS_Fseek	9
#define	SYS_Ftell	10


enum MMIX_filemode
 {
   TextRead = 0,
   TextWrite = 1,
   BinaryRead = 2,
   BinaryWrite = 3,
   BinaryReadWrite = 4
 };

#define N_MMIX_FILEHANDLES 32

/* We store a bitmap of allocated filehandles
   _MMIX_allocated_filehandle[fileno] in an array.  There are 32 of them.
   Indexes 0, 1 and 2 are allocated from start.  The reason we keep track
   of them is that *we* have to allocate a filehandle when opening a file.
   Had we got a filehandle from the simulator, we wouldn't have to keep
   track of it.  A value of 0 denotes a free handle.  */
extern unsigned char _MMIX_allocated_filehandle[N_MMIX_FILEHANDLES];

/* Simulator call with one argument.  Also used for zero-argument calls;
   pass a zero as ARG1.  Make the asm volatile so we can safely ignore the
   return-value and only get the benefit from the supposed side-effect
   without the asm being optimized away.  */
#define TRAP1i(FUN, ARG1)			\
 ({ long ret_;					\
    __asm__ __volatile__			\
      ("TRAP 0,%1,%2\n\tSET %0,$255"		\
       : "=r" (ret_) : "i" (FUN), "i" (ARG1)	\
       : "memory");				\
    ret_;					\
 })

/* Helper macros to cope with the file-handle parameter to the simulator
   being *constant*.  We support up to 32 simultaneously open files.  Make
   the asm volatile so we can safely ignore the return-value and get the
   benefit from the supposed side-effect without the asm being optimized
   away.  */

#define I3f(FUN, ARG1, N, ARGS)				\
 if (ARG1 == N)						\
   __asm__ __volatile__					\
     ("SET $255,%3\n\tTRAP 0,%1,%2\n\tSET %0,$255"	\
      : "=r" (ret_) : "i" (FUN), "i" (N), "r" (ARGS)	\
      : "memory")

/* Using if:s rather than switches to help GCC optimize the rest away.  */
#define DO32(FUN, ARG1, ARGS)			\
    I3f (FUN, ARG1, 0, ARGS);			\
    else I3f (FUN, ARG1, 1, ARGS);		\
    else I3f (FUN, ARG1, 2, ARGS);		\
    else I3f (FUN, ARG1, 3, ARGS);		\
    else I3f (FUN, ARG1, 4, ARGS);		\
    else I3f (FUN, ARG1, 5, ARGS);		\
    else I3f (FUN, ARG1, 6, ARGS);		\
    else I3f (FUN, ARG1, 7, ARGS);		\
    else I3f (FUN, ARG1, 8, ARGS);		\
    else I3f (FUN, ARG1, 9, ARGS);		\
    else I3f (FUN, ARG1, 10, ARGS);		\
    else I3f (FUN, ARG1, 11, ARGS);		\
    else I3f (FUN, ARG1, 12, ARGS);		\
    else I3f (FUN, ARG1, 13, ARGS);		\
    else I3f (FUN, ARG1, 14, ARGS);		\
    else I3f (FUN, ARG1, 15, ARGS);		\
    else I3f (FUN, ARG1, 16, ARGS);		\
    else I3f (FUN, ARG1, 17, ARGS);		\
    else I3f (FUN, ARG1, 18, ARGS);		\
    else I3f (FUN, ARG1, 19, ARGS);		\
    else I3f (FUN, ARG1, 20, ARGS);		\
    else I3f (FUN, ARG1, 21, ARGS);		\
    else I3f (FUN, ARG1, 22, ARGS);		\
    else I3f (FUN, ARG1, 23, ARGS);		\
    else I3f (FUN, ARG1, 24, ARGS);		\
    else I3f (FUN, ARG1, 25, ARGS);		\
    else I3f (FUN, ARG1, 26, ARGS);		\
    else I3f (FUN, ARG1, 27, ARGS);		\
    else I3f (FUN, ARG1, 28, ARGS);		\
    else I3f (FUN, ARG1, 29, ARGS);		\
    else I3f (FUN, ARG1, 30, ARGS);		\
    else I3f (FUN, ARG1, 31, ARGS);		\
    else					\
      {						\
        errno = EBADF;				\
	return -1;				\
      }

#define TRAP1f(FUN, ARG1)			\
 ({ long ret_;					\
    DO32 (FUN, ARG1, 0);			\
    ret_;					\
 })

#define TRAP2f(FUN, ARG1, ARG2)			\
 ({ long ret_;					\
    DO32 (FUN, ARG1, ARG2);			\
    ret_;					\
 })

#define TRAP3f(FUN, ARG1, ARG2, ARG3)				\
 ({ long ret_;							\
    unsigned long args_[]					\
      = { (unsigned long) (ARG2), (unsigned long) (ARG3) };	\
    DO32 (FUN, ARG1, args_);					\
    ret_;							\
 })

#ifndef __GNUC__
/* Probably will not happen.  Nevertheless...  */
# define UNIMPLEMENTED(MSG)
#else
# define UNIMPLEMENTED(MSG) UNIMPLEMENTEDi MSG
# define UNIMPLEMENTEDi(MSG, ARGS...)					\
 do {									\
     char buf[2000];							\
     sprintf (buf, "UNIMPLEMENTED %s in %s\n", __FUNCTION__, __FILE__);	\
     write (2, buf, strlen (buf));					\
     sprintf (buf, MSG , ##ARGS);					\
     write (2, buf, strlen (buf));					\
     write (2, "\n", 1);						\
 } while (0)
#endif
