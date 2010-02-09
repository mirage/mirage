#ifndef _POSIX_TERMIOS_H
#define _POSIX_TERMIOS_H

#define NCC 32

struct termios {
    unsigned long c_iflag;
    unsigned long c_oflag;
    unsigned long c_lflag;
    unsigned long c_cflag;
    unsigned char c_cc[NCC];
};

/* modem lines */
#define TIOCM_DTR	0x002
#define TIOCM_RTS	0x004
#define TIOCM_CTS	0x020
#define TIOCM_CAR	0x040
#define TIOCM_RI	0x080
#define TIOCM_DSR	0x100

/* c_iflag */
#define IGNBRK	0x00000001
#define BRKINT	0x00000002
#define IGNPAR	0x00000004
#define PARMRK	0x00000008
#define INPCK	0x00000010
#define ISTRIP	0x00000020
#define INLCR	0x00000040
#define IGNCR	0x00000080
#define ICRNL	0x00000100
#define IUCLC	0x00000200
#define IXON	0x00000400
#define IXANY	0x00000800
#define IXOFF	0x00001000
#define IMAXBEL	0x00002000
#define IUTF8	0x00004000

/* c_oflag */
#define OPOST	0x00000001
#define OLCUC	0x00000002
#define ONLCR	0x00000004
#define OCRNL	0x00000008
#define ONOCR	0x00000010
#define ONLRET	0x00000020
#define OFILL	0x00000040
#define OFDEL	0x00000080

/* c_lflag */
#define ISIG	0x00000001
#define ICANON	0x00000002
#define XCASE	0x00000004
#define ECHO	0x00000008
#define ECHOE	0x00000010
#define ECHOK	0x00000020
#define ECHONL	0x00000040
#define NOFLSH	0x00000080
#define TOSTOP	0x00000100
#define ECHOCTL	0x00000200
#define ECHOPRT	0x00000400
#define ECHOKE	0x00000800
#define FLUSHO	0x00002000
#define PENDIN	0x00004000
#define IEXTEN	0x00008000

/* c_cflag */
#define CSIZE	0x00000030
#define CS8	0x00000030
#define CSTOPB	0x00000040
#define CREAD	0x00000080
#define PARENB	0x00000100
#define PARODD	0x00000200
#define HUPCL	0x00000400
#define CLOCAL	0x00000800

/* c_cc */
#define VTIME	5
#define VMIN	6

#define TCSANOW		0
#define TCSADRAIN	1
#define TCSAFLUSH	2

int tcsetattr(int fildes, int action, const struct termios *tios);
int tcgetattr(int fildes, struct termios *tios);

#endif /* _POSIX_TERMIOS_H */
