
/* ioctl command encoding: 32 bits total, command in lower 16 bits,
 * size of the parameter structure in the lower 14 bits of the
 * upper 16 bits.
 * Encoding the size of the parameter structure in the ioctl request
 * is useful for catching programs compiled with old versions
 * and to avoid overwriting user space outside the user buffer area.
 * The highest 2 bits are reserved for indicating the ``access mode''.
 * NOTE: This limits the max parameter size to 16kB -1 !
 */

/*
 * The following is for compatibility across the various Linux
 * platforms.  The i386 ioctl numbering scheme doesn't really enforce
 * a type field.  De facto, however, the top 8 bits of the lower 16
 * bits are indeed used as a type field, so we might just as well make
 * this explicit here.  Please be sure to use the decoding macros
 * below from now on.
 */
#define _IOC_NRBITS	8
#define _IOC_TYPEBITS	8
#define _IOC_SIZEBITS	14
#define _IOC_DIRBITS	2

#define _IOC_NRMASK	((1 << _IOC_NRBITS)-1)
#define _IOC_TYPEMASK	((1 << _IOC_TYPEBITS)-1)
#define _IOC_SIZEMASK	((1 << _IOC_SIZEBITS)-1)
#define _IOC_DIRMASK	((1 << _IOC_DIRBITS)-1)

#define _IOC_NRSHIFT	0
#define _IOC_TYPESHIFT	(_IOC_NRSHIFT+_IOC_NRBITS)
#define _IOC_SIZESHIFT	(_IOC_TYPESHIFT+_IOC_TYPEBITS)
#define _IOC_DIRSHIFT	(_IOC_SIZESHIFT+_IOC_SIZEBITS)

/*
 * Direction bits.
 */
#define _IOC_NONE	0U
#define _IOC_WRITE	1U
#define _IOC_READ	2U

#define _IOC(dir,type,nr,size) \
	(((dir)  << _IOC_DIRSHIFT) | \
	 ((type) << _IOC_TYPESHIFT) | \
	 ((nr)   << _IOC_NRSHIFT) | \
	 ((size) << _IOC_SIZESHIFT))

/* used to create numbers */
#define _IO(type,nr)		_IOC(_IOC_NONE,(type),(nr),0)
#define _IOR(type,nr,size)	_IOC(_IOC_READ,(type),(nr),sizeof(size))
#define _IOW(type,nr,size)	_IOC(_IOC_WRITE,(type),(nr),sizeof(size))
#define _IOWR(type,nr,size)	_IOC(_IOC_READ|_IOC_WRITE,(type),(nr),sizeof(size))

/* used to decode ioctl numbers.. */
#define _IOC_DIR(nr)		(((nr) >> _IOC_DIRSHIFT) & _IOC_DIRMASK)
#define _IOC_TYPE(nr)		(((nr) >> _IOC_TYPESHIFT) & _IOC_TYPEMASK)
#define _IOC_NR(nr)		(((nr) >> _IOC_NRSHIFT) & _IOC_NRMASK)
#define _IOC_SIZE(nr)		(((nr) >> _IOC_SIZESHIFT) & _IOC_SIZEMASK)

/* ...and for the drivers/sound files... */

#define IOC_IN		(_IOC_WRITE << _IOC_DIRSHIFT)
#define IOC_OUT		(_IOC_READ << _IOC_DIRSHIFT)
#define IOC_INOUT	((_IOC_WRITE|_IOC_READ) << _IOC_DIRSHIFT)
#define IOCSIZE_MASK	(_IOC_SIZEMASK << _IOC_SIZESHIFT)
#define IOCSIZE_SHIFT	(_IOC_SIZESHIFT)

/* 0x54 is just a magic number to make these relatively unique ('T') */

#define TCGETS		0x5401
#define TCSETS		0x5402
#define TCSETSW		0x5403
#define TCSETSF		0x5404
#define TCGETA		0x5405
#define TCSETA		0x5406
#define TCSETAW		0x5407
#define TCSETAF		0x5408
#define TCSBRK		0x5409
#define TCXONC		0x540A
#define TCFLSH		0x540B
#define TIOCEXCL	0x540C
#define TIOCNXCL	0x540D
#define TIOCSCTTY	0x540E
#define TIOCGPGRP	0x540F
#define TIOCSPGRP	0x5410
#define TIOCOUTQ	0x5411
#define TIOCSTI		0x5412
#define TIOCGWINSZ	0x5413
#define TIOCSWINSZ	0x5414
#define TIOCMGET	0x5415
#define TIOCMBIS	0x5416
#define TIOCMBIC	0x5417
#define TIOCMSET	0x5418
#define TIOCGSOFTCAR	0x5419
#define TIOCSSOFTCAR	0x541A
#define FIONREAD	0x541B
#define TIOCINQ		FIONREAD
#define TIOCLINUX	0x541C
#define TIOCCONS	0x541D
#define TIOCGSERIAL	0x541E
#define TIOCSSERIAL	0x541F
#define TIOCPKT		0x5420
#define FIONBIO		0x5421
#define TIOCNOTTY	0x5422
#define TIOCSETD	0x5423
#define TIOCGETD	0x5424
#define TCSBRKP		0x5425	/* Needed for POSIX tcsendbreak() */
#define TIOCTTYGSTRUCT	0x5426  /* For debugging only */
#define TIOCSBRK	0x5427  /* BSD compatibility */
#define TIOCCBRK	0x5428  /* BSD compatibility */
#define TIOCGSID	0x5429  /* Return the session ID of FD */
#define TIOCGPTN	_IOR('T',0x30, unsigned int) /* Get Pty Number (of pty-mux device) */
#define TIOCSPTLCK	_IOW('T',0x31, int)  /* Lock/unlock Pty */

#define FIONCLEX	0x5450  /* these numbers need to be adjusted. */
#define FIOCLEX		0x5451
#define FIOASYNC	0x5452
#define TIOCSERCONFIG	0x5453
#define TIOCSERGWILD	0x5454
#define TIOCSERSWILD	0x5455
#define TIOCGLCKTRMIOS	0x5456
#define TIOCSLCKTRMIOS	0x5457
#define TIOCSERGSTRUCT	0x5458 /* For debugging only */
#define TIOCSERGETLSR   0x5459 /* Get line status register */
#define TIOCSERGETMULTI 0x545A /* Get multiport config  */
#define TIOCSERSETMULTI 0x545B /* Set multiport config */

#define TIOCMIWAIT	0x545C	/* wait for a change on serial input line(s) */
#define TIOCGICOUNT	0x545D	/* read serial port inline interrupt counts */
#define FIOQSIZE	0x545E

/* Used for packet mode */
#define TIOCPKT_DATA		 0
#define TIOCPKT_FLUSHREAD	 1
#define TIOCPKT_FLUSHWRITE	 2
#define TIOCPKT_STOP		 4
#define TIOCPKT_START		 8
#define TIOCPKT_NOSTOP		16
#define TIOCPKT_DOSTOP		32

#define TIOCSER_TEMT	0x01	/* Transmitter physically empty */

/* Socket-level I/O control calls. */
#define FIOSETOWN 	0x8901
#define SIOCSPGRP	0x8902
#define FIOGETOWN	0x8903
#define SIOCGPGRP	0x8904
#define SIOCATMARK	0x8905
#define SIOCGSTAMP	0x8906		/* Get stamp */
