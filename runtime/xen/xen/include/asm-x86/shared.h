#ifndef __XEN_X86_SHARED_H__
#define __XEN_X86_SHARED_H__

#ifdef CONFIG_COMPAT

#define nmi_reason(d) (!has_32bit_shinfo(d) ?                             \
                       (u32 *)&(d)->shared_info->native.arch.nmi_reason : \
                       (u32 *)&(d)->shared_info->compat.arch.nmi_reason)

#define GET_SET_SHARED(type, field)                             \
static inline type arch_get_##field(const struct domain *d)     \
{                                                               \
    return !has_32bit_shinfo(d) ?                               \
           d->shared_info->native.arch.field :                  \
           d->shared_info->compat.arch.field;                   \
}                                                               \
static inline void arch_set_##field(struct domain *d,           \
                                    type val)                   \
{                                                               \
    if ( !has_32bit_shinfo(d) )                                 \
        d->shared_info->native.arch.field = val;                \
    else                                                        \
        d->shared_info->compat.arch.field = val;                \
}

#define GET_SET_VCPU(type, field)                               \
static inline type arch_get_##field(const struct vcpu *v)       \
{                                                               \
    return !has_32bit_shinfo(v->domain) ?                       \
           v->vcpu_info->native.arch.field :                    \
           v->vcpu_info->compat.arch.field;                     \
}                                                               \
static inline void arch_set_##field(struct vcpu *v,             \
                                    type val)                   \
{                                                               \
    if ( !has_32bit_shinfo(v->domain) )                         \
        v->vcpu_info->native.arch.field = val;                  \
    else                                                        \
        v->vcpu_info->compat.arch.field = val;                  \
}

#else

#define nmi_reason(d) ((u32 *)&(d)->shared_info->arch.nmi_reason)

#define GET_SET_SHARED(type, field)                             \
static inline type arch_get_##field(const struct domain *d)     \
{                                                               \
    return d->shared_info->arch.field;                          \
}                                                               \
static inline void arch_set_##field(struct domain *d,           \
                                    type val)                   \
{                                                               \
    d->shared_info->arch.field = val;                           \
}

#define GET_SET_VCPU(type, field)                               \
static inline type arch_get_##field(const struct vcpu *v)       \
{                                                               \
    return v->vcpu_info->arch.field;                            \
}                                                               \
static inline void arch_set_##field(struct vcpu *v,             \
                                    type val)                   \
{                                                               \
    v->vcpu_info->arch.field = val;                             \
}
#endif

GET_SET_SHARED(unsigned long, max_pfn)
GET_SET_SHARED(xen_pfn_t, pfn_to_mfn_frame_list_list)
GET_SET_SHARED(unsigned long, nmi_reason)

GET_SET_VCPU(unsigned long, cr2)

#undef GET_SET_VCPU
#undef GET_SET_SHARED

#endif /* __XEN_X86_SHARED_H__ */
