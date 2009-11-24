#ifndef __ASM_X86_HVM_GUEST_ACCESS_H__
#define __ASM_X86_HVM_GUEST_ACCESS_H__

#include <xen/percpu.h>
DECLARE_PER_CPU(bool_t, hvm_64bit_hcall);

unsigned long copy_to_user_hvm(void *to, const void *from, unsigned len);
unsigned long copy_from_user_hvm(void *to, const void *from, unsigned len);

#endif /* __ASM_X86_HVM_GUEST_ACCESS_H__ */
