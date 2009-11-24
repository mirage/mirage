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

#ifdef HAVE_LIBC
#include <os.h>
#include <console.h>
#include <sched.h>
#include <events.h>
#include <wait.h>
#include <netfront.h>
#include <blkfront.h>
#include <fbfront.h>
#include <xenbus.h>
#include <xs.h>

#include <sys/types.h>
#include <sys/unistd.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <net/if.h>
#include <time.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <assert.h>
#include <dirent.h>
#include <stdlib.h>
#include <math.h>

#ifdef HAVE_LWIP
#include <lwip/sockets.h>
#endif
#include <fs.h>

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

pthread_mutex_t fd_lock = PTHREAD_MUTEX_INITIALIZER;
struct file files[NOFILE] = {
    { .type = FTYPE_CONSOLE }, /* stdin */
    { .type = FTYPE_CONSOLE }, /* stdout */
    { .type = FTYPE_CONSOLE }, /* stderr */
};

DECLARE_WAIT_QUEUE_HEAD(event_queue);

int alloc_fd(enum fd_type type)
{
    int i;
    pthread_mutex_lock(&fd_lock);
    for (i=0; i<NOFILE; i++) {
	if (files[i].type == FTYPE_NONE) {
	    files[i].type = type;
	    pthread_mutex_unlock(&fd_lock);
	    return i;
	}
    }
    pthread_mutex_unlock(&fd_lock);
    printk("Too many opened files\n");
    do_exit();
}

void close_all_files(void)
{
    int i;
    pthread_mutex_lock(&fd_lock);
    for (i=NOFILE - 1; i > 0; i--)
	if (files[i].type != FTYPE_NONE)
            close(i);
    pthread_mutex_unlock(&fd_lock);
}

int dup2(int oldfd, int newfd)
{
    pthread_mutex_lock(&fd_lock);
    if (files[newfd].type != FTYPE_NONE)
	close(newfd);
    // XXX: this is a bit bogus, as we are supposed to share the offset etc
    files[newfd] = files[oldfd];
    pthread_mutex_unlock(&fd_lock);
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

int mkdir(const char *pathname, mode_t mode)
{
    int ret;
    ret = fs_create(fs_import, (char *) pathname, 1, mode);
    if (ret < 0) {
        errno = EIO;
        return -1;
    }
    return 0;
}

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
    int fs_fd, fd;
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
    switch (flags & ~O_ACCMODE) {
        case 0:
            fs_fd = fs_open(fs_import, (void *) pathname);
            break;
        case O_CREAT|O_TRUNC:
        {
            va_list ap;
            mode_t mode;
            va_start(ap, flags);
            mode = va_arg(ap, mode_t);
            va_end(ap);
            fs_fd = fs_create(fs_import, (void *) pathname, 0, mode);
            break;
        }
        default:
            printk(" unsupported flags\n");
            do_exit();
    }
    if (fs_fd < 0) {
	errno = EIO;
	return -1;
    }
    fd = alloc_fd(FTYPE_FILE);
    printk("-> %d\n", fd);
    files[fd].file.fd = fs_fd;
    files[fd].file.offset = 0;
    return fd;
}

int isatty(int fd)
{
    return files[fd].type == FTYPE_CONSOLE;
}

int read(int fd, void *buf, size_t nbytes)
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
	case FTYPE_FILE: {
	    ssize_t ret;
	    if (nbytes > PAGE_SIZE * FSIF_NR_READ_GNTS)
		nbytes = PAGE_SIZE * FSIF_NR_READ_GNTS;
	    ret = fs_read(fs_import, files[fd].file.fd, buf, nbytes, files[fd].file.offset);
	    if (ret > 0) {
		files[fd].file.offset += ret;
		return ret;
	    } else if (ret < 0) {
		errno = EIO;
		return -1;
	    }
	    return 0;
	}
#ifdef HAVE_LWIP
	case FTYPE_SOCKET:
	    return lwip_read(files[fd].socket.fd, buf, nbytes);
#endif
	case FTYPE_TAP: {
	    ssize_t ret;
	    ret = netfront_receive(files[fd].tap.dev, buf, nbytes);
	    if (ret <= 0) {
		errno = EAGAIN;
		return -1;
	    }
	    return ret;
	}
        case FTYPE_KBD: {
            int ret, n;
            n = nbytes / sizeof(union xenkbd_in_event);
            ret = kbdfront_receive(files[fd].kbd.dev, buf, n);
	    if (ret <= 0) {
		errno = EAGAIN;
		return -1;
	    }
	    return ret * sizeof(union xenkbd_in_event);
        }
        case FTYPE_FB: {
            int ret, n;
            n = nbytes / sizeof(union xenfb_in_event);
            ret = fbfront_receive(files[fd].fb.dev, buf, n);
	    if (ret <= 0) {
		errno = EAGAIN;
		return -1;
	    }
	    return ret * sizeof(union xenfb_in_event);
        }
	default:
	    break;
    }
    printk("read(%d): Bad descriptor\n", fd);
    errno = EBADF;
    return -1;
}

int write(int fd, const void *buf, size_t nbytes)
{
    switch (files[fd].type) {
	case FTYPE_CONSOLE:
	    console_print(files[fd].cons.dev, (char *)buf, nbytes);
	    return nbytes;
	case FTYPE_FILE: {
	    ssize_t ret;
	    if (nbytes > PAGE_SIZE * FSIF_NR_WRITE_GNTS)
		nbytes = PAGE_SIZE * FSIF_NR_WRITE_GNTS;
	    ret = fs_write(fs_import, files[fd].file.fd, (void *) buf, nbytes, files[fd].file.offset);
	    if (ret > 0) {
		files[fd].file.offset += ret;
		return ret;
	    } else if (ret < 0) {
		errno = EIO;
		return -1;
	    }
	    return 0;
	}
#ifdef HAVE_LWIP
	case FTYPE_SOCKET:
	    return lwip_write(files[fd].socket.fd, (void*) buf, nbytes);
#endif
	case FTYPE_TAP:
	    netfront_xmit(files[fd].tap.dev, (void*) buf, nbytes);
	    return nbytes;
	default:
	    break;
    }
    printk("write(%d): Bad descriptor\n", fd);
    errno = EBADF;
    return -1;
}

off_t lseek(int fd, off_t offset, int whence)
{
    if (files[fd].type != FTYPE_FILE) {
	errno = ESPIPE;
	return (off_t) -1;
    }
    switch (whence) {
	case SEEK_SET:
	    files[fd].file.offset = offset;
	    break;
	case SEEK_CUR:
	    files[fd].file.offset += offset;
	    break;
	case SEEK_END: {
	    struct stat st;
	    int ret;
	    ret = fstat(fd, &st);
	    if (ret)
		return -1;
	    files[fd].file.offset = st.st_size + offset;
	    break;
	}
	default:
	    errno = EINVAL;
	    return -1;
    }
    return files[fd].file.offset;
}

int fsync(int fd) {
    switch (files[fd].type) {
	case FTYPE_FILE: {
	    int ret;
	    ret = fs_sync(fs_import, files[fd].file.fd);
	    if (ret < 0) {
		errno = EIO;
		return -1;
	    }
	    return 0;
	}
	default:
	    break;
    }
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
	case FTYPE_FILE: {
	    int ret = fs_close(fs_import, files[fd].file.fd);
	    files[fd].type = FTYPE_NONE;
	    if (ret < 0) {
		errno = EIO;
		return -1;
	    }
	    return 0;
	}
	case FTYPE_XENBUS:
            xs_daemon_close((void*)(intptr_t) fd);
            return 0;
#ifdef HAVE_LWIP
	case FTYPE_SOCKET: {
	    int res = lwip_close(files[fd].socket.fd);
	    files[fd].type = FTYPE_NONE;
	    return res;
	}
#endif
	case FTYPE_XC:
	    xc_interface_close(fd);
	    return 0;
	case FTYPE_EVTCHN:
            xc_evtchn_close(fd);
            return 0;
	case FTYPE_GNTMAP:
	    xc_gnttab_close(fd);
	    return 0;
	case FTYPE_TAP:
	    shutdown_netfront(files[fd].tap.dev);
	    files[fd].type = FTYPE_NONE;
	    return 0;
	case FTYPE_BLK:
            shutdown_blkfront(files[fd].blk.dev);
	    files[fd].type = FTYPE_NONE;
	    return 0;
	case FTYPE_KBD:
            shutdown_kbdfront(files[fd].kbd.dev);
            files[fd].type = FTYPE_NONE;
            return 0;
	case FTYPE_FB:
            shutdown_fbfront(files[fd].fb.dev);
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

static void stat_from_fs(struct stat *buf, struct fsif_stat_response *stat)
{
    buf->st_mode = stat->stat_mode;
    buf->st_uid = stat->stat_uid;
    buf->st_gid = stat->stat_gid;
    buf->st_size = stat->stat_size;
    buf->st_atime = stat->stat_atime;
    buf->st_mtime = stat->stat_mtime;
    buf->st_ctime = stat->stat_ctime;
}

int stat(const char *path, struct stat *buf)
{
    struct fsif_stat_response stat;
    int ret;
    int fs_fd;
    printk("stat(%s)\n", path);
    fs_fd = fs_open(fs_import, (char*) path);
    if (fs_fd < 0) {
	errno = EIO;
	ret = -1;
	goto out;
    }
    ret = fs_stat(fs_import, fs_fd, &stat);
    if (ret < 0) {
	errno = EIO;
	ret = -1;
	goto outfd;
    }
    init_stat(buf);
    stat_from_fs(buf, &stat);
    ret = 0;

outfd:
    fs_close(fs_import, fs_fd);
out:
    return ret;
}

int fstat(int fd, struct stat *buf)
{
    init_stat(buf);
    switch (files[fd].type) {
	case FTYPE_CONSOLE:
	case FTYPE_SOCKET: {
	    buf->st_mode = (files[fd].type == FTYPE_CONSOLE?S_IFCHR:S_IFSOCK) | S_IRUSR|S_IWUSR;
	    buf->st_uid = 0;
	    buf->st_gid = 0;
	    buf->st_size = 0;
	    buf->st_atime = 
	    buf->st_mtime = 
	    buf->st_ctime = time(NULL);
	    return 0;
	}
	case FTYPE_FILE: {
	    struct fsif_stat_response stat;
	    int ret;
	    ret = fs_stat(fs_import, files[fd].file.fd, &stat);
	    if (ret < 0) {
		errno = EIO;
		return -1;
	    }
	    /* The protocol is a bit evasive about this value */
	    stat_from_fs(buf, &stat);
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
    switch (files[fd].type) {
	case FTYPE_FILE: {
            int ret;
            ret = fs_truncate(fs_import, files[fd].file.fd, length);
	    if (ret < 0) {
		errno = EIO;
		return -1;
	    }
	    return 0;
	}
	default:
	    break;
    }

    printk("ftruncate(%d): Bad descriptor\n", fd);
    errno = EBADF;
    return -1;
}

int remove(const char *pathname)
{
    int ret;
    printk("remove(%s)", pathname);
    ret = fs_remove(fs_import, (char*) pathname);
    if (ret < 0) {
        errno = EIO;
        return -1;
    }
    return 0;
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
#ifdef HAVE_LWIP
	case F_SETFL:
	    if (files[fd].type == FTYPE_SOCKET && !(arg & ~O_NONBLOCK)) {
		/* Only flag supported: non-blocking mode */
		uint32_t nblock = !!(arg & O_NONBLOCK);
		return lwip_ioctl(files[fd].socket.fd, FIONBIO, &nblock);
	    }
	    /* Fallthrough */
#endif
	default:
	    printk("fcntl(%d, %d, %lx/%lo)\n", fd, cmd, arg, arg);
	    errno = ENOSYS;
	    return -1;
    }
}

DIR *opendir(const char *name)
{
    DIR *ret;
    ret = malloc(sizeof(*ret));
    ret->name = strdup(name);
    ret->offset = 0;
    ret->entries = NULL;
    ret->curentry = -1;
    ret->nbentries = 0;
    ret->has_more = 1;
    return ret;
}

struct dirent *readdir(DIR *dir)
{
    if (dir->curentry >= 0) {
        free(dir->entries[dir->curentry]);
        dir->entries[dir->curentry] = NULL;
    }
    dir->curentry++;
    if (dir->curentry >= dir->nbentries) {
        dir->offset += dir->nbentries;
        free(dir->entries);
        dir->curentry = -1;
        dir->nbentries = 0;
        if (!dir->has_more)
            return NULL;
        dir->entries = fs_list(fs_import, dir->name, dir->offset, &dir->nbentries, &dir->has_more);
        if (!dir->entries || !dir->nbentries)
            return NULL;
        dir->curentry = 0;
    }
    dir->dirent.d_name = dir->entries[dir->curentry];
    return &dir->dirent;
} 
int closedir(DIR *dir)
{
    int i;
    for (i=0; i<dir->nbentries; i++)
        free(dir->entries[i]);
    free(dir->entries);
    free(dir->name);
    free(dir);
    return 0;
}

/* We assume that only the main thread calls select(). */

static const char file_types[] = {
    [FTYPE_NONE]	= 'N',
    [FTYPE_CONSOLE]	= 'C',
    [FTYPE_FILE]	= 'F',
    [FTYPE_XENBUS]	= 'S',
    [FTYPE_XC]		= 'X',
    [FTYPE_EVTCHN]	= 'E',
    [FTYPE_SOCKET]	= 's',
    [FTYPE_TAP]		= 'T',
    [FTYPE_BLK]		= 'B',
    [FTYPE_KBD]		= 'K',
    [FTYPE_FB]		= 'G',
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
#ifdef HAVE_LWIP
    int sock_n = 0, sock_nfds = 0;
    fd_set sock_readfds, sock_writefds, sock_exceptfds;
    struct timeval timeout = { .tv_sec = 0, .tv_usec = 0};
#endif

#ifdef LIBC_VERBOSE
    static int nb;
    static int nbread[NOFILE], nbwrite[NOFILE], nbexcept[NOFILE];
    static s_time_t lastshown;

    nb++;
#endif

#ifdef HAVE_LWIP
    /* first poll network */
    FD_ZERO(&sock_readfds);
    FD_ZERO(&sock_writefds);
    FD_ZERO(&sock_exceptfds);
    for (i = 0; i < nfds; i++) {
	if (files[i].type == FTYPE_SOCKET) {
	    if (FD_ISSET(i, readfds)) {
		FD_SET(files[i].socket.fd, &sock_readfds);
		sock_nfds = i+1;
	    }
	    if (FD_ISSET(i, writefds)) {
		FD_SET(files[i].socket.fd, &sock_writefds);
		sock_nfds = i+1;
	    }
	    if (FD_ISSET(i, exceptfds)) {
		FD_SET(files[i].socket.fd, &sock_exceptfds);
		sock_nfds = i+1;
	    }
	}
    }
    if (sock_nfds > 0) {
        DEBUG("lwip_select(");
        dump_set(nfds, &sock_readfds, &sock_writefds, &sock_exceptfds, &timeout);
        DEBUG("); -> ");
        sock_n = lwip_select(sock_nfds, &sock_readfds, &sock_writefds, &sock_exceptfds, &timeout);
        dump_set(nfds, &sock_readfds, &sock_writefds, &sock_exceptfds, &timeout);
        DEBUG("\n");
    }
#endif

    /* Then see others as well. */
    for (i = 0; i < nfds; i++) {
	switch(files[i].type) {
	default:
	    if (FD_ISSET(i, readfds) || FD_ISSET(i, writefds) || FD_ISSET(i, exceptfds))
		printk("bogus fd %d in select\n", i);
	    /* Fallthrough.  */
	case FTYPE_FILE:
	    FD_CLR(i, readfds);
	    FD_CLR(i, writefds);
	    FD_CLR(i, exceptfds);
	    break;
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
	case FTYPE_TAP:
	case FTYPE_BLK:
	case FTYPE_KBD:
	case FTYPE_FB:
	    if (FD_ISSET(i, readfds)) {
		if (files[i].read)
		    n++;
		else
		    FD_CLR(i, readfds);
	    }
	    FD_CLR(i, writefds);
	    FD_CLR(i, exceptfds);
	    break;
#ifdef HAVE_LWIP
	case FTYPE_SOCKET:
	    if (FD_ISSET(i, readfds)) {
	        /* Optimize no-network-packet case.  */
		if (sock_n && FD_ISSET(files[i].socket.fd, &sock_readfds))
		    n++;
		else
		    FD_CLR(i, readfds);
	    }
            if (FD_ISSET(i, writefds)) {
		if (sock_n && FD_ISSET(files[i].socket.fd, &sock_writefds))
		    n++;
		else
		    FD_CLR(i, writefds);
            }
            if (FD_ISSET(i, exceptfds)) {
		if (sock_n && FD_ISSET(files[i].socket.fd, &sock_exceptfds))
		    n++;
		else
		    FD_CLR(i, exceptfds);
            }
	    break;
#endif
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

/* The strategy is to
 * - announce that we will maybe sleep
 * - poll a bit ; if successful, return
 * - if timeout, return
 * - really sleep (except if somebody woke us in the meanwhile) */
int select(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds,
	struct timeval *timeout)
{
    int n, ret;
    fd_set myread, mywrite, myexcept;
    struct thread *thread = get_current();
    s_time_t start = NOW(), stop;
    DEFINE_WAIT(w1);
    DEFINE_WAIT(w2);
    DEFINE_WAIT(w3);
    DEFINE_WAIT(w4);
    DEFINE_WAIT(w5);
    DEFINE_WAIT(w6);

    assert(thread == main_thread);

    DEBUG("select(%d, ", nfds);
    dump_set(nfds, readfds, writefds, exceptfds, timeout);
    DEBUG(");\n");

    if (timeout)
	stop = start + SECONDS(timeout->tv_sec) + timeout->tv_usec * 1000;
    else
	/* just make gcc happy */
	stop = start;

    /* Tell people we're going to sleep before looking at what they are
     * saying, hence letting them wake us if events happen between here and
     * schedule() */
    add_waiter(w1, netfront_queue);
    add_waiter(w2, event_queue);
    add_waiter(w3, blkfront_queue);
    add_waiter(w4, xenbus_watch_queue);
    add_waiter(w5, kbdfront_queue);
    add_waiter(w6, console_queue);

    if (readfds)
        myread = *readfds;
    else
        FD_ZERO(&myread);
    if (writefds)
        mywrite = *writefds;
    else
        FD_ZERO(&mywrite);
    if (exceptfds)
        myexcept = *exceptfds;
    else
        FD_ZERO(&myexcept);

    DEBUG("polling ");
    dump_set(nfds, &myread, &mywrite, &myexcept, timeout);
    DEBUG("\n");
    n = select_poll(nfds, &myread, &mywrite, &myexcept);

    if (n) {
	dump_set(nfds, readfds, writefds, exceptfds, timeout);
	if (readfds)
	    *readfds = myread;
	if (writefds)
	    *writefds = mywrite;
	if (exceptfds)
	    *exceptfds = myexcept;
	DEBUG(" -> ");
	dump_set(nfds, readfds, writefds, exceptfds, timeout);
	DEBUG("\n");
	wake(thread);
	ret = n;
	goto out;
    }
    if (timeout && NOW() >= stop) {
	if (readfds)
	    FD_ZERO(readfds);
	if (writefds)
	    FD_ZERO(writefds);
	if (exceptfds)
	    FD_ZERO(exceptfds);
	timeout->tv_sec = 0;
	timeout->tv_usec = 0;
	wake(thread);
	ret = 0;
	goto out;
    }

    if (timeout)
	thread->wakeup_time = stop;
    schedule();

    if (readfds)
        myread = *readfds;
    else
        FD_ZERO(&myread);
    if (writefds)
        mywrite = *writefds;
    else
        FD_ZERO(&mywrite);
    if (exceptfds)
        myexcept = *exceptfds;
    else
        FD_ZERO(&myexcept);

    n = select_poll(nfds, &myread, &mywrite, &myexcept);

    if (n) {
	if (readfds)
	    *readfds = myread;
	if (writefds)
	    *writefds = mywrite;
	if (exceptfds)
	    *exceptfds = myexcept;
	ret = n;
	goto out;
    }
    errno = EINTR;
    ret = -1;

out:
    remove_waiter(w1);
    remove_waiter(w2);
    remove_waiter(w3);
    remove_waiter(w4);
    remove_waiter(w5);
    remove_waiter(w6);
    return ret;
}

#ifdef HAVE_LWIP
int socket(int domain, int type, int protocol)
{
    int fd, res;
    fd = lwip_socket(domain, type, protocol);
    if (fd < 0)
	return -1;
    res = alloc_fd(FTYPE_SOCKET);
    printk("socket -> %d\n", res);
    files[res].socket.fd = fd;
    return res;
}

int accept(int s, struct sockaddr *addr, socklen_t *addrlen)
{
    int fd, res;
    if (files[s].type != FTYPE_SOCKET) {
	printk("accept(%d): Bad descriptor\n", s);
	errno = EBADF;
	return -1;
    }
    fd = lwip_accept(files[s].socket.fd, addr, addrlen);
    if (fd < 0)
	return -1;
    res = alloc_fd(FTYPE_SOCKET);
    files[res].socket.fd = fd;
    printk("accepted on %d -> %d\n", s, res);
    return res;
}

#define LWIP_STUB(ret, name, proto, args) \
ret name proto \
{ \
    if (files[s].type != FTYPE_SOCKET) { \
	printk(#name "(%d): Bad descriptor\n", s); \
	errno = EBADF; \
	return -1; \
    } \
    s = files[s].socket.fd; \
    return lwip_##name args; \
}

LWIP_STUB(int, bind, (int s, struct sockaddr *my_addr, socklen_t addrlen), (s, my_addr, addrlen))
LWIP_STUB(int, getsockopt, (int s, int level, int optname, void *optval, socklen_t *optlen), (s, level, optname, optval, optlen))
LWIP_STUB(int, setsockopt, (int s, int level, int optname, void *optval, socklen_t optlen), (s, level, optname, optval, optlen))
LWIP_STUB(int, connect, (int s, struct sockaddr *serv_addr, socklen_t addrlen), (s, serv_addr, addrlen))
LWIP_STUB(int, listen, (int s, int backlog), (s, backlog));
LWIP_STUB(ssize_t, recv, (int s, void *buf, size_t len, int flags), (s, buf, len, flags))
LWIP_STUB(ssize_t, recvfrom, (int s, void *buf, size_t len, int flags, struct sockaddr *from, socklen_t *fromlen), (s, buf, len, flags, from, fromlen))
LWIP_STUB(ssize_t, send, (int s, void *buf, size_t len, int flags), (s, buf, len, flags))
LWIP_STUB(ssize_t, sendto, (int s, void *buf, size_t len, int flags, struct sockaddr *to, socklen_t tolen), (s, buf, len, flags, to, tolen))
LWIP_STUB(int, getsockname, (int s, struct sockaddr *name, socklen_t *namelen), (s, name, namelen))
#endif

static char *syslog_ident;
void openlog(const char *ident, int option, int facility)
{
    if (syslog_ident)
        free(syslog_ident);
    syslog_ident = strdup(ident);
}

void vsyslog(int priority, const char *format, va_list ap)
{
    printk("%s: ", syslog_ident);
    print(0, format, ap);
}

void syslog(int priority, const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    vsyslog(priority, format, ap);
    va_end(ap);
}

void closelog(void)
{
    free(syslog_ident);
    syslog_ident = NULL;
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

int usleep(useconds_t usec)
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
unsupported_function_crash(if_freenameindex);

/* Linuxish abi for the Caml runtime, don't support 
   Log, and return an error code if possible.  If it is not possible
   to inform the application of an error, then crash instead!
*/
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
#endif
