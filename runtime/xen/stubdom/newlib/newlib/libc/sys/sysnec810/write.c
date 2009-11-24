static volatile char *data = (char *)(0x20);
static volatile char *control = (char *)(0x24);

extern void _outb (volatile char*, unsigned char);
extern unsigned char _inb (volatile char*);

static unsigned char
 read_scc_reg (unsigned char n)
{
  _outb (control, n);
  return _inb(control);
}

static void write_scc_data (unsigned char n)
{
  _outb (data, n);
}

int
_write (int dev, void *buf, unsigned int len)
{
  int i;
  char *string = (char*)buf;

  for (i = 0; i < len; i++) 
    {
      int j;

      for (j = 0 ; j < 5000; j++)
	;
      write_scc_data (string[i]);

    }
  return len;
}

