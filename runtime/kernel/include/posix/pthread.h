#ifndef _POSIX_PTHREAD_H
#define _POSIX_PTHREAD_H

#include <stdlib.h>

/* Let's be single-threaded for now.  */

typedef struct {
    void *ptr;
} *pthread_key_t;
static inline int pthread_key_create(pthread_key_t *key, void (*destr_function)(void*))
{
    *key = malloc(sizeof(**key));
    (*key)->ptr = NULL;
    return 0;
}
static inline int pthread_setspecific(pthread_key_t key, const void *pointer)
{
    key->ptr = (void*) pointer;
    return 0;
}
static inline void *pthread_getspecific(pthread_key_t key)
{
    return key->ptr;
}
static inline int pthread_key_delete(pthread_key_t key)
{
    free(key);
    return 0;
}



typedef struct {} pthread_mutexattr_t;
static inline int pthread_mutexattr_init(pthread_mutexattr_t *mattr) { return 0; }
#define PTHREAD_MUTEX_NORMAL 0
#define PTHREAD_MUTEX_RECURSIVE 1
static inline int pthread_mutexattr_settype(pthread_mutexattr_t *mattr, int kind) { return 0; }
static inline int pthread_mutexattr_destroy(pthread_mutexattr_t *mattr) { return 0; }
typedef struct {} pthread_mutex_t;
#define PTHREAD_MUTEX_INITIALIZER {}
static inline int pthread_mutex_init(pthread_mutex_t *mutex, pthread_mutexattr_t *mattr) { return 0; }
static inline int pthread_mutex_lock(pthread_mutex_t *mutex) { return 0; }
static inline int pthread_mutex_unlock(pthread_mutex_t *mutex) { return 0; }



typedef struct {
    int done;
} pthread_once_t;
#define PTHREAD_ONCE_INIT { 0 }

static inline int pthread_once(pthread_once_t *once_control, void (*init_routine)(void))
{
    if (!once_control->done) {
        once_control->done = 1;
        init_routine();
    }
    return 0;
}

#define __thread

#endif /* _POSIX_PTHREAD_H */
