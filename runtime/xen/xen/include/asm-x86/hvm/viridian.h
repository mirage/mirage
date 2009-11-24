/*****************************************************************************
 *
 * include/xen/viridian.h
 *
 * Copyright (c) 2008 Citrix Corp.
 *
 */

#ifndef __ASM_X86_HVM_VIRIDIAN_H__
#define __ASM_X86_HVM_VIRIDIAN_H__

union viridian_guest_os_id
{
    uint64_t raw;
    struct
    {
        uint64_t build_number:16;
        uint64_t service_pack:8;
        uint64_t minor:8;
        uint64_t major:8;
        uint64_t os:8;
        uint64_t vendor:16;
    } fields;
};

union viridian_hypercall_gpa
{   uint64_t raw;
    struct
    {
        uint64_t enabled:1;
        uint64_t reserved_preserved:11;
        uint64_t pfn:48;
    } fields;
};

struct viridian_domain
{
    union viridian_guest_os_id guest_os_id;
    union viridian_hypercall_gpa hypercall_gpa;
};

int
cpuid_viridian_leaves(
    unsigned int leaf,
    unsigned int *eax,
    unsigned int *ebx,
    unsigned int *ecx,
    unsigned int *edx);

int
wrmsr_viridian_regs(
    uint32_t idx,
    uint64_t val);

int
rdmsr_viridian_regs(
    uint32_t idx,
    uint64_t *val);

int
viridian_hypercall(struct cpu_user_regs *regs);

#endif /* __ASM_X86_HVM_VIRIDIAN_H__ */
