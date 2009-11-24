
union u 
{
  struct 
    {
      short int msw;
      unsigned short lsw;
    } w;
  long l;
};

union us
{
  struct 
    {
      short int msw;
      unsigned short lsw;
    } w;
  long l;
};

int
__cmpsi2(long arga,
	 short int msw_b, unsigned short int lsw_b)
{
  union u u;
  u.l = arga;

  if (u.w.msw != msw_b)
    {
      if (u.w.msw < msw_b) return 0;
      return 2;
    }
  if (u.w.lsw != lsw_b) 
    {
      if (u.w.lsw < lsw_b) return 0;
      return 2;
    }
  return 1;
}


int
__ucmpsi2(unsigned long arga,
	 unsigned short int msw_b, unsigned short int lsw_b)
{
  union us u;
  u.l = arga;

  if (u.w.msw != msw_b)
    {
      if (u.w.msw < msw_b) return 0;
      return 2;
    }
  if (u.w.lsw != lsw_b) 
    {
      if (u.w.lsw < lsw_b) return 0;
      return 2;
    }
  return 1;
}


union pu 
{
  struct {
    char ignore;
    signed char msb;
    unsigned short lsw;
  } w;
  long l;
};

union pun
{
  struct {
    char ignore;
    unsigned char msb;
    unsigned short lsw;
  } w;
  long l;
};


int
__cmppsi2(long arga, long argb)
{
  union pu a;
  union pu b;
  a.l = arga;
  b.l = argb;

  if (a.w.msb != b.w.msb)
    {
      if (a.w.msb < b.w.msb) return 0;
      return 2;
    }
  if (a.w.lsw != b.w.lsw)
    {
      if (a.w.lsw < b.w.lsw) return 0;
      return 2;
    }
  return 1;
}


int
__ucmppsi2(long arga, long argb)
{
  union pun a;
  union pun b;
  a.l = arga;
  b.l = argb;

  if (a.w.msb != b.w.msb)
    {
      if (a.w.msb < b.w.msb) return 0;
      return 2;
    }
  if (a.w.lsw != b.w.lsw)
    {
      if (a.w.lsw < b.w.lsw) return 0;
      return 2;
    }
  return 1;
}
