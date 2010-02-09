/*
 * malloc/free by O.Dreesen
 *
 * first TRY:
 *   lists w/magics
 * and now the second TRY
 *   let the kernel map all the stuff (if there is something to do)
 */

#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>
#include "dietfeatures.h"

#include <sys/cdefs.h>
#include <sys/types.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

#include <sys/shm.h>	/* for PAGE_SIZE */


/* -- HELPER CODE --------------------------------------------------------- */

#ifndef MAP_FAILED
#define MAP_FAILED ((void*)-1)
#endif

#ifndef NULL
#define NULL ((void*)0)
#endif

typedef struct {
  void*  next;
  size_t size;
} __alloc_t;

#define BLOCK_START(b)	(((void*)(b))-sizeof(__alloc_t))
#define BLOCK_RET(b)	(((void*)(b))+sizeof(__alloc_t))

#define MEM_BLOCK_SIZE	PAGE_SIZE
#define PAGE_ALIGN(s)	(((s)+MEM_BLOCK_SIZE-1)&(unsigned long)(~(MEM_BLOCK_SIZE-1)))

/* a simple mmap :) */
#if defined(__i386__)
#define REGPARM(x) __attribute__((regparm(x)))
#else
#define REGPARM(x)
#endif

static void REGPARM(1) *do_mmap(size_t size) {
  return mmap(0, size, PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_PRIVATE, -1, (size_t)0);
}

/* -- SMALL MEM ----------------------------------------------------------- */

static __alloc_t* __small_mem[8];

#define __SMALL_NR(i)		(MEM_BLOCK_SIZE/(i))

#define __MIN_SMALL_SIZE	__SMALL_NR(256)		/*   16 /   32 */
#define __MAX_SMALL_SIZE	__SMALL_NR(2)		/* 2048 / 4096 */

#define GET_SIZE(s)		(__MIN_SMALL_SIZE<<get_index((s)))

#define FIRST_SMALL(p)		(((unsigned long)(p))&(~(MEM_BLOCK_SIZE-1)))

static inline int __ind_shift() { return (MEM_BLOCK_SIZE==4096)?4:5; }

static size_t REGPARM(1) get_index(size_t _size) {
  register size_t idx=0;
//  if (_size) {	/* we already check this in the callers */
    register size_t size=((_size-1)&(MEM_BLOCK_SIZE-1))>>__ind_shift();
    while(size) { size>>=1; ++idx; }
//  }
  return idx;
}

/* small mem */
static void __small_free(void*_ptr,size_t _size) REGPARM(2);

static void REGPARM(2) __small_free(void*_ptr,size_t _size) {
  __alloc_t* ptr=BLOCK_START(_ptr);
  size_t size=_size;
  size_t idx=get_index(size);

#ifdef WANT_FREE_OVERWRITE
  memset(ptr,0x55,size);	/* allways zero out small mem */
#else
  memset(ptr,0,size);	/* allways zero out small mem */
#endif

  ptr->next=__small_mem[idx];
  __small_mem[idx]=ptr;
}

static void* REGPARM(1) __small_malloc(size_t _size) {
  __alloc_t *ptr;
  size_t size=_size;
  size_t idx;

  idx=get_index(size);
  ptr=__small_mem[idx];

  if (ptr==0)  {	/* no free blocks ? */
    register int i,nr;
    ptr=do_mmap(MEM_BLOCK_SIZE);
    if (ptr==MAP_FAILED) return MAP_FAILED;

    __small_mem[idx]=ptr;

    nr=__SMALL_NR(size)-1;
    for (i=0;i<nr;i++) {
      ptr->next=(((void*)ptr)+size);
      ptr=ptr->next;
    }
    ptr->next=0;

    ptr=__small_mem[idx];
  }

  /* get a free block */
  __small_mem[idx]=ptr->next;
  ptr->next=0;

  return ptr;
}

/* -- PUBLIC FUNCTIONS ---------------------------------------------------- */

static void _alloc_libc_free(void *ptr) {
  register size_t size;
  if (ptr) {
    size=((__alloc_t*)BLOCK_START(ptr))->size;
    if (size) {
      if (size<=__MAX_SMALL_SIZE)
	__small_free(ptr,size);
      else
	munmap(BLOCK_START(ptr),size);
    }
  }
}
void __libc_free(void *ptr) __attribute__((alias("_alloc_libc_free")));
void free(void *ptr) __attribute__((weak,alias("_alloc_libc_free")));
void if_freenameindex(void* ptr) __attribute__((alias("free")));

#ifdef WANT_MALLOC_ZERO
static __alloc_t zeromem[2];
#endif

static void* _alloc_libc_malloc(size_t size) {
  __alloc_t* ptr;
  size_t need;
#ifdef WANT_MALLOC_ZERO
  if (!size) return BLOCK_RET(zeromem);
#else
  if (!size) goto err_out;
#endif
  size+=sizeof(__alloc_t);
  if (size<sizeof(__alloc_t)) goto err_out;
  if (size<=__MAX_SMALL_SIZE) {
    need=GET_SIZE(size);
    ptr=__small_malloc(need);
  }
  else {
    need=PAGE_ALIGN(size);
    if (!need) ptr=MAP_FAILED; else ptr=do_mmap(need);
  }
  if (ptr==MAP_FAILED) goto err_out;
  ptr->size=need;
  return BLOCK_RET(ptr);
err_out:
  (*__errno_location())=ENOMEM;
  return 0;
}
void* __libc_malloc(size_t size) __attribute__((alias("_alloc_libc_malloc")));
void* malloc(size_t size) __attribute__((weak,alias("_alloc_libc_malloc")));

void* __libc_calloc(size_t nmemb, size_t _size);
void* __libc_calloc(size_t nmemb, size_t _size) {
  register size_t size=_size*nmemb;
  if (nmemb && size/nmemb!=_size) {
    (*__errno_location())=ENOMEM;
    return 0;
  }
#ifdef WANT_FREE_OVERWRITE
  if (size<__MAX_SMALL_SIZE) {
    void* x=malloc(size);
    memset(x,0,size);
    return x;
  } else
#endif
  return malloc(size);
}
void* calloc(size_t nmemb, size_t _size) __attribute__((weak,alias("__libc_calloc")));

void* __libc_realloc(void* ptr, size_t _size);
void* __libc_realloc(void* ptr, size_t _size) {
  register size_t size=_size;
  if (ptr) {
    if (size) {
      __alloc_t* tmp=BLOCK_START(ptr);
      size+=sizeof(__alloc_t);
      if (size<sizeof(__alloc_t)) goto retzero;
      size=(size<=__MAX_SMALL_SIZE)?GET_SIZE(size):PAGE_ALIGN(size);
      if (tmp->size!=size) {
	if ((tmp->size<=__MAX_SMALL_SIZE)) {
	  void *new=_alloc_libc_malloc(_size);
	  if (new) {
	    register __alloc_t* foo=BLOCK_START(new);
	    size=foo->size;
	    if (size>tmp->size) size=tmp->size;
	    if (size) memcpy(new,ptr,size-sizeof(__alloc_t));
	    _alloc_libc_free(ptr);
	  }
	  ptr=new;
	}
	else {
	  register __alloc_t* foo;
	  size=PAGE_ALIGN(size);
	  foo=mremap(tmp,tmp->size,size,MREMAP_MAYMOVE);
	  if (foo==MAP_FAILED) {
retzero:
	    (*__errno_location())=ENOMEM;
	    ptr=0;
	  }
	  else {
	    foo->size=size;
	    ptr=BLOCK_RET(foo);
	  }
	}
      }
    }
    else { /* size==0 */
      _alloc_libc_free(ptr);
      ptr = NULL;
    }
  }
  else { /* ptr==0 */
    if (size) {
      ptr=_alloc_libc_malloc(size);
    }
  }
  return ptr;
}
void* realloc(void* ptr, size_t size) __attribute__((weak,alias("__libc_realloc")));

