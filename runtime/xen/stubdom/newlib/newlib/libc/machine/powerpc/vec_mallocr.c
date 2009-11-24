/* This code is based on mallocr.c written by Doug Lea which is released
   to the public domain.  Any changes to libc/stdlib/mallocr.c
   should be reflected here as well.    */

/* Preliminaries */

#ifndef __STD_C
#ifdef __STDC__
#define __STD_C     1
#else
#if __cplusplus
#define __STD_C     1
#else
#define __STD_C     0
#endif /*__cplusplus*/
#endif /*__STDC__*/
#endif /*__STD_C*/

#ifndef Void_t
#if __STD_C
#define Void_t      void
#else
#define Void_t      char
#endif
#endif /*Void_t*/

#if __STD_C
#include <stddef.h>   /* for size_t */
#else
#include <sys/types.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

#include <sys/config.h>

/*
  In newlib, all the publically visible routines take a reentrancy
  pointer.  We don't currently do anything much with it, but we do
  pass it to the lock routine.
 */

#include <reent.h>
#include <string.h>
#include <malloc.h>

#define MALLOC_LOCK __malloc_lock(reent_ptr)
#define MALLOC_UNLOCK __malloc_unlock(reent_ptr)

#ifdef SMALL_MEMORY
#define malloc_getpagesize (128)
#else
#define malloc_getpagesize (4096)
#endif

#if __STD_C
extern void __malloc_lock(struct _reent *);
extern void __malloc_unlock(struct _reent *);
#else
extern void __malloc_lock();
extern void __malloc_unlock();
#endif

#if __STD_C
#define RARG struct _reent *reent_ptr,
#define RONEARG struct _reent *reent_ptr
#else
#define RARG reent_ptr
#define RONEARG reent_ptr
#define RDECL struct _reent *reent_ptr;
#endif

#define RCALL reent_ptr,
#define RONECALL reent_ptr

/*
   Define MALLOC_LOCK and MALLOC_UNLOCK to C expressions to run to
   lock and unlock the malloc data structures.  MALLOC_LOCK may be
   called recursively.
 */

#ifndef MALLOC_LOCK
#define MALLOC_LOCK
#endif

#ifndef MALLOC_UNLOCK
#define MALLOC_UNLOCK
#endif

/*
  INTERNAL_SIZE_T is the word-size used for internal bookkeeping
  of chunk sizes. On a 64-bit machine, you can reduce malloc
  overhead by defining INTERNAL_SIZE_T to be a 32 bit `unsigned int'
  at the expense of not being able to handle requests greater than
  2^31. This limitation is hardly ever a concern; you are encouraged
  to set this. However, the default version is the same as size_t.
*/

#ifndef INTERNAL_SIZE_T
#define INTERNAL_SIZE_T size_t
#endif

/*
  Following is needed on implementations whereby long > size_t.
  The problem is caused because the code performs subtractions of
  size_t values and stores the result in long values.  In the case
  where long > size_t and the first value is actually less than
  the second value, the resultant value is positive.  For example,
  (long)(x - y) where x = 0 and y is 1 ends up being 0x00000000FFFFFFFF
  which is 2*31 - 1 instead of 0xFFFFFFFFFFFFFFFF.  This is due to the
  fact that assignment from unsigned to signed won't sign extend.
*/

#ifdef SIZE_T_SMALLER_THAN_LONG
#define long_sub_size_t(x, y) ( (x < y) ? -((long)(y - x)) : (x - y) );
#else
#define long_sub_size_t(x, y) ( (long)(x - y) )
#endif

/*
  REALLOC_ZERO_BYTES_FREES should be set if a call to
  realloc with zero bytes should be the same as a call to free.
  Some people think it should. Otherwise, since this malloc
  returns a unique pointer for malloc(0), so does realloc(p, 0). 
*/

/* The following macros are only invoked with (2n+1)-multiples of
   INTERNAL_SIZE_T units, with a positive integer n. This is exploited
   for fast inline execution when n is small. */

#define MALLOC_ZERO(charp, nbytes)                                            \
do {                                                                          \
  INTERNAL_SIZE_T mzsz = (nbytes);                                            \
  if(mzsz <= 9*sizeof(mzsz)) {                                                \
    INTERNAL_SIZE_T* mz = (INTERNAL_SIZE_T*) (charp);                         \
    if(mzsz >= 5*sizeof(mzsz)) {     *mz++ = 0;                               \
                                     *mz++ = 0;                               \
      if(mzsz >= 7*sizeof(mzsz)) {   *mz++ = 0;                               \
                                     *mz++ = 0;                               \
        if(mzsz >= 9*sizeof(mzsz)) { *mz++ = 0;                               \
                                     *mz++ = 0; }}}                           \
                                     *mz++ = 0;                               \
                                     *mz++ = 0;                               \
                                     *mz   = 0;                               \
  } else memset((charp), 0, mzsz);                                            \
} while(0)

#define MALLOC_COPY(dest,src,nbytes)                                          \
do {                                                                          \
  INTERNAL_SIZE_T mcsz = (nbytes);                                            \
  if(mcsz <= 9*sizeof(mcsz)) {                                                \
    INTERNAL_SIZE_T* mcsrc = (INTERNAL_SIZE_T*) (src);                        \
    INTERNAL_SIZE_T* mcdst = (INTERNAL_SIZE_T*) (dest);                       \
    if(mcsz >= 5*sizeof(mcsz)) {     *mcdst++ = *mcsrc++;                     \
                                     *mcdst++ = *mcsrc++;                     \
      if(mcsz >= 7*sizeof(mcsz)) {   *mcdst++ = *mcsrc++;                     \
                                     *mcdst++ = *mcsrc++;                     \
        if(mcsz >= 9*sizeof(mcsz)) { *mcdst++ = *mcsrc++;                     \
                                     *mcdst++ = *mcsrc++; }}}                 \
                                     *mcdst++ = *mcsrc++;                     \
                                     *mcdst++ = *mcsrc++;                     \
                                     *mcdst   = *mcsrc  ;                     \
  } else memcpy(dest, src, mcsz);                                             \
} while(0)

#define vECCALLOc	_vec_calloc_r
#define fREe		_free_r
#define mEMALIGn	_memalign_r
#define vECREALLOc	_vec_realloc_r
#
#if __STD_C

Void_t* vECREALLOc(RARG Void_t*, size_t);
Void_t* vECCALLOc(RARG size_t, size_t);
#else
Void_t* vECREALLOc();
Void_t* vECCALLOc();
#endif


#ifdef __cplusplus
};  /* end of extern "C" */
#endif

/*
  Type declarations
*/

struct malloc_chunk
{
  INTERNAL_SIZE_T prev_size; /* Size of previous chunk (if free). */
  INTERNAL_SIZE_T size;      /* Size in bytes, including overhead. */
  struct malloc_chunk* fd;   /* double links -- used only if free. */
  struct malloc_chunk* bk;
};

typedef struct malloc_chunk* mchunkptr;

/*  sizes, alignments */

#define SIZE_SZ                (sizeof(INTERNAL_SIZE_T))
#define MALLOC_ALIGN           16
#define MALLOC_ALIGNMENT       16
#define MALLOC_ALIGN_MASK      (MALLOC_ALIGNMENT - 1)
#define MINSIZE                (sizeof(struct malloc_chunk))

/* conversion from malloc headers to user pointers, and back */

#define chunk2mem(p)   ((Void_t*)((char*)(p) + 2*SIZE_SZ))
#define mem2chunk(mem) ((mchunkptr)((char*)(mem) - 2*SIZE_SZ))
/* pad request bytes into a usable size */

#define request2size(req) \
 (((long)((req) + (SIZE_SZ + MALLOC_ALIGN_MASK)) < \
  (long)(MINSIZE + MALLOC_ALIGN_MASK)) ? ((MINSIZE + MALLOC_ALIGN_MASK) & ~(MALLOC_ALIGN_MASK)) : \
   (((req) + (SIZE_SZ + MALLOC_ALIGN_MASK)) & ~(MALLOC_ALIGN_MASK)))


/* Check if m has acceptable alignment */

#define aligned_OK(m)    (((unsigned long)((m)) & (MALLOC_ALIGN_MASK)) == 0)

/* 
  Physical chunk operations  
*/


/* size field is or'ed with PREV_INUSE when previous adjacent chunk in use */

#define PREV_INUSE 0x1 

/* size field is or'ed with IS_MMAPPED if the chunk was obtained with mmap() */

#define IS_MMAPPED 0x2

/* Bits to mask off when extracting size */

#define SIZE_BITS (PREV_INUSE|IS_MMAPPED)


/* Ptr to next physical malloc_chunk. */

#define next_chunk(p) ((mchunkptr)( ((char*)(p)) + ((p)->size & ~PREV_INUSE) ))

/* Ptr to previous physical malloc_chunk */

#define prev_chunk(p)\
   ((mchunkptr)( ((char*)(p)) - ((p)->prev_size) ))


/* Treat space at ptr + offset as a chunk */

#define chunk_at_offset(p, s)  ((mchunkptr)(((char*)(p)) + (s)))




/* 
  Dealing with use bits 
*/

/* extract p's inuse bit */

#define inuse(p)\
((((mchunkptr)(((char*)(p))+((p)->size & ~PREV_INUSE)))->size) & PREV_INUSE)

/* extract inuse bit of previous chunk */

#define prev_inuse(p)  ((p)->size & PREV_INUSE)

/* check for mmap()'ed chunk */

#define chunk_is_mmapped(p) ((p)->size & IS_MMAPPED)

/* set/clear chunk as in use without otherwise disturbing */

#define set_inuse(p)\
((mchunkptr)(((char*)(p)) + ((p)->size & ~PREV_INUSE)))->size |= PREV_INUSE

#define clear_inuse(p)\
((mchunkptr)(((char*)(p)) + ((p)->size & ~PREV_INUSE)))->size &= ~(PREV_INUSE)

/* check/set/clear inuse bits in known places */

#define inuse_bit_at_offset(p, s)\
 (((mchunkptr)(((char*)(p)) + (s)))->size & PREV_INUSE)

#define set_inuse_bit_at_offset(p, s)\
 (((mchunkptr)(((char*)(p)) + (s)))->size |= PREV_INUSE)

#define clear_inuse_bit_at_offset(p, s)\
 (((mchunkptr)(((char*)(p)) + (s)))->size &= ~(PREV_INUSE))



/* 
  Dealing with size fields 
*/

/* Get size, ignoring use bits */

#define chunksize(p)          ((p)->size & ~(SIZE_BITS))

/* Set size at head, without disturbing its use bit */

#define set_head_size(p, s)   ((p)->size = (((p)->size & PREV_INUSE) | (s)))

/* Set size/use ignoring previous bits in header */

#define set_head(p, s)        ((p)->size = (s))



#ifdef DEFINE_VECREALLOC


#if __STD_C
Void_t* vECREALLOc(RARG Void_t* oldmem, size_t bytes)
#else
Void_t* vECREALLOc(RARG oldmem, bytes) RDECL Void_t* oldmem; size_t bytes;
#endif
{
  INTERNAL_SIZE_T    nb;      /* padded request size */

  mchunkptr oldp;             /* chunk corresponding to oldmem */
  INTERNAL_SIZE_T    oldsize; /* its size */

  mchunkptr newp;             /* chunk to return */
  INTERNAL_SIZE_T    newsize; /* its size */
  Void_t*   newmem;           /* corresponding user mem */

  mchunkptr remainder;        /* holds split off extra space from newp */
  INTERNAL_SIZE_T  remainder_size;   /* its size */

#ifdef REALLOC_ZERO_BYTES_FREES
  if (bytes == 0) { fREe(RCALL oldmem); return 0; }
#endif


  /* realloc of null is supposed to be same as malloc */
  if (oldmem == 0) return mEMALIGn(RCALL 16, bytes);

  MALLOC_LOCK;

  newp    = oldp    = mem2chunk(oldmem);
  newsize = oldsize = chunksize(oldp);

  nb = request2size(bytes);

  if ((long)(oldsize) < (long)(nb))  
  {
    /* Must allocate */

    newmem = mEMALIGn (RCALL 16, bytes);

    if (newmem == 0)  /* propagate failure */
    {
      MALLOC_UNLOCK;
      return 0;
    }

    /* copy, free, and exit */
    MALLOC_COPY(newmem, oldmem, oldsize - SIZE_SZ);
    fREe(RCALL oldmem);
    MALLOC_UNLOCK;
    return newmem;
  }

  remainder_size = long_sub_size_t(newsize, nb);

  if (remainder_size >= (long)MINSIZE) /* split off remainder */
  {
    remainder = chunk_at_offset(newp, nb);
    set_head_size(newp, nb);
    set_head(remainder, remainder_size | PREV_INUSE);
    set_inuse_bit_at_offset(remainder, remainder_size);
    fREe(RCALL chunk2mem(remainder)); /* let free() deal with it */
  }
  else
  {
    set_head_size(newp, newsize);
    set_inuse_bit_at_offset(newp, newsize);
  }

  MALLOC_UNLOCK;
  return chunk2mem(newp);
}

#endif /* DEFINE_VECREALLOC */


#ifdef DEFINE_VECCALLOC

/*

  calloc calls malloc, then zeroes out the allocated chunk.

*/

#if __STD_C
Void_t* vECCALLOc(RARG size_t n, size_t elem_size)
#else
Void_t* vECCALLOc(RARG n, elem_size) RDECL size_t n; size_t elem_size;
#endif
{
  INTERNAL_SIZE_T sz = n * elem_size;

  Void_t* mem;

  mem = mEMALIGn (RCALL 16, sz);

  if (mem == 0) 
  {
    return 0;
  }

  MALLOC_ZERO(mem, sz);
  return mem;
}

#endif /* DEFINE_VECCALLOC */

