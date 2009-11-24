/*
 * This file is subject to the terms and conditions of the GNU General Public
 * License.  See the file "COPYING" in the main directory of this archive
 * for more details.
 *
 * This file contains NUMA specific prototypes and definitions.
 *
 * 2002/08/05 Erich Focht <efocht@ess.nec.de>
 *
 */
#ifndef _ASM_IA64_NUMA_H
#define _ASM_IA64_NUMA_H

#include <linux/config.h>

#ifdef CONFIG_NUMA

#include <linux/cache.h>
#include <linux/cpumask.h>
#include <linux/numa.h>
#ifndef XEN /* dependency loop when this is included */
#include <linux/smp.h>
#endif
#include <linux/threads.h>

#include <asm/mmzone.h>

extern int srat_rev;

extern u8 cpu_to_node_map[NR_CPUS] __cacheline_aligned;
#ifndef XEN
extern cpumask_t node_to_cpu_mask[MAX_NUMNODES] __cacheline_aligned;
#else
extern cpumask_t node_to_cpu_mask[] __cacheline_aligned;
#endif

/* Stuff below this line could be architecture independent */

extern int num_node_memblks;		/* total number of memory chunks */

/*
 * List of node memory chunks. Filled when parsing SRAT table to
 * obtain information about memory nodes.
*/

struct node_memblk_s {
	unsigned long start_paddr;
	unsigned long size;
	int nid;		/* which logical node contains this chunk? */
	int bank;		/* which mem bank on this node */
};

struct node_cpuid_s {
	u16	phys_id;	/* id << 8 | eid */
	int	nid;		/* logical node containing this CPU */
};

#ifndef XEN
extern struct node_memblk_s node_memblk[NR_NODE_MEMBLKS];
#else
extern struct node_memblk_s node_memblk[];
#endif
extern struct node_cpuid_s node_cpuid[NR_CPUS];

/*
 * ACPI 2.0 SLIT (System Locality Information Table)
 * http://devresource.hp.com/devresource/Docs/TechPapers/IA64/slit.pdf
 *
 * This is a matrix with "distances" between nodes, they should be
 * proportional to the memory access latency ratios.
 */

#ifndef XEN
extern u8 numa_slit[MAX_NUMNODES * MAX_NUMNODES];
#else
extern u8 numa_slit[];
#endif
#define node_distance(from,to) (numa_slit[(from) * num_online_nodes() + (to)])

extern int paddr_to_nid(unsigned long paddr);

#define local_nodeid (cpu_to_node_map[smp_processor_id()])

#else /* !CONFIG_NUMA */

#define paddr_to_nid(addr)	0

#endif /* CONFIG_NUMA */

#ifdef XEN
#define phys_to_nid(paddr) paddr_to_nid(paddr)
extern int pxm_to_node(int pxm);
extern int node_to_pxm(int node);
extern void __acpi_map_pxm_to_node(int, int);
extern int acpi_map_pxm_to_node(int);
#endif

#endif /* _ASM_IA64_NUMA_H */
