/*
 * POSIX-compatible libc layer
 *
 * Samuel Thibault <Samuel.Thibault@eu.citrix.net>, October 2007
 *
 * Provides the UNIXish part of the standard libc function.
 *
 * Relatively straight-forward: just multiplex the file descriptor operations
 * among the various file types (console, FS, network, ...)
 */

//#define LIBC_VERBOSE
//#define LIBC_DEBUG

#ifdef LIBC_DEBUG
#define DEBUG(fmt,...) printk(fmt, ##__VA_ARGS__)
#else
#define DEBUG(fmt,...)
#endif

#include <os.h>
#include <console.h>
#include <sched.h>
#include <events.h>
#include <wait.h>
#include <netfront.h>
#include <blkfront.h>
#include <xen/io/xenbus.h>
#include <xen/xenstore/xs.h>

#include <sys/types.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <net/if.h>
#include <time.h>
#include <errno.h>
#include <fcntl.h>
#include <assert.h>
#include <dirent.h>
#include <stdlib.h>
#include <math.h>
#include <sys/times.h>

#define debug(fmt, ...) \

#define print_unsupported(fmt, ...) \
    printk("Unsupported function "fmt" called in Mini-OS kernel\n", ## __VA_ARGS__);

/* Crash on function call */
#define unsupported_function_crash(function) \
    int __unsup_##function(void) asm(#function); \
    int __unsup_##function(void) \
    { \
    print_unsupported(#function); \
    do_exit(); \
    }

/* Log and err out on function call */
#define unsupported_function_log(type, function, ret) \
    type __unsup_##function(void) asm(#function); \
    type __unsup_##function(void) \
    { \
    print_unsupported(#function); \
    errno = ENOSYS; \
    return ret; \
    }

/* Err out on function call */
#define unsupported_function(type, function, ret) \
    type __unsup_##function(void) asm(#function); \
    type __unsup_##function(void) \
    { \
    errno = ENOSYS; \
    return ret; \
    }

#define NOFILE 32

struct file files[NOFILE] = {
    { .type = FTYPE_CONSOLE }, /* stdin */
    { .type = FTYPE_CONSOLE }, /* stdout */
    { .type = FTYPE_CONSOLE }, /* stderr */
};

void vwarn(const char *format, va_list ap)
{
    printk("stubdom: ");
    if (format) {
        print(format, ap);
        printk(", ");
    }
//    printk("%s", strerror(the_errno));
}

void warn(const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    vwarn(format, ap);
    va_end(ap);
}

void verr(int eval, const char *format, va_list ap)
{
    vwarn(format, ap);
    exit(eval);
}

void exit(int status)
{
    printk("exit: %d\n", status);
    do_exit();
}

void err(int eval, const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    verr(eval, format, ap);
    va_end(ap);
}

void vwarnx(const char *format, va_list ap)
{
    printk("stubdom: ");
    if (format)
        print(format, ap);
}

void warnx(const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    vwarnx(format, ap);
    va_end(ap);
}

void verrx(int eval, const char *format, va_list ap)
{
    vwarnx(format, ap);
    exit(eval);
}

void errx(int eval, const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    verrx(eval, format, ap);
    va_end(ap);
}

size_t getpagesize(void)
{
    return PAGE_SIZE;
}

ssize_t write(int fd, const void *buf, size_t nbytes)
{
    console_print(buf, nbytes);
    return nbytes;
}

/* Not supported by FS yet.  */
unsupported_function_crash(link);
unsupported_function(int, readlink, -1);
unsupported_function(int, __libc_write, -1);
unsupported_function(off_t, lseek, -1);
unsupported_function(int, ioctl, -1);
unsupported_function(int, stat, -1);
unsupported_function(int, close, -1);
unsupported_function(int, open, -1);
unsupported_function_crash(unlink);
unsupported_function_crash(read);
unsupported_function_crash(getpid);
unsupported_function_crash(umask);
unsupported_function_crash(getcwd);
unsupported_function_crash(fcntl);
unsupported_function_crash(rename);

/* We could support that.  */
unsupported_function_log(int, chdir, -1);

/* No dynamic library support.  */ 
unsupported_function_log(void *, dlopen, NULL);
unsupported_function_log(void *, dlsym, NULL);
unsupported_function_log(char *, dlerror, NULL);
unsupported_function_log(int, dlclose, -1);

/* We don't raise signals anyway.  */
unsupported_function(int, sigemptyset, -1);
unsupported_function(int, sigfillset, -1);
unsupported_function(int, sigaddset, -1);
unsupported_function(int, sigdelset, -1);
unsupported_function(int, sigismember, -1);
unsupported_function(int, sigprocmask, -1);
unsupported_function(int, sigaction, -1);
unsupported_function(int, __sigsetjmp, 0);
unsupported_function(int, sigaltstack, -1);
unsupported_function_crash(kill);

