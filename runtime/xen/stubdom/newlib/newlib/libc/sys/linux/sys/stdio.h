#ifndef _NEWLIB_STDIO_H
#define _NEWLIB_STDIO_H

/* Internal locking macros, used to protect stdio functions.  In the
   linux case, expand to flockfile, and funlockfile, both defined in
   LinuxThreads. */
#if !defined(__SINGLE_THREAD__)
#  if !defined(_flockfile)
#    define _flockfile(fp) flockfile(fp)
#  endif
#  if !defined(_funlockfile)
#    define _funlockfile(fp) funlockfile(fp)
#  endif
#endif /* __SINGLE_THREAD__ */

#define getline __getline
#define getdelim __getdelim

char *	_EXFUN(ctermid, (char *));

#endif /* _NEWLIB_STDIO_H */
