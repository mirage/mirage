#ifndef __X86_PERCPU_H__
#define __X86_PERCPU_H__

#define PERCPU_SHIFT 13
#define PERCPU_SIZE  (1UL << PERCPU_SHIFT)

/* Separate out the type, so (int[3], foo) works. */
#define __DEFINE_PER_CPU(type, name, suffix)                    \
    __attribute__((__section__(".data.percpu" #suffix)))        \
    __typeof__(type) per_cpu_##name

/* var is in discarded region: offset to particular copy we want */
#define per_cpu(var, cpu)  \
    (*RELOC_HIDE(&per_cpu__##var, ((unsigned int)(cpu))<<PERCPU_SHIFT))
#define __get_cpu_var(var) \
    (per_cpu(var, smp_processor_id()))

#define DECLARE_PER_CPU(type, name) extern __typeof__(type) per_cpu__##name

#endif /* __X86_PERCPU_H__ */
