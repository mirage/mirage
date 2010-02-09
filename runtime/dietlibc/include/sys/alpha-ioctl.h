#define _IOC_NRBITS	8
#define _IOC_TYPEBITS	8
#define _IOC_SIZEBITS	13
#define _IOC_DIRBITS	3

#define _IOC_NRMASK	((1 << _IOC_NRBITS)-1)
#define _IOC_TYPEMASK	((1 << _IOC_TYPEBITS)-1)
#define _IOC_SIZEMASK	((1 << _IOC_SIZEBITS)-1)
#define _IOC_DIRMASK	((1 << _IOC_DIRBITS)-1)

#define _IOC_NRSHIFT	0
#define _IOC_TYPESHIFT	(_IOC_NRSHIFT+_IOC_NRBITS)
#define _IOC_SIZESHIFT	(_IOC_TYPESHIFT+_IOC_TYPEBITS)
#define _IOC_DIRSHIFT	(_IOC_SIZESHIFT+_IOC_SIZEBITS)

/*
 * Direction bits _IOC_NONE could be 0, but OSF/1 gives it a bit.
 * And this turns out useful to catch old ioctl numbers in header
 * files for us.
 */
#define _IOC_NONE	1U
#define _IOC_READ	2U
#define _IOC_WRITE	4U

#define _IOC(dir,type,nr,size)			\
	((unsigned int)				\
	 (((dir)  << _IOC_DIRSHIFT) |		\
	  ((type) << _IOC_TYPESHIFT) |		\
	  ((nr)   << _IOC_NRSHIFT) |		\
	  ((size) << _IOC_SIZESHIFT)))

/* used to create numbers */
#define _IO(type,nr)		_IOC(_IOC_NONE,(type),(nr),0)
#define _IOR(type,nr,size)	_IOC(_IOC_READ,(type),(nr),sizeof(size))
#define _IOW(type,nr,size)	_IOC(_IOC_WRITE,(type),(nr),sizeof(size))
#define _IOWR(type,nr,size)	_IOC(_IOC_READ|_IOC_WRITE,(type),(nr),sizeof(size))

/* used to decode them.. */
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

#define FIOCLEX		_IO('f', 1)
#define FIONCLEX	_IO('f', 2)
#define FIOASYNC	_IOW('f', 125, int)
#define FIONBIO		_IOW('f', 126, int)
#define FIONREAD	_IOR('f', 127, int)
#define TIOCINQ		FIONREAD
#define FIOQSIZE	_IOR('f', 128, loff_t)

#define TIOCGETP	_IOR('t', 8, struct sgttyb)
#define TIOCSETP	_IOW('t', 9, struct sgttyb)
#define TIOCSETN	_IOW('t', 10, struct sgttyb)	/* TIOCSETP wo flush */

#define TIOCSETC	_IOW('t', 17, struct tchars)
#define TIOCGETC	_IOR('t', 18, struct tchars)
#define TCGETS		_IOR('t', 19, struct termios)
#define TCSETS		_IOW('t', 20, struct termios)
#define TCSETSW		_IOW('t', 21, struct termios)
#define TCSETSF		_IOW('t', 22, struct termios)

#define TCGETA		_IOR('t', 23, struct termio)
#define TCSETA		_IOW('t', 24, struct termio)
#define TCSETAW		_IOW('t', 25, struct termio)
#define TCSETAF		_IOW('t', 28, struct termio)

#define TCSBRK		_IO('t', 29)
#define TCXONC		_IO('t', 30)
#define TCFLSH		_IO('t', 31)

#define TIOCSWINSZ	_IOW('t', 103, struct winsize)
#define TIOCGWINSZ	_IOR('t', 104, struct winsize)
#define	TIOCSTART	_IO('t', 110)		/* start output, like ^Q */
#define	TIOCSTOP	_IO('t', 111)		/* stop output, like ^S */
#define TIOCOUTQ        _IOR('t', 115, int)     /* output queue size */

#define TIOCGLTC	_IOR('t', 116, struct ltchars)
#define TIOCSLTC	_IOW('t', 117, struct ltchars)
#define TIOCSPGRP	_IOW('t', 118, int)
#define TIOCGPGRP	_IOR('t', 119, int)

#define TIOCEXCL	0x540C
#define TIOCNXCL	0x540D
#define TIOCSCTTY	0x540E

#define TIOCSTI		0x5412
#define TIOCMGET	0x5415
#define TIOCMBIS	0x5416
#define TIOCMBIC	0x5417
#define TIOCMSET	0x5418
# define TIOCM_LE	0x001
# define TIOCM_DTR	0x002
# define TIOCM_RTS	0x004
# define TIOCM_ST	0x008
# define TIOCM_SR	0x010
# define TIOCM_CTS	0x020
# define TIOCM_CAR	0x040
# define TIOCM_RNG	0x080
# define TIOCM_DSR	0x100
# define TIOCM_CD	TIOCM_CAR
# define TIOCM_RI	TIOCM_RNG
# define TIOCM_OUT1	0x2000
# define TIOCM_OUT2	0x4000
# define TIOCM_LOOP	0x8000

#define TIOCGSOFTCAR	0x5419
#define TIOCSSOFTCAR	0x541A
#define TIOCLINUX	0x541C
#define TIOCCONS	0x541D
#define TIOCGSERIAL	0x541E
#define TIOCSSERIAL	0x541F
#define TIOCPKT		0x5420
# define TIOCPKT_DATA		 0
# define TIOCPKT_FLUSHREAD	 1
# define TIOCPKT_FLUSHWRITE	 2
# define TIOCPKT_STOP		 4
# define TIOCPKT_START		 8
# define TIOCPKT_NOSTOP		16
# define TIOCPKT_DOSTOP		32


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

#define TIOCSERCONFIG	0x5453
#define TIOCSERGWILD	0x5454
#define TIOCSERSWILD	0x5455
#define TIOCGLCKTRMIOS	0x5456
#define TIOCSLCKTRMIOS	0x5457
#define TIOCSERGSTRUCT	0x5458 /* For debugging only */
#define TIOCSERGETLSR   0x5459 /* Get line status register */
  /* ioctl (fd, TIOCSERGETLSR, &result) where result may be as below */
# define TIOCSER_TEMT    0x01	/* Transmitter physically empty */
#define TIOCSERGETMULTI 0x545A /* Get multiport config  */
#define TIOCSERSETMULTI 0x545B /* Set multiport config */

#define TIOCMIWAIT	0x545C	/* wait for a change on serial input line(s) */
#define TIOCGICOUNT	0x545D	/* read serial port inline interrupt counts */
#define TIOCGHAYESESP	0x545E  /* Get Hayes ESP configuration */
#define TIOCSHAYESESP	0x545F  /* Set Hayes ESP configuration */

/* Socket-level I/O control calls. */

#define FIOGETOWN	_IOR('f', 123, int)
#define FIOSETOWN 	_IOW('f', 124, int)

#define SIOCATMARK	_IOR('s', 7, int)
#define SIOCSPGRP	_IOW('s', 8, pid_t)
#define SIOCGPGRP	_IOR('s', 9, pid_t)

#define SIOCGSTAMP	0x8906		/* Get stamp - linux-specific */
