
/* Functions used by mcheck/mprobe */
extern void (*__malloc_initialize_hook) (void);
extern void (*__free_hook) (void * __ptr, const void *);
extern void * (*__malloc_hook) (size_t __size, const void *);
extern void * (*__realloc_hook) (void * __ptr, size_t __size, const void *);
extern void * (*__memalign_hook) (size_t __alignment, size_t __size,
                                  const void *);
extern void (*__after_morecore_hook) (void);
extern void __malloc_check_init (void);

extern int __malloc_initialized;
