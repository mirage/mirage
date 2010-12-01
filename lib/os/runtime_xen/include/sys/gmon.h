#ifndef __DLC_GMON_H_
#define __DLC_GMON_H_

#include <sys/cdefs.h>

__BEGIN_DECLS

# define HISTCOUNTER	unsigned short
# define HISTFRACTION	2
# define HASHFRACTION	2
# define ARCDENSITY		2
# define MINARCS		50
# define MAXARCS		(( 1 << (8 * sizeof(HISTCOUNTER))) - 2)

# define ROUNDDOWN(x,y)	(((x)/(y))*y)
# define ROUNDUP(x,y)	((((x)+(y)-1)/(y))*y)

# define PROF_SECTION __attribute__ ((section (".profile")))

struct tostruct {
	unsigned long	selfpc;
	signed long		count;
	unsigned short	link;
	unsigned short	pad;
};

struct rawarc {
	unsigned long	raw_frompc;
	unsigned long	raw_selfpc;
	signed long		raw_count;
};

struct monparam  {
	unsigned short *kcount;
	unsigned long   kcountsize;
	struct rawarc  *arcs;
	unsigned long	arcnum;
	unsigned long   lowpc;
	unsigned long   highpc;
	unsigned long   textsize;
};

struct gmonparam {
	long           state;
	unsigned short *kcount;
	unsigned long  kcountsize;
	unsigned short *froms;
	unsigned long  fromsize;
	struct tostruct *tos;
	unsigned long  tossize;
	long           tolimit;
	unsigned long  lowpc;
	unsigned long  highpc;
	unsigned long  textsize;
	unsigned long  hashfraction;
	unsigned long  log_hashfraction;
};

struct gmon_hdr {
	char cookie[4];
	long version;
	char spare[12];
};

struct gmon_hist_hdr {
	long low_pc;
	long high_pc;
	long hist_size;
	long prof_rate;
	char dimen[15];
	char dimen_abbrev;
};

struct gmon_cg_arc_record {
	long from_pc;
	long self_pc;
	long count;
};

struct __bb {
	long	zero_word;
	char	*filename;
	long	*counts;
	long	ncounts;
	struct __bb *next;
	unsigned long *addresses;
};

typedef enum {
	GMON_TAG_TIME_HIST, GMON_TAG_CG_ARC, GMON_TAG_BB_COUNT
} GMON_Record_Tag;

enum { GMON_PROF_ON, GMON_PROF_BUSY, GMON_PROF_ERROR, GMON_PROF_OFF };
enum { GPROF_STATE, GPROF_COUNT, GPROF_FROMS, GPROF_TOS, GPROF_GMONPARAM };

extern struct gmonparam gmparam;
extern struct __bb * __bb_head;

extern void __monstartup(unsigned long, unsigned long);
extern void monstartup(unsigned long, unsigned long);
extern void _mcleanup(void);

__END_DECLS

#endif
