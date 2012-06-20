#ifndef _SYS_TLS_H
#define _SYS_TLS_H

#include <inttypes.h>
#include <stddef.h>
#include <stdbool.h>

/* Type for the dtv.  */
typedef union dtv
{
  size_t counter;
  struct
  {
    void *val;
    bool is_static;
  } pointer;
} dtv_t;

typedef struct
{
  void *tcb;            /* Pointer to the TCB.  Not necessary the
                           thread descriptor used by libpthread.  */
  dtv_t *dtv;
  void *self;           /* Pointer to the thread descriptor.  */
  int multiple_threads;
#ifdef __x86_64__
  int gscope_flag;
#endif
  uintptr_t sysinfo;
  uintptr_t stack_guard;
  uintptr_t pointer_guard;
#ifdef __i386__
  int gscope_flag;
#endif
} tcbhead_t;

tcbhead_t* __get_cur_tcb(void) __THROW;

#if defined(__i386__)

struct user_desc {
	unsigned int  entry_number;
	unsigned long base_addr;
	unsigned int  limit;
	unsigned int  seg_32bit:1;
	unsigned int  contents:2;
	unsigned int  read_exec_only:1;
	unsigned int  limit_in_pages:1;
	unsigned int  seg_not_present:1;
	unsigned int  useable:1;
};

int set_thread_area(struct user_desc* uinfo);

#elif defined(__x86_64__)

#define ARCH_SET_GS 0x1001
#define ARCH_SET_FS 0x1002
#define ARCH_GET_FS 0x1003
#define ARCH_GET_GS 0x1004

int arch_prctl(unsigned int what, void* where);

#else

#warning "need proper sys/tls.h for this platform"

#endif

#endif
