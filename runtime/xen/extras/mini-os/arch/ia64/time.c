/* 
 * Done by Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com>
 * Description: simple ia64 specific time handling
 * Parts are taken from FreeBSD.
 *
 ****************************************************************************
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <mini-os/os.h>
#include <mini-os/console.h>
#include <mini-os/time.h>
#include <mini-os/efi.h>
#include <mini-os/events.h>

struct timespec os_time;
static uint64_t itc_alt;		/* itc on last update. */
static uint64_t itc_at_boot;		/* itc on boot */
static uint64_t itc_frequency;
static uint64_t processor_frequency;
static uint64_t itm_val;

static int is_leap_year(int year)
{
	if( year % 4 == 0 )
	{
		if( year % 100 == 0 )
		{
			if( year % 400 == 0 ) return 1;
			else return 0;
		}
		return 1;
	}
	return 0;
}

static int count_leap_years(int epoch, int year)
{
	int i, result = 0;
	for( i = epoch ; i < year ; i++ ) if( is_leap_year(i) ) result++;
	return result;
}

static int get_day(int year, int mon, int day) {
	int result;
	switch(mon)
	{
		case 0: result = 0; break;
		case 1: result = 31; break; /* 1: 31 */
		case 2: result = 59; break; /* 2: 31+28 */
		case 3: result = 90; break; /* 3: 59+31 */
		case 4: result = 120;break; /* 4: 90+30 */
		case 5: result = 151;break; /* 5: 120+31 */
		case 6: result = 181;break; /* 6: 151+30 */
		case 7: result = 212;break; /* 7: 181+31 */
		case 8: result = 243;break; /* 8: 212+31 */
		case 9: result = 273;break; /* 9: 243+30 */
		case 10:result = 304;break; /* 10:273+31 */
		case 11:result = 334;break; /* 11:304+30 */
		default: break;
	}
	if( is_leap_year(year) && mon > 2 ) result++;
	result += day - 1;
	return result;
}

/*
 * Converts Gregorian date to seconds since 1970-01-01 00:00:00.
 * Assumes input in normal date format, i.e. 1980-12-31 23:59:59
 * => year=1980, mon=12, day=31, hour=23, min=59, sec=59.
 *
 * WARNING: this function will overflow on 2106-02-07 06:28:16 on
 * machines were long is 32-bit! (However, as time_t is signed, we
 * will already get problems at other places on 2038-01-19 03:14:08)
 */
static unsigned long _mktime(const unsigned int year, const unsigned int mon,
			    const unsigned int day, const unsigned int hour,
		            const unsigned int min, const unsigned int sec)
{
	unsigned long result = 0;

	result = sec;
	result += min * 60;
	result += hour * 3600;
	result += get_day(year, mon - 1, day) * 86400;
	result += (year - 1970) * 31536000;
	result += count_leap_years(1970, year) * 86400;

	return result;
}

static inline uint64_t
ns_from_cycles(uint64_t cycles)
{
	return (cycles * (1000000000 / itc_frequency));
}

static inline uint64_t
ns_to_cycles(uint64_t ns)
{
	return (ns * (itc_frequency / 1000000000));
}

/*
 * Block the domain until until(nanoseconds) is over.
 * If block is called no timerinterrupts are delivered from xen!
 */
void
block_domain(s_time_t until)
{
	struct ia64_pal_result pal_res;
	uint64_t c, new;

	c = ns_to_cycles(until);
	new = ia64_get_itc() + c - NOW();
	ia64_set_itm(new);		/* Reload cr.itm */
	/*
	 * PAL_HALT_LIGHT returns on every external interrupt,
	 * including timer interrupts.
	 */
	pal_res = ia64_call_pal_static(PAL_HALT_LIGHT, 0, 0, 0);
	if (pal_res.pal_status != 0)
		printk("%s: PAL_HALT_LIGHT returns an error\n");
	/* Reload the normal timer interrupt match. */
	new = ia64_get_itc() + itm_val;
	ia64_set_itm(new);
}

static void
calculate_time(void)
{
	uint64_t itc_new, new;

	itc_new = ia64_get_itc();
	if (itc_new < itc_alt)
		new = ~0 - itc_alt + itc_new;
	else
		new = itc_new - itc_alt;
	itc_alt = itc_new;
	new = ns_from_cycles(new);
	os_time.tv_nsec += new;
	if (os_time.tv_nsec > 1000000000) {	/* On overflow. */
		os_time.tv_sec++;
		os_time.tv_nsec -= 1000000000;
	}
}

void
timer_interrupt(evtchn_port_t port, struct pt_regs* regsP, void *data)
{
	uint64_t new;

	calculate_time();
	new = ia64_get_itc() + itm_val;
	ia64_set_itm(new);
}

/*
 * monotonic_clock(): returns # of nanoseconds passed since time_init()
 */
uint64_t
monotonic_clock(void)
{
	uint64_t delta;

	delta = ia64_get_itc() - itc_at_boot;
	delta = ns_from_cycles(delta);
	return delta;
}

int
gettimeofday(struct timeval *tv, void *tz)
{
	calculate_time();
	tv->tv_sec = os_time.tv_sec;			/* seconds */
	tv->tv_usec = NSEC_TO_USEC(os_time.tv_nsec);	/* microseconds */
        return 0;
};

/*
 * Read the clock frequencies from pal and sal for calculating
 * the clock interrupt.
 */
static void
calculate_frequencies(void)
{
	struct ia64_sal_result sal_res;
	struct ia64_pal_result pal_res;

	pal_res = ia64_call_pal_static(PAL_FREQ_RATIOS, 0, 0, 0);
	sal_res = ia64_sal_entry(SAL_FREQ_BASE, 0, 0, 0, 0, 0, 0, 0);

	if (sal_res.sal_status == 0 && pal_res.pal_status == 0) {
		processor_frequency =
			sal_res.sal_result[0] * (pal_res.pal_result[0] >> 32)
				/ (pal_res.pal_result[0] & ((1L << 32) - 1));
		itc_frequency =
			sal_res.sal_result[0] * (pal_res.pal_result[2] >> 32)
				/ (pal_res.pal_result[2] & ((1L << 32) - 1));
		PRINT_BV("Reading clock frequencies:\n");
		PRINT_BV("  Platform clock frequency %ld Hz\n",
			       sal_res.sal_result[0]);
		PRINT_BV("  Processor ratio %ld/%ld, Bus ratio %ld/%ld, "
			       "  ITC ratio %ld/%ld\n",
			       pal_res.pal_result[0] >> 32,
			       pal_res.pal_result[0] & ((1L << 32) - 1),
			       pal_res.pal_result[1] >> 32,
			       pal_res.pal_result[1] & ((1L << 32) - 1),
			       pal_res.pal_result[2] >> 32,
			       pal_res.pal_result[2] & ((1L << 32) - 1));

		printk("  ITC frequency %ld\n", itc_frequency);
	} else {
		itc_frequency = 1000000000;
		processor_frequency = 0;
		printk("Reading clock frequencies failed!!! Using: %ld\n",
		       itc_frequency);
	}
}


//#define HZ 1
#define HZ 1000		// 1000 clock ticks per sec
#define IA64_TIMER_VECTOR 0xef

void
init_time(void)
{
	uint64_t new;
	efi_time_t tm;
	evtchn_port_t port = 0;

	printk("Initialising time\n");
	calculate_frequencies();

	itm_val = (itc_frequency + HZ/2) / HZ;
	printk("  itm_val: %ld\n", itm_val);

	os_time.tv_sec = 0;
	os_time.tv_nsec = 0;

	if (efi_get_time(&tm)) {
		printk("  EFI-Time: %d.%d.%d   %d:%d:%d\n", tm.Day,
		       tm.Month, tm.Year, tm.Hour, tm.Minute, tm.Second);
		os_time.tv_sec = _mktime(tm.Year, tm.Month,
					tm.Day, tm.Hour, tm.Minute, tm.Second);
		os_time.tv_nsec = tm.Nanosecond;
	} else
		printk("efi_get_time() failed\n");

	port = bind_virq(VIRQ_ITC, timer_interrupt, NULL);
	if (port == -1) {
		printk("XEN timer request chn bind failed %i\n", port);
		return;
	}
        unmask_evtchn(port);
	itc_alt = ia64_get_itc();
	itc_at_boot = itc_alt;
	new = ia64_get_itc() + itm_val;
	ia64_set_itv(IA64_TIMER_VECTOR);
	ia64_set_itm(new);
	ia64_srlz_d();
}

void
fini_time(void)
{
	/* TODO */
}
