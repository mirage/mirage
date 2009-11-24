/* A replacement malloc with:
   - Much reduced code size;
   - Smaller RAM footprint;
   - The ability to handle downward-growing heaps;
   but
   - Slower;
   - Probably higher memory fragmentation;
   - Doesn't support threads (but, if it did support threads,
     it wouldn't need a global lock, only a compare-and-swap instruction);
   - Assumes the maximum alignment required is the alignment of a pointer;
   - Assumes that memory is already there and doesn't need to be allocated.

* Synopsis of public routines

  malloc(size_t n);
     Return a pointer to a newly allocated chunk of at least n bytes, or null
     if no space is available.
  free(void* p);
     Release the chunk of memory pointed to by p, or no effect if p is null.
  realloc(void* p, size_t n);
     Return a pointer to a chunk of size n that contains the same data
     as does chunk p up to the minimum of (n, p's size) bytes, or null
     if no space is available. The returned pointer may or may not be
     the same as p. If p is null, equivalent to malloc.  Unless the
     #define REALLOC_ZERO_BYTES_FREES below is set, realloc with a
     size argument of zero (re)allocates a minimum-sized chunk.
  memalign(size_t alignment, size_t n);
     Return a pointer to a newly allocated chunk of n bytes, aligned
     in accord with the alignment argument, which must be a power of
     two.  Will fail if 'alignment' is too large.
  calloc(size_t unit, size_t quantity);
     Returns a pointer to quantity * unit bytes, with all locations
     set to zero.
  cfree(void* p);
     Equivalent to free(p).
  malloc_trim(size_t pad);
     Release all but pad bytes of freed top-most memory back 
     to the system. Return 1 if successful, else 0.
  malloc_usable_size(void* p);
     Report the number usable allocated bytes associated with allocated
     chunk p. This may or may not report more bytes than were requested,
     due to alignment and minimum size constraints.
  malloc_stats();
     Prints brief summary statistics on stderr.
  mallinfo()
     Returns (by copy) a struct containing various summary statistics.
  mallopt(int parameter_number, int parameter_value)
     Changes one of the tunable parameters described below. Returns
     1 if successful in changing the parameter, else 0.  Actually, returns 0
     always, as no parameter can be changed.
*/

#ifdef __xstormy16__
#define MALLOC_DIRECTION -1
#endif

#ifndef MALLOC_DIRECTION
#define MALLOC_DIRECTION 1
#endif

#include <stddef.h>

void* malloc(size_t);
void    free(void*);
void* realloc(void*, size_t);
void* memalign(size_t, size_t);
void* valloc(size_t);
void* pvalloc(size_t);
void* calloc(size_t, size_t);
void    cfree(void*);
int     malloc_trim(size_t);
size_t  malloc_usable_size(void*);
void    malloc_stats(void);
int     mallopt(int, int);
struct mallinfo mallinfo(void);

typedef struct freelist_entry {
  size_t size;
  struct freelist_entry *next;
} *fle;

extern void * __malloc_end;
extern fle __malloc_freelist;

/* Return the number of bytes that need to be added to X to make it
   aligned to an ALIGN boundary.  ALIGN must be a power of 2.  */
#define M_ALIGN(x, align) (-(size_t)(x) & ((align) - 1))

/* Return the number of bytes that need to be subtracted from X to make it
   aligned to an ALIGN boundary.  ALIGN must be a power of 2.  */
#define M_ALIGN_SUB(x, align) ((size_t)(x) & ((align) - 1))

extern void __malloc_start;

/* This is the minimum gap allowed between __malloc_end and the top of
   the stack.  This is only checked for when __malloc_end is
   decreased; if instead the stack grows into the heap, silent data
   corruption will result.  */
#define MALLOC_MINIMUM_GAP 32

#ifdef __xstormy16__
register void * stack_pointer asm ("r15");
#define MALLOC_LIMIT stack_pointer
#else
#define MALLOC_LIMIT __builtin_frame_address (0)
#endif

#if MALLOC_DIRECTION < 0
#define CAN_ALLOC_P(required)				\
  (((size_t) __malloc_end - (size_t)MALLOC_LIMIT	\
    - MALLOC_MINIMUM_GAP) >= (required))
#else
#define CAN_ALLOC_P(required)				\
  (((size_t)MALLOC_LIMIT - (size_t) __malloc_end	\
    - MALLOC_MINIMUM_GAP) >= (required))
#endif

/* real_size is the size we actually have to allocate, allowing for
   overhead and alignment.  */
#define REAL_SIZE(sz)						\
  ((sz) < sizeof (struct freelist_entry) - sizeof (size_t)	\
   ? sizeof (struct freelist_entry)				\
   : sz + sizeof (size_t) + M_ALIGN(sz, sizeof (size_t)))

#ifdef DEFINE_MALLOC

void * __malloc_end = &__malloc_start;
fle __malloc_freelist;

void *
malloc (size_t sz)
{
  fle *nextfree;
  fle block;

  /* real_size is the size we actually have to allocate, allowing for
     overhead and alignment.  */
  size_t real_size = REAL_SIZE (sz);

  /* Look for the first block on the freelist that is large enough.  */
  for (nextfree = &__malloc_freelist; 
       *nextfree; 
       nextfree = &(*nextfree)->next)  
    {
      block = *nextfree;
      
      if (block->size >= real_size)
	{
	  /* If the block found is just the right size, remove it from
	     the free list.  Otherwise, split it.  */
	  if (block->size < real_size + sizeof (struct freelist_entry))
	    {
	      *nextfree = block->next;
	      return (void *)&block->next;
	    }
	  else
	    {
	      size_t newsize = block->size - real_size;
	      fle newnext = block->next;
	      *nextfree = (fle)((size_t)block + real_size);
	      (*nextfree)->size = newsize;
	      (*nextfree)->next = newnext;
	      goto done;
	    }
	}

      /* If this is the last block on the freelist, and it was too small,
	 enlarge it.  */
      if (! block->next
	  && __malloc_end == (void *)((size_t)block + block->size))
	{
	  size_t moresize = real_size - block->size;
	  if (! CAN_ALLOC_P (moresize))
	    return NULL;
	  
	  *nextfree = NULL;
	  if (MALLOC_DIRECTION < 0)
	    {
	      block = __malloc_end = (void *)((size_t)block - moresize);
	    }
	  else
	    {
	      __malloc_end = (void *)((size_t)block + real_size);
	    }

	  goto done;
	}
    }

  /* No free space at the end of the free list.  Allocate new space
     and use that.  */

  if (! CAN_ALLOC_P (real_size))
    return NULL;

  if (MALLOC_DIRECTION > 0)
    {
      block = __malloc_end;
      __malloc_end = (void *)((size_t)__malloc_end + real_size);
    }
  else
    {
      block = __malloc_end = (void *)((size_t)__malloc_end - real_size);
    }
 done:
  block->size = real_size;
  return (void *)&block->next;
}

#endif

#ifdef DEFINE_FREE

void
free (void *block_p)
{
  fle *nextfree;
  fle block = (fle)((size_t) block_p - offsetof (struct freelist_entry, next));

  if (block_p == NULL)
    return;
  
  /* Look on the freelist to see if there's a free block just before
     or just after this block.  */
  for (nextfree = &__malloc_freelist; 
       *nextfree; 
       nextfree = &(*nextfree)->next)
    {
      fle thisblock = *nextfree;
      if ((size_t)thisblock + thisblock->size == (size_t) block)
	{
	  thisblock->size += block->size;
	  if (MALLOC_DIRECTION > 0
	      && thisblock->next
	      && (size_t) block + block->size == (size_t) thisblock->next)
	    {
	      thisblock->size += thisblock->next->size;
	      thisblock->next = thisblock->next->next;
	    }
	  return;
	}
      else if ((size_t) thisblock == (size_t) block + block->size)
	{
	  if (MALLOC_DIRECTION < 0
	      && thisblock->next
	      && (size_t) block == ((size_t) thisblock->next 
				    + thisblock->next->size))
	    {
	      *nextfree = thisblock->next;
	      thisblock->next->size += block->size + thisblock->size;
	    }
	  else
	    {
	      block->size += thisblock->size;
	      block->next = thisblock->next;
	      *nextfree = block;
	    }
	  return;
	}
      else if ((MALLOC_DIRECTION > 0
		&& (size_t) thisblock > (size_t) block)
	       || (MALLOC_DIRECTION < 0
		   && (size_t) thisblock < (size_t) block))
	break;
    }

  block->next = *nextfree;
  *nextfree = block;
  return;
}
#endif

#ifdef DEFINE_REALLOC
void *
realloc (void *block_p, size_t sz)
{
  fle block = (fle)((size_t) block_p - offsetof (struct freelist_entry, next));
  size_t real_size = REAL_SIZE (sz);
  size_t old_real_size;

  if (block_p == NULL)
    return malloc (sz);

  old_real_size = block->size;

  /* Perhaps we need to allocate more space.  */
  if (old_real_size < real_size)
    {
      void *result;
      size_t old_size = old_real_size - sizeof (size_t);
      
      /* Need to allocate, copy, and free.  */
      result = malloc (sz);
      if (result == NULL)
	return NULL;
      memcpy (result, block_p, old_size < sz ? old_size : sz);
      free (block_p);
      return result;
    }
  /* Perhaps we can free some space.  */
  if (old_real_size - real_size >= sizeof (struct freelist_entry))
    {
      fle newblock = (fle)((size_t)block + real_size);
      block->size = real_size;
      newblock->size = old_real_size - real_size;
      free (&newblock->next);
    }
  return block_p;
}
#endif

#ifdef DEFINE_CALLOC
void *
calloc (size_t n, size_t elem_size)
{
  void *result;
  size_t sz = n * elem_size;
  result = malloc (sz);
  if (result != NULL)
    memset (result, 0, sz);
  return result;
}
#endif

#ifdef DEFINE_CFREE
void
cfree (void *p)
{
  free (p);
}
#endif

#ifdef DEFINE_MEMALIGN
void *
memalign (size_t align, size_t sz)
{
  fle *nextfree;
  fle block;

  /* real_size is the size we actually have to allocate, allowing for
     overhead and alignment.  */
  size_t real_size = REAL_SIZE (sz);

  /* Some sanity checking on 'align'. */
  if ((align & (align - 1)) != 0
      || align <= 0)
    return NULL;

  /* Look for the first block on the freelist that is large enough.  */
  /* One tricky part is this: We want the result to be a valid pointer
     to free.  That means that there has to be room for a size_t
     before the block.  If there's additional space before the block,
     it should go on the freelist, or it'll be lost---we could add it
     to the size of the block before it in memory, but finding the
     previous block is expensive.  */
  for (nextfree = &__malloc_freelist; 
       ; 
       nextfree = &(*nextfree)->next)  
    {
      size_t before_size;
      size_t old_size;

      /* If we've run out of free blocks, allocate more space.  */
      if (! *nextfree)
	{
	  old_size = real_size;
	  if (MALLOC_DIRECTION < 0)
	    {
	      old_size += M_ALIGN_SUB (((size_t)__malloc_end 
					- old_size + sizeof (size_t)),
				       align);
	      if (! CAN_ALLOC_P (old_size))
		return NULL;
	      block = __malloc_end = (void *)((size_t)__malloc_end - old_size);
	    }
	  else
	    {
	      block = __malloc_end;
	      old_size += M_ALIGN ((size_t)__malloc_end + sizeof (size_t),
				   align);
	      if (! CAN_ALLOC_P (old_size))
		return NULL;
	      __malloc_end = (void *)((size_t)__malloc_end + old_size);
	    }
	  *nextfree = block;
	  block->size = old_size;
	  block->next = NULL;
	}
      else
	{
	  block = *nextfree;
	  old_size = block->size;
	}
      

      before_size = M_ALIGN (&block->next, align);
      if (before_size != 0)
	before_size = sizeof (*block) + M_ALIGN (&(block+1)->next, align);

      /* If this is the last block on the freelist, and it is too small,
	 enlarge it.  */
      if (! block->next
	  && old_size < real_size + before_size
	  && __malloc_end == (void *)((size_t)block + block->size))
	{
	  if (MALLOC_DIRECTION < 0)
	    {
	      size_t moresize = real_size - block->size;
	      moresize += M_ALIGN_SUB ((size_t)&block->next - moresize, align);
	      if (! CAN_ALLOC_P (moresize))
		return NULL;
	      block = __malloc_end = (void *)((size_t)block - moresize);
	      block->next = NULL;
	      block->size = old_size = old_size + moresize;
	      before_size = 0;
	    }
	  else
	    {
	      if (! CAN_ALLOC_P (before_size + real_size - block->size))
		return NULL;
	      __malloc_end = (void *)((size_t)block + before_size + real_size);
	      block->size = old_size = before_size + real_size;
	    }

	  /* Two out of the four cases below will now be possible; which
	     two depends on MALLOC_DIRECTION.  */
	}

      if (old_size >= real_size + before_size)
	{
	  /* This block will do.  If there needs to be space before it, 
	     split the block.  */
	  if (before_size != 0)
	    {
	      fle old_block = block;

	      old_block->size = before_size;
	      block = (fle)((size_t)block + before_size);
	      
	      /* If there's no space after the block, we're now nearly
                 done; just make a note of the size required.  
	         Otherwise, we need to create a new free space block.  */
	      if (old_size - before_size 
		  <= real_size + sizeof (struct freelist_entry))
		{
		  block->size = old_size - before_size;
		  return (void *)&block->next;
		}
	      else 
		{
		  fle new_block;
		  new_block = (fle)((size_t)block + real_size);
		  new_block->size = old_size - before_size - real_size;
		  if (MALLOC_DIRECTION > 0)
		    {
		      new_block->next = old_block->next;
		      old_block->next = new_block;
		    }
		  else
		    {
		      new_block->next = old_block;
		      *nextfree = new_block;
		    }
		  goto done;
		}
	    }
	  else
	    {
	      /* If the block found is just the right size, remove it from
		 the free list.  Otherwise, split it.  */
	      if (old_size <= real_size + sizeof (struct freelist_entry))
		{
		  *nextfree = block->next;
		  return (void *)&block->next;
		}
	      else
		{
		  size_t newsize = old_size - real_size;
		  fle newnext = block->next;
		  *nextfree = (fle)((size_t)block + real_size);
		  (*nextfree)->size = newsize;
		  (*nextfree)->next = newnext;
		  goto done;
		}
	    }
	}
    }

 done:
  block->size = real_size;
  return (void *)&block->next;
}
#endif

#ifdef DEFINE_VALLOC
void *
valloc (size_t sz)
{
  return memalign (128, sz);
}
#endif
#ifdef DEFINE_PVALLOC
void *
pvalloc (size_t sz)
{
  return memalign (128, sz + M_ALIGN (sz, 128));
}
#endif

#ifdef DEFINE_MALLINFO
#include "malloc.h"

struct mallinfo 
mallinfo (void)
{
  struct mallinfo r;
  fle fr;
  size_t free_size;
  size_t total_size;
  size_t free_blocks;

  memset (&r, 0, sizeof (r));

  free_size = 0;
  free_blocks = 0;
  for (fr = __malloc_freelist; fr; fr = fr->next)
    {
      free_size += fr->size;
      free_blocks++;
      if (! fr->next)
	{
	  int atend;
	  if (MALLOC_DIRECTION > 0)
	    atend = (void *)((size_t)fr + fr->size) == __malloc_end;
	  else
	    atend = (void *)fr == __malloc_end;
	  if (atend)
	    r.keepcost = fr->size;
	}
    }

  if (MALLOC_DIRECTION > 0)
    total_size = (char *)__malloc_end - (char *)&__malloc_start;
  else
    total_size = (char *)&__malloc_start - (char *)__malloc_end;
  
#ifdef DEBUG
  /* Fixme: should walk through all the in-use blocks and see if
     they're valid.  */
#endif

  r.arena = total_size;
  r.fordblks = free_size;
  r.uordblks = total_size - free_size;
  r.ordblks = free_blocks;
  return r;
}
#endif

#ifdef DEFINE_MALLOC_STATS
#include "malloc.h"
#include <stdio.h>

void 
malloc_stats(void)
{
  struct mallinfo i;
  FILE *fp;
  
  fp = stderr;
  i = mallinfo();
  fprintf (fp, "malloc has reserved %u bytes between %p and %p\n",
	   i.arena, &__malloc_start, __malloc_end);
  fprintf (fp, "there are %u bytes free in %u chunks\n",
	   i.fordblks, i.ordblks);
  fprintf (fp, "of which %u bytes are at the end of the reserved space\n",
	   i.keepcost);
  fprintf (fp, "and %u bytes are in use.\n", i.uordblks);
}
#endif

#ifdef DEFINE_MALLOC_USABLE_SIZE
size_t 
malloc_usable_size (void *block_p)
{
  fle block = (fle)((size_t) block_p - offsetof (struct freelist_entry, next));
  return block->size - sizeof (size_t);
}
#endif

#ifdef DEFINE_MALLOPT
int
mallopt (int n, int v)
{
  (void)n; (void)v;
  return 0;
}
#endif
