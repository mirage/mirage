/* Stand-alone library for Sparclet 701 board
 *
 * Copyright (c) 1996 Cygnus Support
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */

#define RAM_BASE		((unsigned char *)0x12000000) /* Start of cacheable dram */
#define DCACHE_LINES		128	   /* Number of lines in data cache */
#define DCACHE_LINE_SIZE	16	   /* Bytes per data cache line */
#define DCACHE_BANKS		4	   /* 4-way associative */
#define CACHE_INST_TAG_ADDR	((unsigned char *)0xc0020000) /* I-Cache tag base address */
#define ALL_BANKS		0x0000f000 /* Selects all 4 cache banks */
#define ICACHE_LINES		128	   /* Number of lines in inst cache */
#define ICACHE_LINE_SIZE	32	   /* Bytes per inst cache line */

/* I/O Base addresses */
#define CACHE_INST_BASE_ADD     0xc0000000
#define CACHE_DATA_BASE_ADD     0xc8000000
#define	_InstrCacheCtlBase	0xc0000000
#define	_DataCacheCtlBase	0xc8000000

#define USART_BASE_ADD          0x92000000
#define	USART_BASE_ADRS(n)	(USART_BASE_ADD + ((n)<<21))	/*0..3*/

/* Serial receiver definitions */
#define	USART_RX_CHAR(n) (*(unsigned char *) (USART_BASE_ADRS(n)  +(2<<19)))
#define	USART_RX_CTRL_BASE_ADRS(n)	 (USART_BASE_ADRS(n)+(3<<19))
#define URSTR(n) 	(*(unsigned int *) (USART_RX_CTRL_BASE_ADRS(n)+(2<<15)))
#define	URSTR_CHAR_NUM			0x1f00	/* Bits 8-12 */

/* Serial receiver definitions */
#define	USART_TX_CHAR(n)	(*(unsigned char *) (USART_BASE_ADRS(n)+3))
#define	USART_TX_CTRL_BASE_ADRS(n)	 (USART_BASE_ADRS(n)+(1<<19))
#define UTSTR(n) 	(*(unsigned int *) (USART_TX_CTRL_BASE_ADRS(n)+(2<<15)))
#define	UTSTR_CHAR_FREE			0x1f0	/* Bits 4-8 */

/* Cache definitions */
#define DCCA_NB_LINES       128         /* Nb of lines of the cache */
/* Bank number, used for Cache Memory and Cache Tag */
#define	ICCA_B3	   	0x000008000	/* Bit 15 - 1:Bank3 selected       */
#define	ICCA_B2   	0x000004000	/* Bit 14 - 1:Bank2 selected       */
#define	ICCA_B1   	0x000002000	/* Bit 13 - 1:Bank1 selected       */
#define	ICCA_B0   	0x000001000	/* Bit 12 - 1:Bank0 selected       */
/* Register address, show which register is to be checked/updated */
#define	ICCACR		0x00000000	/* Bits 17 - 16 - Control register */
#define	ICCAMEM     	0x00010000	/* Bits 17 - 16 - Cache memory     */
#define	DCCACR          0x00000000	/* Bits 16 - 15 - Control register */
/* Instruction Cache Controller Register */
#define	ICCR_DISABLE  0xfffffffe	/* Reset enable bit                 */

/* Serial I/O routines */

#define STUB_PORT 1		/* 0 = serial port A;  1 = serial port B */

static volatile unsigned char *rx_fifo = &USART_RX_CHAR(STUB_PORT);
static volatile unsigned int *rx_status = &URSTR(STUB_PORT);

static volatile unsigned char *tx_fifo = &USART_TX_CHAR(STUB_PORT);
static volatile unsigned int *tx_status = &UTSTR(STUB_PORT);

/* library-free debug reoutines */
#ifdef XDEBUG
#define XDBG_MSG(x) pmsg(x)
#define XDBG_HEX(x) phex(x)
#else
#define XDBG_MSG(x) 
#define XDBG_HEX(x) 
#endif

static int
rx_rdy()
{
  return (*rx_status & URSTR_CHAR_NUM);
}

static unsigned char
rx_char()
{
  return *rx_fifo;
}

void
tx_char(char c)
{
  *tx_fifo = c;
}

static int
tx_rdy()
{
  return (*tx_status & UTSTR_CHAR_FREE);
}

int
getDebugChar()
{
  while (!rx_rdy())
    ;
  return rx_char();
}

void
putDebugChar(int c)
{
  while (!tx_rdy())
    ;
  tx_char(c);
}

#ifdef XDEBUG
/* library-free debug reoutines */
/* print a string */
void pmsg(char *p)
{
    while (*p)
    {
	if (*p == '\n')
	    putDebugChar('\r');
	putDebugChar(*p++);
    }
}

/* print a hex number */
void phex(long x)
{
    char buf[9];
    int i;

    buf[8] = '\0';
    for (i = 7; i >= 0; i--)
    {
	char c = x & 0x0f;
	buf[i] = c < 10 ? c + '0' : c - 10 + 'A';
	x >>= 4;
    }
    pmsg(buf);
}
#endif

/* rdtbr() - read the trap base register */

unsigned long rdtbr();

asm("
	.text
	.align 4
	.globl _rdtbr
_rdtbr:
	retl
	mov	%tbr, %o0
");

/* wrtbr() - write the trap base register */

void wrtbr(unsigned long);

asm("
	.text
	.align 4
	.globl _wrtbr
_wrtbr:
	retl
	mov	%o0, %tbr
");

/* Each entry in the trap vector occupies four words. */

struct trap_entry
{
  unsigned sethi_filler:10;
  unsigned sethi_imm22:22;
  unsigned jmpl_filler:19;
  unsigned jmpl_simm13:13;
  unsigned long filler[2];
};

extern struct trap_entry fltr_proto;
asm ("
	.data
	.globl _fltr_proto
	.align 4
_fltr_proto:			! First level trap routine prototype
	sethi 0, %l0
	jmpl 0+%l0, %g0
	nop
	nop

	.text
	.align 4
");

/* copy_vectors - Copy the trap vectors from ROM to RAM, set the TBR register
   to point to the RAM vectors, and return the address of the RAM vectors.  */

extern struct trap_entry __trap_vectors[256];	/* defined in matra.ld */

struct trap_entry *copy_vectors()
{
  int i;
  struct trap_entry *old = (struct trap_entry *) (rdtbr() & ~0xfff);

  XDBG_MSG("Copying vectors...\n");
  for (i = 0; i < 256; i++)
    __trap_vectors[i] = old[i];
  wrtbr ((unsigned long)__trap_vectors);
  XDBG_MSG("Done\n");
  return __trap_vectors;
}


void
disable_cache()
{
  unsigned long *ptr;
  static unsigned long CACHE_shadow_iccr = 0;   /* Because CR cannot be read */
  static unsigned long CACHE_shadow_dccr = 0;   /* Because CR cannot be read */

  XDBG_MSG("Disabling cache...\n");
  ptr = (unsigned long*)(CACHE_INST_BASE_ADD | ICCACR);
  CACHE_shadow_iccr = CACHE_shadow_iccr & ICCR_DISABLE;
  *ptr = CACHE_shadow_iccr;

  ptr = (unsigned long*)(CACHE_DATA_BASE_ADD | DCCACR);
  CACHE_shadow_dccr = CACHE_shadow_dccr & ICCR_DISABLE;
  *ptr = CACHE_shadow_dccr;
  XDBG_MSG("Done\n");
}

/* Flush the instruction cache.  We need to do this for the debugger stub so
   that breakpoints, et. al. become visible to the instruction stream after
   storing them in memory.  FIXME!!
 */

void
flush_i_cache ()
{
  volatile unsigned char *addr;

  /* First, force all dirty items in the data cache to be moved out to real
     memory.  This is done by making read refs to alternate addresses that will
     fill up all four banks for each line.  Note that we actually have to
     reference 8 locs per line just in case the region of memory we use is one
     of the areas that needs to be flushed.  */

  for (addr = RAM_BASE;
       addr < RAM_BASE + (DCACHE_LINES * DCACHE_LINE_SIZE * DCACHE_BANKS) * 2;
       addr += DCACHE_LINE_SIZE)
    *addr;			/* Read the loc */

  /* Now, flush the instruction cache.  */

  for (addr = CACHE_INST_TAG_ADDR + ALL_BANKS;
       addr <= CACHE_INST_TAG_ADDR + ALL_BANKS + ICACHE_LINES * ICACHE_LINE_SIZE;
       addr += ICACHE_LINE_SIZE)
    *(unsigned long *)addr = 0; /* Clr tag entry for all banks on this line */
}

/* Setup trap TT to go to ROUTINE. */

void
exceptionHandler (int tt, unsigned long routine)
{
  static struct trap_entry *tb;		/* Trap vector base address */

  if (!tb)
    {
      tb = copy_vectors();		/* Copy trap vectors to RAM */
      disable_cache();			/* Disable cache  FIXME!! */
    }

  XDBG_MSG("Setting exception handler for trap...\n");

  tb[tt] = fltr_proto;

  tb[tt].sethi_imm22 = routine >> 10;
  tb[tt].jmpl_simm13 = routine & 0x3ff;

  XDBG_MSG("Done\n");
}
