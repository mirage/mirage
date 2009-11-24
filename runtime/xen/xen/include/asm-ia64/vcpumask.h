#ifndef __XEN_VCPUMASK_H
#define __XEN_VCPUMASK_H

/* vcpu mask
   stolen from cpumask.h */
typedef struct { DECLARE_BITMAP(bits, MAX_VIRT_CPUS); } vcpumask_t;

#define vcpu_set(vcpu, dst) __vcpu_set((vcpu), &(dst))
static inline void __vcpu_set(int vcpu, volatile vcpumask_t *dstp)
{
    set_bit(vcpu, dstp->bits);
}
#define vcpus_clear(dst) __vcpus_clear(&(dst), MAX_VIRT_CPUS)
static inline void __vcpus_clear(vcpumask_t *dstp, int nbits)
{
    bitmap_zero(dstp->bits, nbits);
}
/* No static inline type checking - see Subtlety (1) above. */
#define vcpu_isset(vcpu, vcpumask) test_bit((vcpu), (vcpumask).bits)

#define first_vcpu(src) __first_vcpu(&(src), MAX_VIRT_CPUS)
static inline int __first_vcpu(const vcpumask_t *srcp, int nbits)
{
    return min_t(int, nbits, find_first_bit(srcp->bits, nbits));
}

#define next_vcpu(n, src) __next_vcpu((n), &(src), MAX_VIRT_CPUS)
static inline int __next_vcpu(int n, const vcpumask_t *srcp, int nbits)
{
    return min_t(int, nbits, find_next_bit(srcp->bits, nbits, n+1));
}

#if MAX_VIRT_CPUS > 1
#define for_each_vcpu_mask(d, vcpu, mask)       \
    for ((vcpu) = first_vcpu(mask);             \
         (vcpu) < d->max_vcpus;                 \
         (vcpu) = next_vcpu((vcpu), (mask)))
#else /* NR_CPUS == 1 */
#define for_each_vcpu_mask(d, vcpu, mask) for ((vcpu) = 0; (vcpu) < 1; (vcpu)++)
#endif /* NR_CPUS */

#define vcpumask_scnprintf(buf, len, src) \
        __vcpumask_scnprintf((buf), (len), &(src), MAX_VIRT_CPUS)
static inline int __vcpumask_scnprintf(char *buf, int len,
                                       const vcpumask_t *srcp, int nbits)
{
    return bitmap_scnprintf(buf, len, srcp->bits, nbits);
}

#endif /* __XEN_VCPUMASK_H */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */
