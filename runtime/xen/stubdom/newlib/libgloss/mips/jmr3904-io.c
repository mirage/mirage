

#define READ_UINT8( _register_, _value_ ) \
        ((_value_) = *((volatile unsigned char *)(_register_)))

#define WRITE_UINT8( _register_, _value_ ) \
        (*((volatile unsigned char *)(_register_)) = (_value_))

 /* - Board specific addresses for serial chip */
#define DIAG_BASE       0xfffff300
#define DIAG_SLCR       (DIAG_BASE+0x00)
#define DIAG_SLSR       (DIAG_BASE+0x04)
#define DIAG_SLDICR     (DIAG_BASE+0x08)
#define DIAG_SLDISR     (DIAG_BASE+0x0C)
#define DIAG_SFCR       (DIAG_BASE+0x10)
#define DIAG_SBRG       (DIAG_BASE+0x14)
#define DIAG_TFIFO      (DIAG_BASE+0x20)
#define DIAG_RFIFO      (DIAG_BASE+0x30)

#define BRG_T0          0x0000
#define BRG_T2          0x0100
#define BRG_T4          0x0200
#define BRG_T5          0x0300


#define READ_UINT16( _register_, _value_ ) \
     ((_value_) = *((volatile unsigned short *)(_register_)))

#define WRITE_UINT16( _register_, _value_ ) \
     (*((volatile unsigned short *)(_register_)) = (_value_))

unsigned char
inbyte (void)
{
  unsigned char c;
  unsigned short disr;
  
  for (;;)
    {
      READ_UINT16 (DIAG_SLDISR, disr);
      if (disr & 0x0001)
	break;
    }
  disr = disr & ~0x0001;
  READ_UINT8 (DIAG_RFIFO, c);
  WRITE_UINT16 (DIAG_SLDISR, disr);
  return c;
}

void
outbyte (unsigned char c)
{
  unsigned short disr;
  
  for (;;)
    {
      READ_UINT16 (DIAG_SLDISR, disr);
      if (disr & 0x0002)
	break;
    }
  disr = disr & ~0x0002;
  WRITE_UINT8 (DIAG_TFIFO, c);
  WRITE_UINT16 (DIAG_SLDISR, disr);
}

/* Stuff required to setup IO on this board */
void board_serial_init (void)
{
  WRITE_UINT16 (DIAG_SLCR, 0x0020);
  WRITE_UINT16 (DIAG_SLDICR, 0x0000);
  WRITE_UINT16 (DIAG_SFCR, 0x0000);
  WRITE_UINT16 (DIAG_SBRG, BRG_T2 | 5);
}

/* If you want this to be initialized as part of the stuff which gets called
   by crt0, it should be named 'hardware_init_hook'.
   Local implementations may want to move or add to this function OR
   do the initializations after main() is entered.
*/
void hardware_init_hook(void)
{
  board_serial_init() ;
}
     
/* Structure filled in by get_mem_info.  Only the size field is
   actually used (by sbrk), so the others aren't even filled in.  */

struct s_mem
{
  unsigned int size;
  unsigned int icsize;
  unsigned int dcsize;
};

/* mem_size is provided in the linker script so that we don't have to
   define it here. */
extern char _mem_size[];

void
get_mem_info (mem)
     struct s_mem *mem;
{
  mem->size = (unsigned int)_mem_size;
}
