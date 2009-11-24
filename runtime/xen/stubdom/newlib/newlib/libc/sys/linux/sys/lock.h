#ifndef __SYS_LOCK_H__
#define __SYS_LOCK_H__

#include <features.h>

#define  _LIBC  1
#define  NOT_IN_libc 1

#ifndef __USE_GNU
#define __USE_GNU 1
#endif

#include <bits/libc-lock.h>

typedef __libc_lock_t _LOCK_T;
typedef __libc_lock_recursive_t _LOCK_RECURSIVE_T;

#define __LOCK_INIT(class,lock) \
  __libc_lock_define_initialized(class, lock)
#define __LOCK_INIT_RECURSIVE(class, lock) \
  __libc_lock_define_initialized_recursive(class, lock)

#define __lock_init(__lock) __libc_lock_init(__lock)
#define __lock_init_recursive(__lock) __libc_lock_init_recursive(__lock)
#define __lock_acquire(__lock) __libc_lock_lock(__lock)
#define __lock_acquire_recursive(__lock) __libc_lock_lock_recursive(__lock)
#define __lock_release(__lock) __libc_lock_unlock(__lock)
#define __lock_release_recursive(__lock) __libc_lock_unlock_recursive(__lock)
#define __lock_try_acquire(__lock) __libc_lock_trylock(__lock)
#define __lock_try_acquire_recursive(__lock) \
	__libc_lock_trylock_recursive(__lock)
#define __lock_close(__lock) __libc_lock_fini(__lock)
#define __lock_close_recursive(__lock) __libc_lock_fini_recursive(__lock)

#endif /* __SYS_LOCK_H__ */
