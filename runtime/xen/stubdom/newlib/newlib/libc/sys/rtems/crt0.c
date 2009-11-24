/*
 *  RTEMS Fake crt0
 *
 *  Each RTEMS BSP provides its own crt0 and linker script.  Unfortunately
 *  this means that crt0 and the linker script are not available as
 *  each tool is configured.  Without a crt0 and linker script, some
 *  targets do not successfully link "conftest.c" during the configuration 
 *  process.  So this fake crt0.c provides all the symbols required to
 *  successfully link a program.  The resulting program will not run
 *  but this is enough to satisfy the autoconf macro AC_PROG_CC.
 */

#include <reent.h>

void rtems_provides_crt0( void ) {}  /* dummy symbol so file always has one */

/* RTEMS provides some of its own routines including a Malloc family */

void *malloc() { return 0; }
void *realloc() { return 0; }
void free() { ; }
void abort() { ; }
int raise() { return -1; }

#if defined(__GNUC__)
/*
 * stubs for libstdc++ rtems-threads support functions from gcc/gthr-rtems.h
 */
int rtems_gxx_once() { return -1; }
int rtems_gxx_key_create() { return -1; }
int rtems_gxx_key_delete() { return -1; }
void *rtems_gxx_getspecific() { return 0; }
int rtems_gxx_setspecific() { return -1; }

void rtems_gxx_mutex_init() { }
int rtems_gxx_mutex_lock() { return -1; }
int rtems_gxx_mutex_trylock() { return -1; }
int rtems_gxx_mutex_unlock() { return -1; }

void rtems_gxx_recursive_mutex_init() { }
int rtems_gxx_recursive_mutex_lock() { return -1; }
int rtems_gxx_recursive_mutex_trylock() { return -1; }
int rtems_gxx_recursive_mutex_unlock() { return -1; }
#endif

/* stubs for functions from reent.h */
int _close_r (struct _reent *r, int fd) { return -1; }
#if NOT_USED_BY_RTEMS
int _execve_r (struct _reent *r, char *, char **, char **) { return -1; }
#endif
int _fcntl_r (  struct _reent *ptr, int fd, int cmd, int arg ) { return -1;}
#if NOT_USED_BY_RTEMS
int _fork_r (struct _reent *r) { return -1; }
#endif
int _fstat_r (struct _reent *r, int fd, struct stat *buf) { return -1; }
int _getpid_r (struct _reent *r) { return -1; }
int _kill_r ( struct _reent *r, int pid, int sig ) { return -1; }
int _link_r ( struct _reent *ptr, const char *existing, const char *new) { return -1; }
_off_t _lseek_r ( struct _reent *ptr, int fd, _off_t offset, int whence ) { return -1; }
int _open_r (struct _reent *r, const char *buf, int flags, int mode) { return -1; }
_ssize_t _read_r (struct _reent *r, int fd, void *buf, size_t nbytes) { return -1; }
#if NOT_USED_BY_RTEMS 
void *_sbrk_r (struct _reent *r, ptrdiff_t) { return -1; }
#endif
int _stat_r (struct _reent *r, const char *path, struct stat *buf) { return -1; }
_CLOCK_T_ _times_r (struct _reent *r, struct tms *ptms) { return -1; }
int _unlink_r (struct _reent *r, const char *path) { return -1; }
#if NOT_USED_BY_RTEMS
int _wait_r (struct _reent *r, int *) { return -1; }
#endif
_ssize_t _write_r (struct _reent *r, int fd, const void *buf, size_t nbytes) { return -1; }

int isatty( int fd ) { return -1; }

_realloc_r() {}
_calloc_r() {}
_malloc_r() {}
_free_r() {}

/* gcc can implicitly generate references to these */
/* strcmp() {} */
/* strcpy() {} */
/* strlen() {} */
/* memcmp() {} */
/* memcpy() {} */
/* memset() {} */

/* The PowerPC expects certain symbols to be defined in the linker script. */

#if defined(__PPC__)
  int __SDATA_START__;  int __SDATA2_START__;
  int __GOT_START__;    int __GOT_END__;
  int __GOT2_START__;   int __GOT2_END__;
  int __SBSS_END__;     int __SBSS2_END__;
  int __FIXUP_START__;  int __FIXUP_END__;
  int __EXCEPT_START__; int __EXCEPT_END__;
  int __init;           int __fini;
  int __CTOR_LIST__;    int __CTOR_END__;
  int __DTOR_LIST__;    int __DTOR_END__;
#endif

/* The SH expects certain symbols to be defined in the linker script. */

#if defined(__sh__)
int __EH_FRAME_BEGIN__;
#endif

/*  The hppa expects this to be defined in the real crt0.s. 
 *  Also for some reason, the hppa1.1 does not find atexit()
 *  during the AC_PROG_CC tests.
 */

#if defined(__hppa__)
/*
  asm ( ".subspa \$GLOBAL\$,QUAD=1,ALIGN=8,ACCESS=0x1f,SORT=40");
  asm ( ".export \$global\$" );
  asm ( "\$global\$:");
*/

  asm (".text");
  asm (".global");
  asm (".EXPORT $$dyncall,ENTRY");
  asm ("$$dyncall:");
  int atexit(void (*function)(void)) { return 0; }
#endif


/*
 *  The AMD a29k generates code expecting the following.
 */

#if defined(_AM29000) || defined(_AM29K)
asm (".global V_SPILL, V_FILL" );
asm (".global V_EPI_OS, V_BSD_OS" );

asm (".equ    V_SPILL, 64" );
asm (".equ    V_FILL, 65" );

asm (".equ    V_BSD_OS, 66" );
asm (".equ    V_EPI_OS, 69" );
#endif

#if defined(__AVR__)
/*
 * Initial stack pointer address "__stack"
 *  hard coded into GCC instead of providing it through ldscripts
 */
const char* __stack ;
#endif
