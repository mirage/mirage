#define USE_PORT_A

#define RXADATA (int *) 0x01F800E0
#define RXBDATA (int *) 0x01F800E4
#define RXSTAT (int *) 0x01F800E8

void
outbyte (int c)
{
  volatile int *rxstat;
  volatile int *rxadata;
  int rxmask;

  rxstat = RXSTAT;
#ifdef USE_PORT_A
  rxadata = RXADATA;
  rxmask = 6;
#else
  rxadata = RXBDATA;
  rxmask = 0x60000;
#endif

  while ((*rxstat & rxmask) == 0);

  *rxadata = c;
}

int
inbyte (void)
{
  volatile int *rxstat;
  volatile int *rxadata;
  int rxmask;

  rxstat = RXSTAT;
#ifdef USE_PORT_A
  rxadata = RXADATA;
  rxmask = 1;
#else
  rxadata = RXBDATA;
  rxmask = 0x10000;
#endif

  while ((*rxstat & rxmask) == 0);

  return *rxadata;
}
