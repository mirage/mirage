/******************************************************************************
 * guest_access.h
 * 
 * Copyright (c) 2006, K A Fraser
 */

#ifndef __ASM_X86_GUEST_ACCESS_H__
#define __ASM_X86_GUEST_ACCESS_H__

#include <asm/uaccess.h>
#include <asm/paging.h>
#include <asm/hvm/support.h>
#include <asm/hvm/guest_access.h>

/* Raw access functions: no type checking. */
#define raw_copy_to_guest(dst, src, len)        \
    (is_hvm_vcpu(current) ?                     \
     copy_to_user_hvm((dst), (src), (len)) :    \
     copy_to_user((dst), (src), (len)))
#define raw_copy_from_guest(dst, src, len)      \
    (is_hvm_vcpu(current) ?                     \
     copy_from_user_hvm((dst), (src), (len)) :  \
     copy_from_user((dst), (src), (len)))
#define __raw_copy_to_guest(dst, src, len)      \
    (is_hvm_vcpu(current) ?                     \
     copy_to_user_hvm((dst), (src), (len)) :    \
     __copy_to_user((dst), (src), (len)))
#define __raw_copy_from_guest(dst, src, len)    \
    (is_hvm_vcpu(current) ?                     \
     copy_from_user_hvm((dst), (src), (len)) :  \
     __copy_from_user((dst), (src), (len)))

/* Is the guest handle a NULL reference? */
#define guest_handle_is_null(hnd)        ((hnd).p == NULL)

/* Offset the given guest handle into the array it refers to. */
#define guest_handle_add_offset(hnd, nr) ((hnd).p += (nr))
#define guest_handle_subtract_offset(hnd, nr) ((hnd).p -= (nr))

/* Cast a guest handle to the specified type of handle. */
#define guest_handle_cast(hnd, type) ({         \
    type *_x = (hnd).p;                         \
    (XEN_GUEST_HANDLE(type)) { _x };            \
})

#define guest_handle_from_ptr(ptr, type)        \
    ((XEN_GUEST_HANDLE(type)) { (type *)ptr })
#define const_guest_handle_from_ptr(ptr, type)  \
    ((XEN_GUEST_HANDLE(const_##type)) { (const type *)ptr })

/*
 * Copy an array of objects to guest context via a guest handle,
 * specifying an offset into the guest array.
 */
#define copy_to_guest_offset(hnd, off, ptr, nr) ({      \
    const typeof(*(ptr)) *_s = (ptr);                   \
    char (*_d)[sizeof(*_s)] = (void *)(hnd).p;          \
    ((void)((hnd).p == (ptr)));                         \
    raw_copy_to_guest(_d+(off), _s, sizeof(*_s)*(nr));  \
})

/*
 * Copy an array of objects from guest context via a guest handle,
 * specifying an offset into the guest array.
 */
#define copy_from_guest_offset(ptr, hnd, off, nr) ({    \
    const typeof(*(ptr)) *_s = (hnd).p;                 \
    typeof(*(ptr)) *_d = (ptr);                         \
    raw_copy_from_guest(_d, _s+(off), sizeof(*_d)*(nr));\
})

/* Copy sub-field of a structure to guest context via a guest handle. */
#define copy_field_to_guest(hnd, ptr, field) ({         \
    const typeof(&(ptr)->field) _s = &(ptr)->field;     \
    void *_d = &(hnd).p->field;                         \
    ((void)(&(hnd).p->field == &(ptr)->field));         \
    raw_copy_to_guest(_d, _s, sizeof(*_s));             \
})

/* Copy sub-field of a structure from guest context via a guest handle. */
#define copy_field_from_guest(ptr, hnd, field) ({       \
    const typeof(&(ptr)->field) _s = &(hnd).p->field;   \
    typeof(&(ptr)->field) _d = &(ptr)->field;           \
    raw_copy_from_guest(_d, _s, sizeof(*_d));           \
})

/*
 * Pre-validate a guest handle.
 * Allows use of faster __copy_* functions.
 */
#define guest_handle_okay(hnd, nr)                      \
    (paging_mode_external(current->domain) ||           \
     array_access_ok((hnd).p, (nr), sizeof(*(hnd).p)))
#define guest_handle_subrange_okay(hnd, first, last)    \
    (paging_mode_external(current->domain) ||           \
     array_access_ok((hnd).p + (first),                 \
                     (last)-(first)+1,                  \
                     sizeof(*(hnd).p)))

#define __copy_to_guest_offset(hnd, off, ptr, nr) ({    \
    const typeof(*(ptr)) *_s = (ptr);                   \
    char (*_d)[sizeof(*_s)] = (void *)(hnd).p;          \
    ((void)((hnd).p == (ptr)));                         \
    __raw_copy_to_guest(_d+(off), _s, sizeof(*_s)*(nr));\
})

#define __copy_from_guest_offset(ptr, hnd, off, nr) ({  \
    const typeof(*(ptr)) *_s = (hnd).p;                 \
    typeof(*(ptr)) *_d = (ptr);                         \
    __raw_copy_from_guest(_d, _s+(off), sizeof(*_d)*(nr));\
})

#define __copy_field_to_guest(hnd, ptr, field) ({       \
    const typeof(&(ptr)->field) _s = &(ptr)->field;     \
    void *_d = &(hnd).p->field;                         \
    ((void)(&(hnd).p->field == &(ptr)->field));         \
    __raw_copy_to_guest(_d, _s, sizeof(*_s));           \
})

#define __copy_field_from_guest(ptr, hnd, field) ({     \
    const typeof(&(ptr)->field) _s = &(hnd).p->field;   \
    typeof(&(ptr)->field) _d = &(ptr)->field;           \
    __raw_copy_from_guest(_d, _s, sizeof(*_d));         \
})

#endif /* __ASM_X86_GUEST_ACCESS_H__ */
