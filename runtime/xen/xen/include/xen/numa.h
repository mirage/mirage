#ifndef _XEN_NUMA_H
#define _XEN_NUMA_H

#include <xen/config.h>
#include <asm/numa.h>

#ifndef NODES_SHIFT
#define NODES_SHIFT     0
#endif

#define NUMA_NO_NODE    0xFF

#define MAX_NUMNODES    (1 << NODES_SHIFT)

#define vcpu_to_node(v) (cpu_to_node((v)->processor))

#define domain_to_node(d) \
  (((d)->vcpu != NULL && (d)->vcpu[0] != NULL) \
   ? vcpu_to_node((d)->vcpu[0]) : NUMA_NO_NODE)

#endif /* _XEN_NUMA_H */
