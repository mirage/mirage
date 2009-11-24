#ifndef __FLUSHTLB_H__
#define __FLUSHTLB_H__

struct vcpu;
struct domain;

/* TLB flushes can be either local (current vcpu only) or domain wide (on
   all vcpus).
   TLB flushes can be either all-flush or range only.

   vTLB flushing means flushing VCPU virtual TLB + machine TLB + machine VHPT.
*/

/* Local all flush of vTLB.  */
void vcpu_flush_vtlb_all(struct vcpu *v);

/* Local range flush of machine TLB only (not full VCPU virtual TLB!!!)  */
void vcpu_flush_tlb_vhpt_range (u64 vadr, u64 log_range);

/* Global all flush of vTLB  */
void domain_flush_vtlb_all(struct domain *d);

/* Global range-flush of vTLB.  */
void domain_flush_vtlb_range (struct domain *d, u64 vadr, u64 addr_range);

#ifdef CONFIG_XEN_IA64_TLB_TRACK
struct tlb_track_entry;
void __domain_flush_vtlb_track_entry(struct domain* d,
                                     const struct tlb_track_entry* entry);
/* Global entry-flush of vTLB */
void domain_flush_vtlb_track_entry(struct domain* d,
                                   const struct tlb_track_entry* entry);
#endif

/* Flush vhpt and mTLB on every dirty cpus.  */
void domain_flush_tlb_vhpt(struct domain *d);

/* Flush vhpt and mTLB for log-dirty mode.  */
void flush_tlb_for_log_dirty(struct domain *d);

/* Flush v-tlb on cpus set in mask for current domain.  */
void flush_tlb_mask(const cpumask_t *mask);

/* Flush local machine TLB.  */
void local_flush_tlb_all (void);

#define tlbflush_filter(x,y) ((void)0)

#endif
