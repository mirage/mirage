#ifndef _LOCAL_H
#include <dlfcn.h>

#define internal_function

/* Internally used flag.  */
#define __RTLD_DLOPEN	0x80000000
#define __RTLD_SPROF	0x40000000

/* Now define the internal interfaces.  */
extern void *__dlvsym (void *__handle, __const char *__name,
		       __const char *__version);

extern void *__libc_dlopen  (__const char *__name);
extern void *__libc_dlsym   (void *__map, __const char *__name);
extern int   __libc_dlclose (void *__map);

/* Locate shared object containing the given address.  */
extern int _dl_addr (const void *address, Dl_info *info)
     internal_function;

/* Open the shared object NAME, relocate it, and run its initializer if it
   hasn't already been run.  MODE is as for `dlopen' (see <dlfcn.h>).  If
   the object is already opened, returns its existing map.  */
extern void *_dl_open (const char *name, int mode, const void *caller)
     internal_function;

/* Close an object previously opened by _dl_open.  */
extern void _dl_close (void *map)
     internal_function;

/* Look up NAME in shared object HANDLE (which may be RTLD_DEFAULT or
   RTLD_NEXT).  WHO is the calling function, for RTLD_NEXT.  Returns
   the symbol value, which may be NULL.  */
extern void *_dl_sym (void *handle, const char *name, void *who)
    internal_function;

/* Look up version VERSION of symbol NAME in shared object HANDLE
   (which may be RTLD_DEFAULT or RTLD_NEXT).  WHO is the calling
   function, for RTLD_NEXT.  Returns the symbol value, which may be
   NULL.  */
extern void *_dl_vsym (void *handle, const char *name, const char *version,
		       void *who)
    internal_function;

/* Call OPERATE, catching errors from `dl_signal_error'.  If there is no
   error, *ERRSTRING is set to null.  If there is an error, *ERRSTRING is
   set to a string constructed from the strings passed to _dl_signal_error,
   and the error code passed is the return value and *OBJNAME is set to
   the object name which experienced the problems.  ERRSTRING if nonzero
   points to a malloc'ed string which the caller has to free after use.
   ARGS is passed as argument to OPERATE.  */
extern int _dl_catch_error (const char **objname, const char **errstring,
			    void (*operate) (void *),
			    void *args)
     internal_function;

/* Helper function for <dlfcn.h> functions.  Runs the OPERATE function via
   _dl_catch_error.  Returns zero for success, nonzero for failure; and
   arranges for `dlerror' to return the error details.
   ARGS is passed as argument to OPERATE.  */
extern int _dlerror_run (void (*operate) (void *), void *args)
     internal_function;

#endif
