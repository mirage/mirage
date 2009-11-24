#ifndef __X86_SETUP_H_
#define __X86_SETUP_H_

extern int early_boot;
extern unsigned long xenheap_initial_phys_start;

void init_done(void);

void early_cpu_init(void);
void early_time_init(void);
void early_page_fault(void);

int intel_cpu_init(void);
int amd_init_cpu(void);
int cyrix_init_cpu(void);
int nsc_init_cpu(void);
int centaur_init_cpu(void);
int transmeta_init_cpu(void);

void numa_initmem_init(unsigned long start_pfn, unsigned long end_pfn);
void arch_init_memory(void);
void subarch_init_memory(void);

void init_IRQ(void);
void init_tmem(void);
void vesa_init(void);
void vesa_mtrr_init(void);

#endif
