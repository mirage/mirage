#include <unistd.h>
#include <sys/gmon.h>

extern struct monparam mparam;

void __mcount (unsigned long, unsigned long) PROF_SECTION;

void
__mcount (unsigned long frompc, unsigned long selfpc)
{
	struct rawarc *arc = mparam.arcs, thisarc;
	unsigned long num;
	/* If arc already exists, increment count */
	for (num = 0; num < mparam.arcnum; num++)
		if (arc[num].raw_frompc == frompc && arc[num].raw_selfpc == selfpc) {
			arc[num].raw_count++;
			return;
		}
	if (selfpc < mparam.lowpc || selfpc > mparam.highpc) return;
	thisarc.raw_frompc = frompc;
	thisarc.raw_selfpc = selfpc;
	thisarc.raw_count  = 1;
	arc[mparam.arcnum++] = thisarc;
}
