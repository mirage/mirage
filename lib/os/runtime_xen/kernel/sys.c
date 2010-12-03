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
    int the_errno = errno;
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

int clock_gettime(clockid_t clk_id, struct timespec *tp)
{
    switch (clk_id) {
    case CLOCK_MONOTONIC:
    {
        struct timeval tv;

        gettimeofday(&tv, NULL);

        tp->tv_sec = tv.tv_sec;
        tp->tv_nsec = tv.tv_usec * 1000;

        break;
    }
    case CLOCK_REALTIME:
    {
        uint64_t nsec = monotonic_clock();

        tp->tv_sec = nsec / 1000000000ULL;
        tp->tv_nsec = nsec % 1000000000ULL;

        break;
    }
    default:
        print_unsupported("clock_gettime(%d)", clk_id);
        errno = EINVAL;
        return -1;
    }

    return 0;
}

clock_t times(struct tms *buf)
{
     uint64_t nsec;
     nsec = monotonic_clock ();
     buf->tms_utime = nsec / CLK_TCK;
     buf->tms_stime = 0;
     buf->tms_cutime = 0;
     buf->tms_cstime = 0;
     return 0;
}

size_t getpagesize(void)
{
    return PAGE_SIZE;
}

void *mmap(void *start, size_t length, int prot, int flags, int fd, off_t offset)
{
    unsigned long n = (length + PAGE_SIZE - 1) / PAGE_SIZE;

    ASSERT(!start);
    ASSERT(prot == (PROT_READ|PROT_WRITE));
    ASSERT((fd == -1 && (flags == (MAP_SHARED|MAP_ANON) || flags == (MAP_PRIVATE|MAP_ANON)))
        || (fd != -1 && flags == MAP_SHARED));

    if (fd == -1)
        return map_zero(n, 1);
    else if (files[fd].type == FTYPE_XC) {
        unsigned long zero = 0;
        return map_frames_ex(&zero, n, 0, 0, 1, DOMID_SELF, 0, 0);
    } else if (files[fd].type == FTYPE_MEM) {
        unsigned long first_mfn = offset >> PAGE_SHIFT;
        return map_frames_ex(&first_mfn, n, 0, 1, 1, DOMID_IO, 0, _PAGE_PRESENT|_PAGE_RW);
    } else ASSERT(0);
}

int munmap(void *start, size_t length)
{
    int total = length / PAGE_SIZE;
    int ret;

    ret = unmap_frames((unsigned long)start, (unsigned long)total);
    if (ret) {
        errno = ret;
        return -1;
    }
    return 0;
}

void sparse(unsigned long data, size_t size)
{
    unsigned long newdata;
    xen_pfn_t *mfns;
    int i, n;

    newdata = (data + PAGE_SIZE - 1) & PAGE_MASK;
    if (newdata - data > size)
        return;
    size -= newdata - data;
    data = newdata;
    n = size / PAGE_SIZE;
    size = n * PAGE_SIZE;

    mfns = malloc(n * sizeof(*mfns));
    for (i = 0; i < n; i++) {
#ifdef LIBC_DEBUG
        int j;
        for (j=0; j<PAGE_SIZE; j++)
            if (((char*)data + i * PAGE_SIZE)[j]) {
                printk("%lx is not zero!\n", data + i * PAGE_SIZE + j);
                exit(1);
            }
#endif
        mfns[i] = virtual_to_mfn(data + i * PAGE_SIZE);
    }

    printk("sparsing %ldMB at %lx\n", size >> 20, data);

    munmap((void *) data, size);
    free_physical_pages(mfns, n);
    do_map_zero(data, n);
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

/* Unsupported */
unsupported_function_crash(pipe);
unsupported_function_crash(fork);
unsupported_function_crash(execv);
unsupported_function_crash(execve);
unsupported_function_crash(waitpid);
unsupported_function_crash(wait);
unsupported_function_crash(lockf);
unsupported_function_crash(sysconf);
unsupported_function(int, tcsetattr, -1);
unsupported_function(int, tcgetattr, 0);
unsupported_function(int, grantpt, -1);
unsupported_function(int, unlockpt, -1);
unsupported_function(char *, ptsname, NULL);
unsupported_function(int, poll, -1);

/* net/if.h */
unsupported_function_log(unsigned int, if_nametoindex, -1);
unsupported_function_log(char *, if_indextoname, (char *) NULL);
unsupported_function_log(struct  if_nameindex *, if_nameindex, (struct  if_nameindex *) NULL);

/* Linuxish abi for the Caml runtime, don't support 
   Log, and return an error code if possible.  If it is not possible
   to inform the application of an error, then crash instead!
*/
unsupported_function_log(char *, getenv, (char *) NULL);
unsupported_function_log(int, system, -1);
unsupported_function_log(struct dirent *, readdir64, NULL);
unsupported_function_log(int, getrusage, -1);
unsupported_function_log(int, getrlimit, -1);
unsupported_function_log(int, getrlimit64, -1);
unsupported_function_log(int, __xstat64, -1);
unsupported_function_log(int, utime, -1);
unsupported_function_log(int, truncate64, -1);
unsupported_function_log(int, tcflow, -1);
unsupported_function_log(int, tcflush, -1);
unsupported_function_log(int, tcdrain, -1);
unsupported_function_log(int, tcsendbreak, -1);
unsupported_function_log(int, cfsetospeed, -1);
unsupported_function_log(int, cfsetispeed, -1);
unsupported_function_crash(cfgetospeed);
unsupported_function_crash(cfgetispeed);
unsupported_function_log(int, symlink, -1);
unsupported_function_log(const char*, inet_ntop, NULL);
unsupported_function_crash(__fxstat64);
unsupported_function_crash(__lxstat64);
unsupported_function_log(int, socketpair, -1);
unsupported_function_crash(sigsuspend);
unsupported_function_log(int, sigpending, -1);
unsupported_function_log(int, shutdown, -1);
unsupported_function_log(int, setuid, -1);
unsupported_function_log(int, setgid, -1);
unsupported_function_crash(rewinddir);
unsupported_function_log(int, getpriority, -1);
unsupported_function_log(int, setpriority, -1);
unsupported_function_log(int, mkfifo, -1);
unsupported_function_log(int, getitimer, -1);
unsupported_function_log(int, setitimer, -1);
unsupported_function_log(void *, getservbyport, NULL);
unsupported_function_log(void *, getservbyname, NULL);
unsupported_function_log(void *, getpwuid, NULL);
unsupported_function_log(void *, getpwnam, NULL);
unsupported_function_log(void *, getprotobynumber, NULL);
unsupported_function_log(void *, getprotobyname, NULL);
unsupported_function_log(int, getpeername, -1);
unsupported_function_log(int, getnameinfo, -1);
unsupported_function_log(char *, getlogin, NULL);
unsupported_function_crash(__h_errno_location);
unsupported_function_log(int, gethostbyname_r, -1);
unsupported_function_log(int, gethostbyaddr_r, -1);
unsupported_function_log(int, getgroups, -1);
unsupported_function_log(void *, getgrgid, NULL);
unsupported_function_log(void *, getgrnam, NULL);
unsupported_function_log(int, getaddrinfo, -1);
unsupported_function_log(int, freeaddrinfo, -1);
unsupported_function_log(int, ftruncate64, -1);
unsupported_function_log(int, fchown, -1);
unsupported_function_log(int, fchmod, -1);
unsupported_function_crash(execvp);
unsupported_function_log(int, dup, -1)
unsupported_function_log(int, chroot, -1)
unsupported_function_log(int, chown, -1);
unsupported_function_log(int, chmod, -1);
unsupported_function_crash(alarm);
unsupported_function_log(int, inet_pton, -1);
unsupported_function_log(int, access, -1);
