/* Warning: this code sets up the machine registers and segments needed
 * for -fstack-protector to work.  If you compile this function with
 * -fstack-protector, it will reference those registers before they are
 * set up properly, causing a segmentation fault.  Ubuntu adds
 * -fstack-protector to their gcc default options, so this breaks.  I
 * added a workaround to the Makefile to make sure this code is always
 * compiled with -fno-stack-protector for this reason.  Or, as a friend
 * put it: yo dawg. I herd u liek stack protektion. :-)
 */
#include <unistd.h>
#include <fcntl.h>
#include <alloca.h>
#include <sys/time.h>
#include <sys/tls.h>
#include <endian.h>
#include <elf.h>
#include "dietfeatures.h"

extern int main(int argc,char* argv[],char* envp[]);

#if defined(WANT_SSP)
extern unsigned long __guard;
#endif

#ifdef __i386__
int __modern_linux;
#endif

#ifdef WANT_TLS
/* __tdatasize is the size of the initialized thread local data section
 * __tmemsize is the size of the complete thread local data section
 *   (including uninitialized data)
 * __tdataptr is a pointer to the initialized thread local data section
 * __tmemsize is already rounded up to meet alignment
 * the final memory layout is [tdata] [tbss (zero)] [tcb] */
size_t __tdatasize, __tmemsize;
void* __tdataptr;

static void findtlsdata(long* auxvec) {
#if (__WORDSIZE == 64)
  Elf64_Phdr* x=0;
#else
  Elf32_Phdr* x=0;
#endif
  size_t i,n=0;
  while (*auxvec) {
    if (auxvec[0]==3) {	/* AT_PHDR */
      x=(void*)auxvec[1];
      if (n) break;
    } else if (auxvec[0]==5) { /* AT_PHNUM */
      n=auxvec[1];
      if (x) break;
    }
    auxvec+=2;
  } /* if we don't find the entry, the kernel let us down */
  if (!x || !n) return;	/* a kernel this old does not support thread local storage anyway */
  for (i=0; i<n; ++i)
    if (x[i].p_type==PT_TLS) {
      __tdataptr=(void*)x[i].p_vaddr;
      __tdatasize=x[i].p_filesz;
      __tmemsize=x[i].p_memsz;
      break;
    }
  /* if there is no PT_TLS section, there is no thread-local data, and
   * we just leave the __t* variables zero */
}
#endif

#if defined(WANT_SSP) || defined(WANT_TLS)
tcbhead_t* __tcb_mainthread;

void __setup_tls(tcbhead_t*);

void __setup_tls(tcbhead_t* mainthread) {
  mainthread->tcb=mainthread;
  mainthread->dtv=0;
  mainthread->self=0;
  mainthread->multiple_threads=0;
#if defined(WANT_SSP)
  mainthread->stack_guard=__guard;
#endif

#if defined(__x86_64__)

  arch_prctl(ARCH_SET_FS, mainthread);

#elif defined(__i386__)

  unsigned int sd[4];
  sd[0]=-1;
  sd[1]=(unsigned long int)mainthread;
  sd[2]=0xfffff; /* 4 GB limit */
  sd[3]=0x51; /* bitfield, see struct user_desc in asm-i386/ldt.h */
  if (__modern_linux>=0)
    if (set_thread_area((struct user_desc*)(void*)&sd)==0) {
      asm volatile ("movw %w0, %%gs" :: "q" (sd[0]*8+3));
      __modern_linux=1;
    } else
      __modern_linux=-1;

#elif defined(__alpha__) || defined(__s390__)
  __builtin_set_thread_pointer(mainthread);
#elif defined(__ia64__) || defined(__powerpc__)
  register tcbhead_t* __thread_self __asm__("r13");
  __thread_self=mainthread;
#elif defined(__sparc__)
  register tcbhead_t* __thread_self __asm("%g7");
  __thread_self=mainthread;
#else
#warning "no idea how to enable TLS on this platform, edit lib/stackgap.c"
#endif
}
#endif

static void* find_rand(long* x) {
  while (*x) {
    if (*x==25)
      return (void*)x[1];
    x+=2;
  }
  return NULL;
}

int stackgap(int argc,char* argv[],char* envp[]);
int stackgap(int argc,char* argv[],char* envp[]) {
#if defined(WANT_STACKGAP) || defined(WANT_SSP) || defined(WANT_TLS)
  long* auxvec=(long*)envp;
  char* rand;
  char* tlsdata;
  while (*auxvec) ++auxvec; ++auxvec;	/* skip envp to get to auxvec */
#ifdef WANT_STACKGAP
  unsigned short s;
#endif
#if defined(WANT_STACKGAP) || defined(WANT_SSP)
  volatile char* gap;
  rand=find_rand(auxvec);
  if (!rand) {
    char myrand[10];
    int fd=open("/dev/urandom",O_RDONLY);
    read(fd,myrand,10);
    close(fd);
    rand=myrand;
  }
#endif
#ifdef WANT_STACKGAP
  s=*(unsigned short*)(rand+8);
#endif
#ifdef WANT_SSP
  __guard=*(unsigned long*)rand;
#endif
#ifdef WANT_STACKGAP
  gap=alloca(s);
#endif
#endif

#ifdef WANT_TLS
  findtlsdata(auxvec);
  if (__unlikely(__tmemsize+sizeof(tcbhead_t)<sizeof(tcbhead_t)) ||
      __unlikely(__tmemsize>512*1024*1024) ||
      __unlikely(__tmemsize<__tdatasize))
    return 111;
  tlsdata=alloca(__tmemsize+sizeof(tcbhead_t));
  memcpy(tlsdata,__tdataptr,__tdatasize);
  memset(tlsdata+__tdatasize,0,__tmemsize-__tdatasize);
  __setup_tls(__tcb_mainthread=(tcbhead_t*)(tlsdata+__tmemsize));
#elif defined(WANT_SSP)
  tlsdata=alloca(sizeof(tcbhead_t));
  __setup_tls(__tcb_mainthread=(tcbhead_t*)(tlsdata));
#endif
  return main(argc,argv,envp);
}

