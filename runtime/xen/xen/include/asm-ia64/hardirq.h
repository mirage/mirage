#ifndef __IA64__HARDIRQ__H__
#define __IA64__HARDIRQ__H__

#define __ARCH_IRQ_STAT	1
#define HARDIRQ_BITS	14
#include <linux/hardirq.h>
#include <xen/sched.h>

#define local_softirq_pending()		(local_cpu_data->softirq_pending)

#endif
