#ifndef _SYS_QUOTA_H
#define _SYS_QUOTA_H 1

#include <inttypes.h>
#include <sys/types.h>
#include <sys/mount.h>

/*
 * Convert diskblocks to blocks and the other way around.
 * currently only to fool the BSD source. :-)
 */
#define dbtob(num) ((num) << 10)
#define btodb(num) ((num) >> 10)

/*
 * Convert count of filesystem blocks to diskquota blocks, meant
 * for filesystems where i_blksize != BLOCK_SIZE
 */
#define fs_to_dq_blocks(num, blksize) (((num) * (blksize)) / BLOCK_SIZE)

/*
 * Definitions for disk quotas imposed on the average user
 * (big brother finally hits Linux).
 *
 * The following constants define the amount of time given a user
 * before the soft limits are treated as hard limits (usually resulting
 * in an allocation failure). The timer is started when the user crosses
 * their soft limit, it is reset when they go below their soft limit.
 */
#define MAX_IQ_TIME  604800	/* (7*24*60*60) 1 week */
#define MAX_DQ_TIME  604800	/* (7*24*60*60) 1 week */

#define MAXQUOTAS 2
#define USRQUOTA  0		/* element used for user quotas */
#define GRPQUOTA  1		/* element used for group quotas */

/*
 * Definitions for the default names of the quotas files.
 */
#define INITQFNAMES { \
   "user",      /* USRQUOTA */ \
   "group",   /* GRPQUOTA */ \
   "undefined", \
};

#define QUOTAFILENAME "quota"
#define QUOTAGROUP "staff"

#define NR_DQHASH 43          /* Just an arbitrary number any suggestions ? */
#define NR_DQUOTS 256         /* Number of quotas active at one time */

/*
 * Command definitions for the 'quotactl' system call.
 * The commands are broken into a main command defined below
 * and a subcommand that is used to convey the type of
 * quota that is being manipulated (see above).
 */
#define SUBCMDMASK  0x00ff
#define SUBCMDSHIFT 8
#define QCMD(cmd, type)  (((cmd) << SUBCMDSHIFT) | ((type) & SUBCMDMASK))

#define Q_QUOTAON  0x0100	/* enable quotas */
#define Q_QUOTAOFF 0x0200	/* disable quotas */
#define Q_GETQUOTA 0x0300	/* get limits and usage */
#define Q_SETQUOTA 0x0400	/* set limits and usage */
#define Q_SETUSE   0x0500	/* set usage */
#define Q_SYNC     0x0600	/* sync disk copy of a filesystems quotas */
#define Q_SETQLIM  0x0700	/* set limits */
#define Q_GETSTATS 0x0800	/* get collected stats */
#define Q_RSQUASH  0x1000	/* set root_squash option */

/*
 * The following structure defines the format of the disk quota file
 * (as it appears on disk) - the file is an array of these structures
 * indexed by user or group number.
 */
struct dqblk {
  uint32_t dqb_bhardlimit;	/* absolute limit on disk blks alloc */
  uint32_t dqb_bsoftlimit;	/* preferred limit on disk blks */
  uint32_t dqb_curblocks;	/* current block count */
  uint32_t dqb_ihardlimit;	/* maximum # allocated inodes */
  uint32_t dqb_isoftlimit;	/* preferred inode limit */
  uint32_t dqb_curinodes;	/* current # allocated inodes */
  time_t dqb_btime;		/* time limit for excessive disk use */
  time_t dqb_itime;		/* time limit for excessive files */
};

/*
 * Shorthand notation.
 */
#define	dq_bhardlimit	dq_dqb.dqb_bhardlimit
#define	dq_bsoftlimit	dq_dqb.dqb_bsoftlimit
#define	dq_curblocks	dq_dqb.dqb_curblocks
#define	dq_ihardlimit	dq_dqb.dqb_ihardlimit
#define	dq_isoftlimit	dq_dqb.dqb_isoftlimit
#define	dq_curinodes	dq_dqb.dqb_curinodes
#define	dq_btime	dq_dqb.dqb_btime
#define	dq_itime	dq_dqb.dqb_itime

#define dqoff(UID)      ((loff_t)((UID) * sizeof (struct dqblk)))

struct dqstats {
  uint32_t lookups;
  uint32_t drops;
  uint32_t reads;
  uint32_t writes;
  uint32_t cache_hits;
  uint32_t pages_allocated;
  uint32_t allocated_dquots;
  uint32_t free_dquots;
  uint32_t syncs;
};

__BEGIN_DECLS

extern int quotactl (int __cmd, const char *__special, int __id,
		     void* __addr) __THROW;

__END_DECLS

#endif /* sys/quota.h */
