#ifndef	_SYS_TERMIO_H
# define _SYS_TERMIO_H

# define TCGETA (('T'<<8)|1)
# define TCSBRK (('T'<<8)|5)
# define NCC 8

# define IGNBRK	000001
# define BRKINT	000002
# define IGNPAR	000004
# define INPCK	000020
# define ISTRIP	000040
# define INLCR	000100
# define IGNCR	000200
# define ICRNL	000400
# define IXON	002000
# define IXOFF	010000

# define OPOST	000001
# define OCRNL	000004
# define ONLCR	000010
# define ONOCR	000020
# define TAB3	014000

# define CLOCAL	004000
# define CREAD	000200
# define CSIZE	000060
# define CS5	0
# define CS6	020
# define CS7	040
# define CS8	060
# define CSTOPB	000100
# define HUPCL	002000
# define PARENB	000400
# define PAODD	001000

# define ECHO	0000010
# define ECHOE	0000020
# define ECHOK	0000040
# define ECHONL	0000100
# define ICANON	0000002
# define IEXTEN	0000400	/* anybody know *what* this does?! */
# define ISIG	0000001
# define NOFLSH	0000200

# define VEOF	4	/* also VMIN -- thanks, AT&T */
# define VEOL	5	/* also VTIME -- thanks again */
# define VERASE	2
# define VINTR	0
# define VKILL	3
# define VMIN	4	/* also VEOF */
# define VQUIT	1
# define VTIME	5	/* also VEOL */

# define B0	000000
# define B50	000001
# define B75	000002
# define B110	000003
# define B134	000004
# define B150	000005
# define B200	000006
# define B300	000007
# define B600	000010
# define B1200	000011
# define B1800	000012
# define B2400	000013
# define B4800	000014
# define B9600	000015
# define B19200	000016
# define B38400	000017

struct termio {
	unsigned short	c_iflag;
	unsigned short	c_oflag;
	unsigned short	c_cflag;
	unsigned short	c_lflag;
	char		c_line;
	unsigned char	c_cc[NCC];
};

#endif	/* _SYS_TERMIO_H */

