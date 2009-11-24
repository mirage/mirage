/******************************************************************************
 * compat.h
 */

#ifndef __XEN_COMPAT_H__
#define __XEN_COMPAT_H__

#include <xen/config.h>

#ifdef CONFIG_COMPAT

#include <xen/types.h>
#include <asm/compat.h>
#include <compat/xlat.h>

#define __DEFINE_COMPAT_HANDLE(name, type) \
    typedef struct { \
        compat_ptr_t c; \
        type *_[0] __attribute__((__packed__)); \
    } __compat_handle_ ## name

#define DEFINE_COMPAT_HANDLE(name) \
    __DEFINE_COMPAT_HANDLE(name, name); \
    __DEFINE_COMPAT_HANDLE(const_ ## name, const name)
#define COMPAT_HANDLE(name)          __compat_handle_ ## name

/* Is the compat handle a NULL reference? */
#define compat_handle_is_null(hnd)        ((hnd).c == 0)

/* Offset the given compat handle into the array it refers to. */
#define compat_handle_add_offset(hnd, nr)                            \
    ((hnd).c += (nr) * sizeof(**(hnd)._))

/* Cast a compat handle to the specified type of handle. */
#define compat_handle_cast(chnd, type) ({                            \
    type *_x = (__typeof__(**(chnd)._) *)(full_ptr_t)(chnd).c;       \
    (XEN_GUEST_HANDLE(type)) { _x };                                 \
})

#define guest_from_compat_handle(ghnd, chnd)                         \
    set_xen_guest_handle(ghnd,                                       \
                         (__typeof__(**(chnd)._) *)(full_ptr_t)(chnd).c)

/*
 * Copy an array of objects to guest context via a compat handle,
 * specifying an offset into the guest array.
 */
#define copy_to_compat_offset(hnd, off, ptr, nr) ({                  \
    const typeof(*(ptr)) *_s = (ptr);                                \
    char (*_d)[sizeof(*_s)] = (void *)(full_ptr_t)(hnd).c;           \
    ((void)((typeof(**(hnd)._) *)(full_ptr_t)(hnd).c == (ptr)));     \
    raw_copy_to_guest(_d + (off), _s, sizeof(*_s) * (nr));           \
})

/*
 * Copy an array of objects from guest context via a compat handle,
 * specifying an offset into the guest array.
 */
#define copy_from_compat_offset(ptr, hnd, off, nr) ({                \
    const typeof(*(ptr)) *_s = (typeof(**(hnd)._) *)(full_ptr_t)(hnd).c; \
    typeof(*(ptr)) *_d = (ptr);                                      \
    raw_copy_from_guest(_d, _s + (off), sizeof(*_d) * (nr));         \
})

#define copy_to_compat(hnd, ptr, nr)                                 \
    copy_to_compat_offset(hnd, 0, ptr, nr)

#define copy_from_compat(ptr, hnd, nr)                               \
    copy_from_compat_offset(ptr, hnd, 0, nr)

/* Copy sub-field of a structure to guest context via a compat handle. */
#define copy_field_to_compat(hnd, ptr, field) ({                     \
    const typeof(&(ptr)->field) _s = &(ptr)->field;                  \
    void *_d = &((typeof(**(hnd)._) *)(full_ptr_t)(hnd).c)->field;   \
    ((void)(&((typeof(**(hnd)._) *)(full_ptr_t)(hnd).c)->field ==    \
            &(ptr)->field));                                         \
    raw_copy_to_guest(_d, _s, sizeof(*_s));                          \
})

/* Copy sub-field of a structure from guest context via a compat handle. */
#define copy_field_from_compat(ptr, hnd, field) ({                   \
    const typeof(&(ptr)->field) _s =                                 \
        &((typeof(**(hnd)._) *)(full_ptr_t)(hnd).c)->field;          \
    typeof(&(ptr)->field) _d = &(ptr)->field;                        \
    raw_copy_from_guest(_d, _s, sizeof(*_d));                        \
})

/*
 * Pre-validate a guest handle.
 * Allows use of faster __copy_* functions.
 */
#define compat_handle_okay(hnd, nr)                                  \
    compat_array_access_ok((void *)(full_ptr_t)(hnd).c, (nr),        \
                           sizeof(**(hnd)._))

#define __copy_to_compat_offset(hnd, off, ptr, nr) ({                \
    const typeof(*(ptr)) *_s = (ptr);                                \
    char (*_d)[sizeof(*_s)] = (void *)(full_ptr_t)(hnd).c;           \
    ((void)((typeof(**(hnd)._) *)(full_ptr_t)(hnd).c == (ptr)));     \
    __raw_copy_to_guest(_d + (off), _s, sizeof(*_s) * (nr));         \
})

#define __copy_from_compat_offset(ptr, hnd, off, nr) ({              \
    const typeof(*(ptr)) *_s = (typeof(**(hnd)._) *)(full_ptr_t)(hnd).c; \
    typeof(*(ptr)) *_d = (ptr);                                      \
    __raw_copy_from_guest(_d, _s + (off), sizeof(*_d) * (nr));       \
})

#define __copy_to_compat(hnd, ptr, nr)                               \
    __copy_to_compat_offset(hnd, 0, ptr, nr)

#define __copy_from_compat(ptr, hnd, nr)                             \
    __copy_from_compat_offset(ptr, hnd, 0, nr)

#define __copy_field_to_compat(hnd, ptr, field) ({                   \
    const typeof(&(ptr)->field) _s = &(ptr)->field;                  \
    void *_d = &((typeof(**(hnd)._) *)(full_ptr_t)(hnd).c)->field;   \
    ((void)(&((typeof(**(hnd)._) *)(full_ptr_t)(hnd).c)->field ==    \
            &(ptr)->field));                                         \
    __raw_copy_to_guest(_d, _s, sizeof(*_s));                        \
})

#define __copy_field_from_compat(ptr, hnd, field) ({                 \
    const typeof(&(ptr)->field) _s =                                 \
        &((typeof(**(hnd)._) *)(full_ptr_t)(hnd).c)->field;          \
    typeof(&(ptr)->field) _d = &(ptr)->field;                        \
    __raw_copy_from_guest(_d, _s, sizeof(*_d));                      \
})


#define CHECK_TYPE(name) \
    typedef int __checkT ## name[1 - ((xen_ ## name ## _t *)0 != \
                                   (compat_ ## name ## _t *)0) * 2]
#define CHECK_TYPE_(k, n) \
    typedef int __checkT ## k ## _ ## n[1 - ((k xen_ ## n *)0 != \
                                          (k compat_ ## n *)0) * 2]

#define CHECK_SIZE(name) \
    typedef int __checkS ## name[1 - (sizeof(xen_ ## name ## _t) != \
                                   sizeof(compat_ ## name ## _t)) * 2]
#define CHECK_SIZE_(k, n) \
    typedef int __checkS ## k ## _ ## n[1 - (sizeof(k xen_ ## n) != \
                                          sizeof(k compat_ ## n)) * 2]

#define CHECK_FIELD(t, f) \
    typedef int __checkF ## t ## __ ## f[1 - (&((xen_ ## t ## _t *)0)->f != \
                                           &((compat_ ## t ## _t *)0)->f) * 2]
#define CHECK_FIELD_(k, n, f) \
    typedef int __checkF ## k ## _ ## n ## __ ## f[1 - (&((k xen_ ## n *)0)->f != \
                                                     &((k compat_ ## n *)0)->f) * 2]

#define CHECK_SUBFIELD_1(t, f1, f2) \
    typedef int __checkF1 ## t ## __ ## f1 ## __ ## f2 \
                [1 - (&((xen_ ## t ## _t *)0)->f1.f2 != \
                   &((compat_ ## t ## _t *)0)->f1.f2) * 2]
#define CHECK_SUBFIELD_1_(k, n, f1, f2) \
    typedef int __checkF1 ## k ## _ ## n ## __ ## f1 ## __ ## f2 \
                [1 - (&((k xen_ ## n *)0)->f1.f2 != \
                   &((k compat_ ## n *)0)->f1.f2) * 2]

#define CHECK_SUBFIELD_2(t, f1, f2, f3) \
    typedef int __checkF2 ## t ## __ ## f1 ## __ ## f2 ## __ ## f3 \
                [1 - (&((xen_ ## t ## _t *)0)->f1.f2.f3 != \
                   &((compat_ ## t ## _t *)0)->f1.f2.f3) * 2]
#define CHECK_SUBFIELD_2_(k, n, f1, f2, f3) \
    typedef int __checkF2 ## k ## _ ## n ## __ ## f1 ## __ ## f2 ## __ ## f3 \
                [1 - (&((k xen_ ## n *)0)->f1.f2.f3 != \
                   &((k compat_ ## n *)0)->f1.f2.f3) * 2]

int hypercall_xlat_continuation(unsigned int *id, unsigned int mask, ...);

/* In-place translation functons: */
struct start_info;
void xlat_start_info(struct start_info *, enum XLAT_start_info_console);
struct vcpu_runstate_info;
void xlat_vcpu_runstate_info(struct vcpu_runstate_info *);

int switch_compat(struct domain *);
int switch_native(struct domain *);

#else

#define compat_handle_is_null(hnd) 0

#endif

#endif /* __XEN_COMPAT_H__ */
