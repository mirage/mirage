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
extern int xc_evtchn_close(int fd);
extern int xc_interface_close(int fd);
extern int xc_gnttab_close(int fd);

struct file files[NOFILE] = {
    { .type = FTYPE_CONSOLE }, /* stdin */
    { .type = FTYPE_CONSOLE }, /* stdout */
    { .type = FTYPE_CONSOLE }, /* stderr */
};

DECLARE_WAIT_QUEUE_HEAD(event_queue);

int alloc_fd(enum fd_type type)
{
    int i;
    for (i=0; i<NOFILE; i++) {
	if (files[i].type == FTYPE_NONE) {
	    files[i].type = type;
	    return i;
	}
    }
    printk("Too many opened files\n");
    do_exit();
}

void close_all_files(void)
{
    int i;
    for (i=NOFILE - 1; i > 0; i--)
	if (files[i].type != FTYPE_NONE)
            close(i);
}

int dup2(int oldfd, int newfd)
{
    if (files[newfd].type != FTYPE_NONE)
	close(newfd);
    // XXX: this is a bit bogus, as we are supposed to share the offset etc
    files[newfd] = files[oldfd];
    return 0;
}

pid_t getpid(void)
{
    return 1;
}

pid_t getppid(void)
{
    return 1;
}

pid_t setsid(void)
{
    return 1;
}

char *getcwd(char *buf, size_t size)
{
    snprintf(buf, size, "/");
    return buf;
}

#define LOG_PATH "/var/log/"

int posix_openpt(int flags)
{
    struct consfront_dev *dev;

    /* Ignore flags */

    dev = init_consfront(NULL);
    dev->fd = alloc_fd(FTYPE_CONSOLE);
    files[dev->fd].cons.dev = dev;

    printk("fd(%d) = posix_openpt\n", dev->fd);
    return(dev->fd);
}

int open(const char *pathname, int flags, ...)
{
    int fd;
    /* Ugly, but fine.  */
    if (!strncmp(pathname,LOG_PATH,strlen(LOG_PATH))) {
	fd = alloc_fd(FTYPE_CONSOLE);
        printk("open(%s) -> %d\n", pathname, fd);
        return fd;
    }
    if (!strncmp(pathname, "/dev/mem", strlen("/dev/mem"))) {
        fd = alloc_fd(FTYPE_MEM);
        printk("open(/dev/mem) -> %d\n", fd);
        return fd;
    }
    if (!strncmp(pathname, "/dev/ptmx", strlen("/dev/ptmx")))
        return posix_openpt(flags);
    printk("open(%s, %x)", pathname, flags);
    errno = EIO;
    return -1;
}

int isatty(int fd)
{
    return files[fd].type == FTYPE_CONSOLE;
}

ssize_t read(int fd, void *buf, size_t nbytes)
{
    switch (files[fd].type) {
	case FTYPE_CONSOLE: {
	    int ret;
            DEFINE_WAIT(w);
            while(1) {
                add_waiter(w, console_queue);
                ret = xencons_ring_recv(files[fd].cons.dev, buf, nbytes);
                if (ret)
                    break;
                schedule();
            }
            remove_waiter(w);
            return ret;
        }
	default:
	    break;
    }
    printk("read(%d): Bad descriptor\n", fd);
    errno = EBADF;
    return -1;
}

ssize_t write(int fd, const void *buf, size_t nbytes)
{
    switch (files[fd].type) {
	case FTYPE_CONSOLE:
	    console_print(files[fd].cons.dev, (char *)buf, nbytes);
	    return nbytes;
	default:
	    break;
    }
    printk("write(%d): Bad descriptor\n", fd);
    errno = EBADF;
    return -1;
}

/* XXX revisit */
ssize_t __libc_write(int fd, const void *buf, size_t len)
{
  return write(fd, buf, len);
}

off_t lseek(int fd, off_t offset, int whence)
{
    errno = ESPIPE;
    return (off_t) -1;
}

int fsync(int fd) {
    printk("fsync(%d): Bad descriptor\n", fd);
    errno = EBADF;
    return -1;
}

int close(int fd)
{
    printk("close(%d)\n", fd);
    switch (files[fd].type) {
        default:
	    files[fd].type = FTYPE_NONE;
	    return 0;
	case FTYPE_XENBUS:
            xs_daemon_close((void*)(intptr_t) fd);
            return 0;
#if 0 /* XXX bring back when XC is back */
	case FTYPE_XC:
	    xc_interface_close(fd);
	    return 0;
	case FTYPE_EVTCHN:
            xc_evtchn_close(fd);
            return 0;
	case FTYPE_GNTMAP:
	    xc_gnttab_close(fd);
	    return 0;
#endif
	case FTYPE_BLK:
            shutdown_blkfront(files[fd].blk.dev);
	    files[fd].type = FTYPE_NONE;
	    return 0;
        case FTYPE_CONSOLE:
            fini_console(files[fd].cons.dev);
            files[fd].type = FTYPE_NONE;
            return 0;
	case FTYPE_NONE:
	    break;
    }
    printk("close(%d): Bad descriptor\n", fd);
    errno = EBADF;
    return -1;
}

static void init_stat(struct stat *buf)
{
    memset(buf, 0, sizeof(*buf));
    buf->st_dev = 0;
    buf->st_ino = 0;
    buf->st_nlink = 1;
    buf->st_rdev = 0;
    buf->st_blksize = 4096;
    buf->st_blocks = 0;
}

int stat(const char *path, struct stat *buf)
{
    errno = EIO;
    return -1;
}

int fstat(int fd, struct stat *buf)
{
    struct timeval tv;
    init_stat(buf);
    switch (files[fd].type) {
	case FTYPE_CONSOLE:
	case FTYPE_SOCKET: {
	    buf->st_mode = (files[fd].type == FTYPE_CONSOLE?S_IFCHR:S_IFSOCK) | S_IRUSR|S_IWUSR;
	    buf->st_uid = 0;
	    buf->st_gid = 0;
	    buf->st_size = 0;
	    gettimeofday(&tv, NULL);
	    buf->st_atime = 
	    buf->st_mtime = 
	    buf->st_ctime = tv.tv_sec;
	    return 0;
	}
	default:
	    break;
    }

    printk("statf(%d): Bad descriptor\n", fd);
    errno = EBADF;
    return -1;
}

int ftruncate(int fd, off_t length)
{
    printk("ftruncate(%d): Bad descriptor\n", fd);
    errno = EBADF;
    return -1;
}

int remove(const char *pathname)
{
    errno = EIO;
    return -1;
}

int unlink(const char *pathname)
{
    return remove(pathname);
}

int rmdir(const char *pathname)
{
    return remove(pathname);
}

int fcntl(int fd, int cmd, ...)
{
    long arg;
    va_list ap;
    va_start(ap, cmd);
    arg = va_arg(ap, long);
    va_end(ap);

    switch (cmd) {
	default:
	    printk("fcntl(%d, %d, %lx/%lo)\n", fd, cmd, arg, arg);
	    errno = ENOSYS;
	    return -1;
    }
}

/* We assume that only the main thread calls select(). */

static const char file_types[] = {
    [FTYPE_NONE]	= 'N',
    [FTYPE_CONSOLE]	= 'C',
    [FTYPE_XENBUS]	= 'S',
    [FTYPE_XC]		= 'X',
    [FTYPE_EVTCHN]	= 'E',
    [FTYPE_SOCKET]	= 's',
    [FTYPE_BLK]		= 'B',
};
#ifdef LIBC_DEBUG
static void dump_set(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds, struct timeval *timeout)
{
    int i, comma;
#define printfds(set) do {\
    comma = 0; \
    for (i = 0; i < nfds; i++) { \
	if (FD_ISSET(i, set)) { \
	    if (comma) \
		printk(", "); \
	    printk("%d(%c)", i, file_types[files[i].type]); \
	    comma = 1; \
	} \
    } \
} while (0)

    printk("[");
    if (readfds)
	printfds(readfds);
    printk("], [");
    if (writefds)
	printfds(writefds);
    printk("], [");
    if (exceptfds)
	printfds(exceptfds);
    printk("], ");
    if (timeout)
	printk("{ %ld, %ld }", timeout->tv_sec, timeout->tv_usec);
}
#else
#define dump_set(nfds, readfds, writefds, exceptfds, timeout)
#endif

/* Just poll without blocking */
static int select_poll(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds)
{
    int i, n = 0;

#ifdef LIBC_VERBOSE
    static int nb;
    static int nbread[NOFILE], nbwrite[NOFILE], nbexcept[NOFILE];
    static s_time_t lastshown;

    nb++;
#endif

    /* Then see others as well. */
    for (i = 0; i < nfds; i++) {
	switch(files[i].type) {
	default:
	    if (FD_ISSET(i, readfds) || FD_ISSET(i, writefds) || FD_ISSET(i, exceptfds))
		printk("bogus fd %d in select\n", i);
	    /* Fallthrough.  */
	case FTYPE_CONSOLE:
	    if (FD_ISSET(i, readfds)) {
                if (xencons_ring_avail(files[i].cons.dev))
		    n++;
		else
		    FD_CLR(i, readfds);
            }
	    if (FD_ISSET(i, writefds))
                n++;
	    FD_CLR(i, exceptfds);
	    break;
	case FTYPE_XENBUS:
	    if (FD_ISSET(i, readfds)) {
                if (files[i].xenbus.events)
		    n++;
		else
		    FD_CLR(i, readfds);
	    }
	    FD_CLR(i, writefds);
	    FD_CLR(i, exceptfds);
	    break;
	case FTYPE_EVTCHN:
	case FTYPE_BLK:
	    if (FD_ISSET(i, readfds)) {
		if (files[i].read)
		    n++;
		else
		    FD_CLR(i, readfds);
	    }
	    FD_CLR(i, writefds);
	    FD_CLR(i, exceptfds);
	    break;
	}
#ifdef LIBC_VERBOSE
	if (FD_ISSET(i, readfds))
	    nbread[i]++;
	if (FD_ISSET(i, writefds))
	    nbwrite[i]++;
	if (FD_ISSET(i, exceptfds))
	    nbexcept[i]++;
#endif
    }
#ifdef LIBC_VERBOSE
    if (NOW() > lastshown + 1000000000ull) {
	lastshown = NOW();
	printk("%lu MB free, ", num_free_pages() / ((1 << 20) / PAGE_SIZE));
	printk("%d(%d): ", nb, sock_n);
	for (i = 0; i < nfds; i++) {
	    if (nbread[i] || nbwrite[i] || nbexcept[i])
		printk(" %d(%c):", i, file_types[files[i].type]);
	    if (nbread[i])
	    	printk(" %dR", nbread[i]);
	    if (nbwrite[i])
		printk(" %dW", nbwrite[i]);
	    if (nbexcept[i])
		printk(" %dE", nbexcept[i]);
	}
	printk("\n");
	memset(nbread, 0, sizeof(nbread));
	memset(nbwrite, 0, sizeof(nbwrite));
	memset(nbexcept, 0, sizeof(nbexcept));
	nb = 0;
    }
#endif
    return n;
}

void vwarn(const char *format, va_list ap)
{
    int the_errno = errno;
    printk("stubdom: ");
    if (format) {
        print(0, format, ap);
        printk(", ");
    }
    printk("%s", strerror(the_errno));
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
        print(0, format, ap);
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

int nanosleep(const struct timespec *req, struct timespec *rem)
{
    s_time_t start = NOW();
    s_time_t stop = start + SECONDS(req->tv_sec) + req->tv_nsec;
    s_time_t stopped;
    struct thread *thread = get_current();

    thread->wakeup_time = stop;
    clear_runnable(thread);
    schedule();
    stopped = NOW();

    if (rem)
    {
	s_time_t remaining = stop - stopped;
	if (remaining > 0)
	{
	    rem->tv_nsec = remaining % 1000000000ULL;
	    rem->tv_sec  = remaining / 1000000000ULL;
	} else memset(rem, 0, sizeof(*rem));
    }

    return 0;
}

int usleep(unsigned long usec)
{
    /* "usec shall be less than one million."  */
    struct timespec req;
    req.tv_nsec = usec * 1000;
    req.tv_sec = 0;

    if (nanosleep(&req, NULL))
	return -1;

    return 0;
}

unsigned int sleep(unsigned int seconds)
{
    struct timespec req, rem;
    req.tv_sec = seconds;
    req.tv_nsec = 0;

    if (nanosleep(&req, &rem))
	return -1;

    if (rem.tv_nsec > 0)
	rem.tv_sec++;

    return rem.tv_sec;
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

uid_t getuid(void)
{
	return 0;
}

uid_t geteuid(void)
{
	return 0;
}

gid_t getgid(void)
{
	return 0;
}

gid_t getegid(void)
{
	return 0;
}

int gethostname(char *name, size_t namelen)
{
	strncpy(name, "mini-os", namelen);
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

int nice(int inc)
{
    printk("nice() stub called with inc=%d\n", inc);
    return 0;
}


/* Not supported by FS yet.  */
unsupported_function_crash(link);
unsupported_function(int, readlink, -1);
unsupported_function_crash(umask);

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
unsupported_function_log(long, __strtol_internal, LONG_MIN);
unsupported_function_log(double, __strtod_internal, HUGE_VAL);
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
