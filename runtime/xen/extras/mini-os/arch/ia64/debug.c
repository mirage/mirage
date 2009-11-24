/* 
 ****************************************************************************
 * Done by Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com
 *
 * Description:	ia64 specific part of the mini-os
 * 		Prints debug information on a crash of mini-os
 *
 * Parts are taken from FreeBSD.
 *
 ****************************************************************************
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
 * DEALINGS IN THE SOFTWARE.
 */

#include <mini-os/os.h>

static const char *ia64_vector_names[] = {
	"VHPT Translation",			/* 0 */
	"Instruction TLB",			/* 1 */
	"Data TLB",				/* 2 */
	"Alternate Instruction TLB",		/* 3 */
	"Alternate Data TLB",			/* 4 */
	"Data Nested TLB",			/* 5 */
	"Instruction Key Miss",			/* 6 */
	"Data Key Miss",			/* 7 */
	"Dirty-Bit",				/* 8 */
	"Instruction Access-Bit",		/* 9 */
	"Data Access-Bit",			/* 10 */
	"Break Instruction",			/* 11 */
	"External Interrupt",			/* 12 */
	"Reserved 13",				/* 13 */
	"Reserved 14",				/* 14 */
	"Reserved 15",				/* 15 */
	"Reserved 16",				/* 16 */
	"Reserved 17",				/* 17 */
	"Reserved 18",				/* 18 */
	"Reserved 19",				/* 19 */
	"Page Not Present",			/* 20 */
	"Key Permission",			/* 21 */
	"Instruction Access Rights",		/* 22 */
	"Data Access Rights",			/* 23 */
	"General Exception",			/* 24 */
	"Disabled FP-Register",			/* 25 */
	"NaT Consumption",			/* 26 */
	"Speculation",				/* 27 */
	"Reserved 28",				/* 28 */
	"Debug",				/* 29 */
	"Unaligned Reference",			/* 30 */
	"Unsupported Data Reference",		/* 31 */
	"Floating-point Fault",			/* 32 */
	"Floating-point Trap",			/* 33 */
	"Lower-Privilege Transfer Trap",	/* 34 */
	"Taken Branch Trap",			/* 35 */
	"Single Step Trap",			/* 36 */
	"Reserved 37",				/* 37 */
	"Reserved 38",				/* 38 */
	"Reserved 39",				/* 39 */
	"Reserved 40",				/* 40 */
	"Reserved 41",				/* 41 */
	"Reserved 42",				/* 42 */
	"Reserved 43",				/* 43 */
	"Reserved 44",				/* 44 */
	"IA-32 Exception",			/* 45 */
	"IA-32 Intercept",			/* 46 */
	"IA-32 Interrupt",			/* 47 */
	"Reserved 48",				/* 48 */
	"Reserved 49",				/* 49 */
	"Reserved 50",				/* 50 */
	"Reserved 51",				/* 51 */
	"Reserved 52",				/* 52 */
	"Reserved 53",				/* 53 */
	"Reserved 54",				/* 54 */
	"Reserved 55",				/* 55 */
	"Reserved 56",				/* 56 */
	"Reserved 57",				/* 57 */
	"Reserved 58",				/* 58 */
	"Reserved 59",				/* 59 */
	"Reserved 60",				/* 60 */
	"Reserved 61",				/* 61 */
	"Reserved 62",				/* 62 */
	"Reserved 63",				/* 63 */
	"Reserved 64",				/* 64 */
	"Reserved 65",				/* 65 */
	"Reserved 66",				/* 66 */
	"Reserved 67",				/* 67 */
};

typedef struct
{
	uint64_t sof	:7;	/* 0-6 size of frame */
	uint64_t sol	:7;	/* 7-13 size of locals (in + loc) */
	uint64_t sor	:4;
	uint64_t rrb_gr	:7;
	uint64_t rrb_fr	:7;
	uint64_t rrb_pr	:6;
	uint64_t res	:25;	/* reserved */
	uint64_t v	:1;	/* The v bit */
} ifs_t;

void
do_trap_error(trap_frame_t* tf)
{
	ifs_t curIfs;

	printk("TRAP in mini-os:\n");
	printk("  trap: %d (%s)\n", tf->trap_num,
	       ia64_vector_names[tf->trap_num]);
	printk("  iip : 0x%.16lx  ifa: 0x%.16lx\n", tf->iip, tf->ifa);
	printk("  ipsr: 0x%.16lx  ifs: 0x%.16lx\n", tf->ipsr, tf->ifs);
	printk("  isr : 0x%.16lx\n", tf->isr);
	printk("  gp  : 0x%.16lx  sp : 0x%.16lx\n", tf->gp, tf->sp);
	printk("  rp  : 0x%.16lx  tp : 0x%.16lx\n", tf->b0, tf->tp);
	printk("  b6  : 0x%.16lx  b7 : 0x%.16lx\n", tf->b6, tf->b7);
	printk("  r8  : 0x%.16lx\n", tf->r8);
	printk("  bsp : 0x%.16lx  rsc: 0x%.16lx\n", tf->bsp, tf->rsc);
	printk("  r14 : 0x%.16lx  r15: 0x%.16lx\n", tf->r14, tf->r15);
	printk("  r16 : 0x%.16lx  r17: 0x%.16lx\n", tf->r16, tf->r17);
	printk("  r18 : 0x%.16lx  r19: 0x%.16lx\n", tf->r18, tf->r19);
	printk("  r20 : 0x%.16lx  r21: 0x%.16lx\n", tf->r20, tf->r21);
	printk("  r22 : 0x%.16lx  r23: 0x%.16lx\n", tf->r22, tf->r23);
	printk("  r24 : 0x%.16lx  r25: 0x%.16lx\n", tf->r24, tf->r25);
	printk("  r26 : 0x%.16lx  r27: 0x%.16lx\n", tf->r26, tf->r27);
	printk("  r28 : 0x%.16lx  r29: 0x%.16lx\n", tf->r28, tf->r29);
	printk("  r30 : 0x%.16lx  r31: 0x%.16lx\n", tf->r30, tf->r31);

	__asm __volatile("flushrs;;");
	curIfs = *((ifs_t*)((void*)(&tf->ifs)));
	if (!curIfs.v)
		printk(" ifs.v = 0");
	else {
		uint64_t* regP;
		uint32_t  i;

		printk("  cfm.sof: %d  cfm.sol: %d\n", curIfs.sof, curIfs.sol);
		regP = (uint64_t *)(tf->bsp + tf->ndirty);
		for (i = curIfs.sof; i != 0; ) {
			if (i <= (((uint64_t)regP & 0x000001f8) >> 3)) {
				regP -= i;
				i = 0;
				break;
			}
			i -= ((uint64_t)regP & 0x000001f8) >> 3;
			regP = (uint64_t *)((uint64_t)regP & ~0x000001ff) - 1;
		}
		for (i = 0; i < curIfs.sof; i++) {
			if (((uint64_t)regP & 0x000001f8) == 0x000001f8)
				regP++;
			printk("  r%d: 0x%lx\n",  i+32, *regP);
			regP++;
		}
	}
	HYPERVISOR_shutdown(SHUTDOWN_poweroff);
}
