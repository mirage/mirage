
#ifndef __XMALLOC_H__
#define __XMALLOC_H__

/*
 * Xen malloc/free-style interface.
 */

/* Allocate space for typed object. */
#define xmalloc(_type) ((_type *)_xmalloc(sizeof(_type), __alignof__(_type)))

/* Allocate space for array of typed objects. */
#define xmalloc_array(_type, _num) \
    ((_type *)_xmalloc_array(sizeof(_type), __alignof__(_type), _num))

/* Allocate untyped storage. */
#define xmalloc_bytes(_bytes) (_xmalloc(_bytes, SMP_CACHE_BYTES))

/* Free any of the above. */
extern void xfree(void *);

/* Underlying functions */
extern void *_xmalloc(unsigned long size, unsigned long align);
static inline void *_xmalloc_array(
    unsigned long size, unsigned long align, unsigned long num)
{
	/* Check for overflow. */
	if (size && num > UINT_MAX / size)
		return NULL;
 	return _xmalloc(size * num, align);
}

/*
 * Pooled allocator interface.
 */

struct xmem_pool;

typedef void *(xmem_pool_get_memory)(unsigned long bytes);
typedef void (xmem_pool_put_memory)(void *ptr);

/**
 * xmem_pool_create - create dynamic memory pool
 * @name: name of the pool
 * @get_mem: callback function used to expand pool
 * @put_mem: callback function used to shrink pool
 * @init_size: inital pool size (in bytes)
 * @max_size: maximum pool size (in bytes) - set this as 0 for no limit
 * @grow_size: amount of memory (in bytes) added to pool whenever required
 *
 * All size values are rounded up to next page boundary.
 */
struct xmem_pool *xmem_pool_create(
    const char *name,
    xmem_pool_get_memory get_mem,
    xmem_pool_put_memory put_mem,
    unsigned long init_size,
    unsigned long max_size,
    unsigned long grow_size);

/**
 * xmem_pool_destroy - cleanup given pool
 * @mem_pool: Pool to be destroyed
 *
 * Data structures associated with pool are freed.
 * All memory allocated from pool must be freed before
 * destorying it.
 */
void xmem_pool_destroy(struct xmem_pool *pool);

/**
 * xmem_pool_alloc - allocate memory from given pool
 * @size: no. of bytes
 * @mem_pool: pool to allocate from
 */
void *xmem_pool_alloc(unsigned long size, struct xmem_pool *pool);

/**
 * xmem_pool_maxalloc - xmem_pool_alloc's greater than this size will fail
 * @mem_pool: pool
 */
int xmem_pool_maxalloc(struct xmem_pool *pool);

/**
 * xmem_pool_maxsize - 
 * @ptr: address of memory to be freed
 * @mem_pool: pool to free from
 */
void xmem_pool_free(void *ptr, struct xmem_pool *pool);

/**
 * xmem_pool_get_used_size - get memory currently used by given pool
 *
 * Used memory includes stored data + metadata + internal fragmentation
 */
unsigned long xmem_pool_get_used_size(struct xmem_pool *pool);

/**
 * xmem_pool_get_total_size - get total memory currently allocated for pool
 *
 * This is the total memory currently allocated for this pool which includes
 * used size + free size.
 *
 * (Total - Used) is good indicator of memory efficiency of allocator.
 */
unsigned long xmem_pool_get_total_size(struct xmem_pool *pool);

#endif /* __XMALLOC_H__ */
