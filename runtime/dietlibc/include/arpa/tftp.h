#ifndef _ARPA_TFTP_H
#define _ARPA_TFTP_H

#include <inttypes.h>

#define	SEGSIZE		512		/* data segment size */
#define	RRQ	01				/* read request */
#define	WRQ	02				/* write request */
#define	DATA	03				/* data packet */
#define	ACK	04				/* acknowledgement */
#define	ERROR	05				/* error code */

struct	tftphdr {
  int16_t th_opcode;			/* packet type */
  union {
    uint16_t tu_block;	/* block # */
    int16_t tu_code;		/* error code */
    char	tu_stuff[1];		/* request packet stuff */
  } __attribute__ ((__packed__)) th_u;
  char	th_data[1];			/* data or error string */
} __attribute__ ((__packed__));

#define	th_block	th_u.tu_block
#define	th_code		th_u.tu_code
#define	th_stuff	th_u.tu_stuff
#define	th_msg		th_data

#define	EUNDEF		0		/* not defined */
#define	ENOTFOUND	1		/* file not found */
#define	EACCESS		2		/* access violation */
#define	ENOSPACE	3		/* disk full or allocation exceeded */
#define	EBADOP		4		/* illegal TFTP operation */
#define	EBADID		5		/* unknown transfer ID */
#define	EEXISTS		6		/* file already exists */
#define	ENOUSER		7		/* no such user */

#endif
