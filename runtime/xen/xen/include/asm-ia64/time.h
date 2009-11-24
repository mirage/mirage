#ifndef _ASM_TIME_H_
#define _ASM_TIME_H_

#include <asm/linux/time.h>
#include <asm/timex.h>

struct tm;
struct tm wallclock_time(void);

void get_wallclock(uint64_t *sec, uint64_t *nsec, uint64_t *now);

#endif /* _ASM_TIME_H_ */
