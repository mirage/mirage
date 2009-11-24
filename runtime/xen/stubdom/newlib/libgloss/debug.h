/* 
 * Copyright (c) 1995, 1996 Cygnus Support
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

static const char hexchars[]="0123456789abcdef";

typedef void (*exception_t)(int);   /* pointer to function with int parm */

/*
 * This is the default function handler to be called with all exceptions.
 */
extern exception_t default_trap_hook;

/* this is used to make Unix style signale nukbers to an exception */
struct trap_info
{
  unsigned char tt;		/* exception number */
  unsigned char signo;		/* corresponding signal number */
};

/* 
 * prototypes for the functions in debug.c. As these'll only be used with GCC,
 * we don't worry about no stinkin K&R comilers.
 */
extern void exception_handler (int, unsigned long);
extern unsigned char *mem2hex(unsigned char *, unsigned char *, int, int);
extern unsigned char *hex2mem(unsigned char *, unsigned char *, int, int);
extern void getpacket(unsigned char *);
extern void putpacket(unsigned char *);
extern char *make_return_packet(int);
extern void set_debug_traps();
extern int computeSignal(int);
extern char digit2hex(int);
extern int hex2digit(int);
extern void debuglogs(int level, char *msg);
extern int hex2int();
extern char *int2hex(int);
extern void gdb_event_loop(int, unsigned long *);

extern char *gdb_read_registers();		/* g - read registers */
extern char *gdb_write_registers(char *);	/* G - write registers */
extern char *gdb_read_memory(long, int);	/* m - read memory */
extern char *gdb_write_memory(long, int, char *);/* M write memory */
extern char *gdb_continue(int, long );		/* c - continue */
extern char *gdb_step(int, long);		/* s - step instruction(s) */
extern char *gdb_kill();			/* k - kill program */
extern char *gdb_last_signal();			/* ? - last signal */
extern char *gdb_baudrate(int);			/* b - change baud rate */
extern char *gdb_dump_state();			/* T - dump state */
extern char *gdb_set_thread(int, int);		/* H - set thread */
extern char *gdb_detach();			/* D - detach */
extern char *gdb_read_reg(int);			/* p - read one register */
extern char *gdb_write_reg(int, long);	        /* P - write one register */
extern char *gdb_exited();			/* W - process exited */
extern char *gdb_terminated();			/* X - process terminated */
extern char *gdb_hex();				/* O - hex encoding */
extern char *gdb_thread_alive(int);		/* A - tread alive request */
extern char *gdb_extended();			/* ! - extended protocol */
extern char *gdb_debug();			/* d - toggle stub diagnostics */
extern char *gdb_toggle();			/* unsupported, toggle stub on/off */
extern char *gdb_reset();			/* r - reset target */
extern char *gdb_search(long, long, long);	/* t - search backwards */
extern char *gdb_query(char *);			/* q - general query */
extern char *gdb_set(char *);			/* Q - set value */

/*
 * indicate to caller of mem2hex or hex2mem that there has been an error. 
 * 0 means ok, 1 means error
 */
extern volatile int mem_err;

/*
 * indicate whether the debug vectors have been initialized
 * 0 means not yet, 1 means yep, it's ready.
 */
extern int initialized;

/*
 * 1 means print debugging messages from the target, 0 means be quiet.
 */
extern int remote_debug;

/*
 * Set up the command processing required for GDB
 */

struct gdb_ops {
  /* 
   * these functions are the most minimal working subset top get full
   * functionality for remote debugging
   */
  char	*(*gdb_read_registers);			/* g - read registers */
  char  *(*gdb_write_registers)(char *);	/* G - write registers */
  char	*(*gdb_read_memory)(long, int);		/* m - read memory */
  char  *(*gdb_write_memory)(long, int, char *);/* M write memory */
  char  *(*gdb_continue)(int, long );		/* c - continue */
  char  *(*gdb_step)(int, long);		/* s - step instruction(s) */
  char  *(*gdb_kill);				/* k - kill program */
  char	*(*gdb_last_signal);			/* ? - last signal */
  char	*(*gdb_baudrate)(int);			/* b - change baud rate */
  char	*(*gdb_dump_state);			/* T - dump state */
  /*
   * these functions are for a more sophisticated target, typically
   * running a simple RTOS.
   */
  char	*(*gdb_set_thread)(int, int);		/* H - set thread */
  char	*(*gdb_detach);				/* D - detach */
  char	*(*gdb_read_reg)(int);			/* p - read one register */
  char  *(*gdb_write_reg)(int, long);	        /* P - write one register */
  char	*(*gdb_exited);				/* W - process exited */
  char	*(*gdb_terminated);			/* X - process terminated */
  char	*(*gdb_hex);				/* O - hex encoding */
  char	*(*gdb_thread_alive)(int);		/* A - tread alive request */
						/* FIXME: not standard yet */
  char	*(*gdb_extended);			/* ! - extended protocol */
  char	*(*gdb_debug);				/* d - toggle stub diagnostics */
  char	*(*gdb_toggle);				/* unsupported, toggle stub on/off */
  char	*(*gdb_reset);				/* r - reset target */
  char	*(*gdb_search)(long, long, long);	/* t - search backwards */
  char	*(*gdb_query)(char *);			/* q - general query */
  char	*(*gdb_set)(long);			/* Q - set value */
};

/*
 * BUFMAX defines the maximum number of characters in inbound/outbound buffers
 * at least NUMREGBYTES*2 are needed for register packets
 */
#define BUFMAX 2048
extern char packet_in_buf[BUFMAX];
extern char packet_out_buf[BUFMAX];
extern int  packet_index;

#define DEBUG(x, y)		debuglog(x, y);
#define set_debug_level(x)	remote_debug = x;
#define OK 0
#define ERROR -1
#define ENN(x) "x"

#define MAY_FAULT 1
#define NO_FAULT 0
