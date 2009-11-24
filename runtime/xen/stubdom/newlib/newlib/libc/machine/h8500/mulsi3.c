
typedef union {
  struct {
  unsigned int msw;
  unsigned int lsw;
} s;
  long v;
} u;

long __mulsi3(u a, u b)
{
  int s;
  long pp1;
  long pp2;
  long r;

  if (a.s.msw == 0 &&
      b.s.msw == 0)
    {
      return (long)a.s.lsw * b.s.lsw;
    }

  s = 0;
  if (a.v < 0)
    {
      s = 1;
      a.v = - a.v;
    }
  if (b.v < 0)
    { 
      s = 1-s;
      b.v = - b.v;
    }

  pp1 = (long)a.s.lsw * b.s.lsw ;
  pp2 = (long)a.s.lsw * b.s.msw + (long)a.s.msw * b.s.lsw;

  pp1 += pp2 << 16;

  if (s)
    {
      pp1 = -pp1;
    }
  return pp1;
}
long __mulpsi3(long a, long b)
{
 return a*b;
}


short 
__mulhi3(short a, short b)
{
  int r;

  r = 0;
  while (a) 
    {
      if (a & 1) 
	{
	  r += b;

	}
      b<<=1;
      a>>=1;

    }
  return r;
}


