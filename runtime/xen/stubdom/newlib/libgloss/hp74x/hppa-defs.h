/*
 * PDC support
 */
#define OPT_PDC_CACHE		5
#define OPT_PDC_ADD_VALID	12
#define OPT_PDC_CHASSIS		2	/* LED's */
#define OPT_PDC_IODC		8	/* console I/O */
#define IODC_CONSOLE_OUT	3	/* bytes out serial port */
#define IODC_CONSOLE_IN		2	/* bytes in serial port */

#define PGZ_MEM_PDC             0x0388  /* location of PDC_ENTRY in memory */
#define PGZ_CONSOLE_STRUCT      0x3A0   /* console config info */
#define CALL_PDC                (*(int (*)())((int *)(*((int *)PGZ_MEM_PDC))))

#define putDebugChar outbyte
#define getDebugChar inbyte

/*
 * IODC support
 */
#define MAX_BUS_CONVERTERS      6
#define MAX_LAYERS	        6
#define IO_CONSOLE_INPUT	2
#define IO_CONSOLE_OUTPUT	3

struct _dev {
	unsigned char	flags;			/* auto-search and auto-boot  */
	unsigned char	bus_convert[MAX_BUS_CONVERTERS];
	unsigned char	pm;			/* fixed field of HPA         */
	unsigned int	layer[MAX_LAYERS];	/* device dependent layers    */
	unsigned int	hpa;			/* device HPA                 */
	unsigned int	spa;			/* device SPA                 */
	unsigned int	*iodc_io;		/* address of ENTRY_IO in mem */
	unsigned int	class;			/* device class               */
};

/*
 * Register defintions
 */
#define gr0	%r0			/* always ZERO */
#define gr1	%r1			/* ADDIL results only */
#define gr2	%r2			/* return address */
#define gr3	%r3			/* scratch registers */
#define gr4	%r4
#define gr5	%r5
#define gr6	%r6
#define gr7	%r7
#define gr8	%r8
#define gr9	%r9
#define gr10	%r10
#define gr11	%r11
#define gr12	%r12
#define gr13	%r13
#define gr14	%r14
#define gr15	%r15
#define gr16	%r16
#define gr17	%r17
#define gr18	%r18
#define gr19	%r19			/* 4th temp register */
#define gr20	%r20			/* 3rd temp register */
#define gr21	%r21			/* 2rd temp register */
#define gr22	%r22			/* 1rd temp register */
#define gr23	%r23			/* argument 3 */
#define gr24	%r24			/* argument 2 */
#define gr25	%r25			/* argument 1 */
#define gr26	%r26			/* argument 0 */
#define gr27	%r27			/* global data pointer */
#define gr28	%r28			/* return value */
#define gr29	%r29			/* return value, static link */
#define gr30	%r30			/* stack pointer */
#define gr31	%r31			/* millicode return pointer */

/*
 * extra definitions, calling conventions
 */
#define rp		gr2		/* return address */
#define sp		gr30		/* stack pointer */
#define dp		gr27		/* global data area pointer */

/*
 * extra definitions, argument passing
 */
#define Arg0            gr26            /* pdc function to perform */
#define Arg1            gr25            /* args to the pdc function */
#define Arg2            gr24
#define Arg3            gr23

/*
 * Special Processor Registers
 */
#define SAR		%cr11		/* shift amount register */
#define IVA		%cr14		/* Interruption Vector Address */
#define EIEM		%cr15		/* EIEM reg */
#define EIR		%cr23		/* EIR reg */
#define TIMER		%cr16		/* interval timer */
#define CCR		%cr10		/* coprocessor control reg. */

/*
 * ASCII escape code
 */
#define NULL    0x00    /* <break>      soft-reset      (input only) */
#define DELP    0x03    /* <ctrl>C      del-collapse    (input only, non-std) */
#define DELE    0x04    /* <ctrl>D      del-to_eol      (input only, non-std) */
#define BELL    0x07    /* <ctrl>G      bell - audio */
#define BS      0x08    /* <ctrl>H      back space      (left arrow) */
#define HT      0x09    /* <ctrl>I      horizontal tab */
#define LF      0x0a    /* <ctrl>J      line feed       (down arrow) */
#define VT      0x0b    /* <ctrl>K      vertical tab    (up arrow) */
#define FF      0x0c    /* <ctrl>L      form feed       (right arrow) */
#define RTN     0x0d    /* <ctrl>M      carrage return */
#define CR      0x0d    /* <ctrl>M      carrage return */

#define INSC    0x0e    /* <ctrl>N      insert char     (input only, non-std) */
#define XON     0x11    /* <ctrl>Q      DC1 - continue */
#define BT      0x12    /* <ctrl>R      reverse tab     (input only, non-std) */
#define XOFF    0x13    /* <ctrl>S      DC3 - wait */
#define INSE    0x16    /* <ctrl>V      insert-expand   (input only, non-std) */
#define DELC    0x18    /* <ctrl>X      delete char     (input only, non-std) */
#define CLRH    0x1a    /* <ctrl>Z      clear/home      (input only) */
#define ESC     0x1b    /* <ctrl>[      escape          (must call key again) */
#define ENDL    0x1c    /* <ctrl>\      cursor-to-eol   (input only, non-std) */
#define HOME    0x1e    /* <ctrl>^      cursor home     (input only) */
#define DEL     0x7f    /* <shift>BS    destructive backspace */
