#ifndef __X86_HPET_H__
#define __X86_HPET_H__

/*
 * Documentation on HPET can be found at:
 *      http://www.intel.com/ial/home/sp/pcmmspec.htm
 *      ftp://download.intel.com/ial/home/sp/mmts098.pdf
 */

#define HPET_MMAP_SIZE	1024

#define HPET_ID		0x000
#define HPET_PERIOD	0x004
#define HPET_CFG	0x010
#define HPET_STATUS	0x020
#define HPET_COUNTER	0x0f0
#define HPET_T0_CFG	0x100
#define HPET_T0_CMP	0x108
#define HPET_T0_ROUTE	0x110
#define HPET_T1_CFG	0x120
#define HPET_T1_CMP	0x128
#define HPET_T1_ROUTE	0x130
#define HPET_T2_CFG	0x140
#define HPET_T2_CMP	0x148
#define HPET_T2_ROUTE	0x150

#define HPET_Tn_CFG(n)      (HPET_T0_CFG + n * 0x20)
#define HPET_Tn_CMP(n)      (HPET_T0_CMP + n * 0x20)
#define HPET_Tn_ROUTE(n)    (HPET_T0_ROUTE + n * 0x20)

#define HPET_ID_VENDOR	0xffff0000
#define HPET_ID_LEGSUP	0x00008000
#define HPET_ID_NUMBER	0x00001f00
#define HPET_ID_REV	0x000000ff
#define	HPET_ID_NUMBER_SHIFT	8

#define HPET_ID_VENDOR_SHIFT	16
#define HPET_ID_VENDOR_8086	0x8086

#define HPET_CFG_ENABLE	0x001
#define HPET_CFG_LEGACY	0x002
#define	HPET_LEGACY_8254	2
#define	HPET_LEGACY_RTC		8

#define HPET_TN_ENABLE		0x004
#define HPET_TN_PERIODIC	0x008
#define HPET_TN_PERIODIC_CAP	0x010
#define HPET_TN_SETVAL		0x040
#define HPET_TN_32BIT		0x100
#define HPET_TN_ROUTE		0x3e00
#define HPET_TN_FSB		0x4000
#define HPET_TN_FSB_CAP		0x8000
#define HPET_TN_ROUTE_SHIFT	9


#define hpet_read32(x)    \
    (*(volatile u32 *)(fix_to_virt(FIX_HPET_BASE) + (x)))
#define hpet_write32(y,x) \
    (*(volatile u32 *)(fix_to_virt(FIX_HPET_BASE) + (x)) = (y))

extern unsigned long hpet_address;

/*
 * Detect and initialise HPET hardware: return counter update frequency.
 * Return value is zero if HPET is unavailable.
 */
u64 hpet_setup(void);

/*
 * Callback from legacy timer (PIT channel 0) IRQ handler.
 * Returns 1 if tick originated from HPET; else 0.
 */
int hpet_legacy_irq_tick(void);

/*
 * Temporarily use an HPET event counter for timer interrupt handling,
 * rather than using the LAPIC timer. Used for Cx state entry.
 */
void hpet_broadcast_init(void);
void hpet_broadcast_enter(void);
void hpet_broadcast_exit(void);
int hpet_broadcast_is_available(void);
void hpet_disable_legacy_broadcast(void);

#endif /* __X86_HPET_H__ */
