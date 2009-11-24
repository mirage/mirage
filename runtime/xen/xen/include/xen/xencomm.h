/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * Copyright (C) IBM Corp. 2006
 *
 * Authors: Hollis Blanchard <hollisb@us.ibm.com>
 */

#ifndef __XENCOMM_H__
#define __XENCOMM_H__

#include <public/xen.h>

unsigned long xencomm_copy_to_guest(
    void *to, const void *from, unsigned int len, unsigned int skip); 
unsigned long xencomm_copy_from_guest(
    void *to, const void *from, unsigned int len, unsigned int skip); 
int xencomm_add_offset(void **handle, unsigned int bytes);
int xencomm_handle_is_null(void *ptr);

static inline int xencomm_is_inline(const void *handle)
{
    unsigned long addr = (unsigned long)handle;
    return (addr & XENCOMM_INLINE_FLAG) == XENCOMM_INLINE_FLAG;
}

static inline unsigned long xencomm_inline_addr(const void *handle)
{
    return (unsigned long)handle & ~XENCOMM_INLINE_FLAG;
}

/* Is the guest handle a NULL reference? */
#define guest_handle_is_null(hnd) \
    ((hnd).p == NULL || xencomm_handle_is_null((hnd).p))

/* Offset the given guest handle into the array it refers to. */
#define guest_handle_add_offset(hnd, nr) ({                             \
    const typeof((hnd).p) _ptr;                                         \
    xencomm_add_offset((void **)&((hnd).p), nr * sizeof(*_ptr));        \
})

/* Cast a guest handle to the specified type of handle. */
#define guest_handle_cast(hnd, type) ({         \
    type *_x = (hnd).p;                         \
    XEN_GUEST_HANDLE(type) _y;                  \
    set_xen_guest_handle(_y, _x);               \
    _y;                                         \
})

/* Since we run in real mode, we can safely access all addresses. That also
 * means our __routines are identical to our "normal" routines. */
#define guest_handle_okay(hnd, nr) 1
#define guest_handle_subrange_okay(hnd, first, last) 1

/*
 * Copy an array of objects to guest context via a guest handle.
 * Optionally specify an offset into the guest array.
 */
#define copy_to_guest_offset(hnd, idx, ptr, nr) \
    __copy_to_guest_offset(hnd, idx, ptr, nr)

/* Copy sub-field of a structure to guest context via a guest handle. */
#define copy_field_to_guest(hnd, ptr, field) \
    __copy_field_to_guest(hnd, ptr, field)

/*
 * Copy an array of objects from guest context via a guest handle.
 * Optionally specify an offset into the guest array.
 */
#define copy_from_guest_offset(ptr, hnd, idx, nr) \
    __copy_from_guest_offset(ptr, hnd, idx, nr)

/* Copy sub-field of a structure from guest context via a guest handle. */
#define copy_field_from_guest(ptr, hnd, field) \
    __copy_field_from_guest(ptr, hnd, field)

#define __copy_to_guest_offset(hnd, idx, ptr, nr) ({                \
    const typeof(*(ptr)) *_s = (ptr);                               \
    void *_d = (hnd).p;                                             \
    ((void)((hnd).p == (ptr)));                                     \
    xencomm_copy_to_guest(_d, _s, sizeof(*_s)*(nr), sizeof(*_s)*(idx)); \
})

#define __copy_field_to_guest(hnd, ptr, field) ({                   \
    unsigned int _off = offsetof(typeof(*(hnd).p), field);          \
    const typeof(&(ptr)->field) _s = &(ptr)->field;                 \
    void *_d = (hnd).p;                                             \
    ((void)(&(hnd).p->field == &(ptr)->field));                     \
    xencomm_copy_to_guest(_d, _s, sizeof(*_s), _off);               \
})

#define __copy_from_guest_offset(ptr, hnd, idx, nr) ({              \
    const typeof(*(ptr)) *_s = (hnd).p;                             \
    typeof(*(ptr)) *_d = (ptr);                                     \
    xencomm_copy_from_guest(_d, _s, sizeof(*_d)*(nr), sizeof(*_d)*(idx)); \
})

#define __copy_field_from_guest(ptr, hnd, field) ({                 \
    unsigned int _off = offsetof(typeof(*(hnd).p), field);          \
    const void *_s = (hnd).p;                                       \
    typeof(&(ptr)->field) _d = &(ptr)->field;                       \
    ((void)(&(hnd).p->field == &(ptr)->field));                     \
    xencomm_copy_from_guest(_d, _s, sizeof(*_d), _off);             \
})

#ifdef CONFIG_XENCOMM_MARK_DIRTY
extern void xencomm_mark_dirty(unsigned long addr, unsigned int len);
#else
static inline void xencomm_mark_dirty(unsigned long addr, unsigned int len)
{
}
#endif

#endif /* __XENCOMM_H__ */
